import 'package:flutter/foundation.dart';
import 'package:movera/core/contracts/trip_status.dart';
import 'package:movera/core/ride/active_ride_repository.dart';

export 'package:movera/core/ride/active_ride_repository.dart'
    show ActiveRideStage;

/// Single source of truth for the lifecycle stage of one active ride.
///
/// Terminal outcomes are tracked separately so presentation switches only need
/// to render the three live stages. Persistence attaches here so screens do
/// not own ride recovery.
class ActiveRideController extends ChangeNotifier {
  ActiveRideController({
    this.tripId,
    ActiveRideRepository? repository,
    ActiveRideStage initialStage = ActiveRideStage.headingToPickup,
    this.snapshotBuilder,
  }) : _repository = repository ?? MemoryActiveRideRepository(),
       _stage = initialStage;

  final String? tripId;
  final ActiveRideRepository _repository;
  PersistedActiveRide Function(ActiveRideStage stage)? snapshotBuilder;
  ActiveRideStage _stage;
  TripStatus? _terminalStatus;

  ActiveRideStage get stage => _stage;
  TripStatus? get terminalStatus => _terminalStatus;
  bool get completed => _terminalStatus == TripStatus.completed;
  bool get cancelled =>
      _terminalStatus == TripStatus.cancelledByRider ||
      _terminalStatus == TripStatus.cancelledByDriver ||
      _terminalStatus == TripStatus.cancelledByAdmin;
  bool get terminal => _terminalStatus != null;

  /// Canonical P1 status derived from the live stage and terminal outcome.
  /// Does not replace [ActiveRideStage] in UI.
  TripStatus get tripStatus => _terminalStatus ?? _stage.tripStatus;

  Future<bool> transitionTo(ActiveRideStage next) async {
    if (_disposed || terminal || saving) {
      return false;
    }
    if (next == _stage) {
      return true;
    }

    final allowed = switch (_stage) {
      ActiveRideStage.headingToPickup =>
        next == ActiveRideStage.waitingForRider,
      ActiveRideStage.waitingForRider => next == ActiveRideStage.onTrip,
      ActiveRideStage.onTrip => false,
    };

    if (!allowed) {
      return false;
    }

    if (!await _write(() => _repository.save(_snapshot(next)))) {
      return false;
    }
    _stage = next;
    if (!_disposed) {
      notifyListeners();
    }
    return true;
  }

  /// Apply an authoritative projection, including skipped live stages.
  Future<bool> applyProjection(TripStatus status) async {
    // Duplicate terminal deliveries must not rerun persistence. A different
    // authoritative terminal status may correct an earlier tentative outcome;
    // the completion journal supports such authoritative corrections.
    if (saving || _disposed ||
        (terminal && (!status.isTerminal || _terminalStatus == status))) {
      return false;
    }
    if (status.isTerminal) {
      if (!await _write(() => _finish(status))) {
        return false;
      }
      _terminalStatus = status;
    } else {
      if (terminal) {
        return false;
      }
      final next = switch (status) {
        TripStatus.accepted ||
        TripStatus.driverToPickup => ActiveRideStage.headingToPickup,
        TripStatus.arrived => ActiveRideStage.waitingForRider,
        TripStatus.riderOnboard ||
        TripStatus.inTrip ||
        TripStatus.approachingDropoff => ActiveRideStage.onTrip,
        _ => null,
      };
      if (next == null || next.index < _stage.index) {
        return false;
      }
      if (!await _write(() => _repository.save(_snapshot(next)))) {
        return false;
      }
      _stage = next;
    }
    if (!_disposed) {
      notifyListeners();
    }
    return true;
  }

  Future<bool> complete({bool clearSnapshot = true}) async {
    if (_disposed || terminal || saving || _stage != ActiveRideStage.onTrip) {
      return false;
    }
    if (clearSnapshot && !await _write(() => _finish(TripStatus.completed))) {
      return false;
    }
    _terminalStatus = TripStatus.completed;
    if (!_disposed) {
      notifyListeners();
    }
    return true;
  }

  Future<bool> cancel({
    TripStatus status = TripStatus.cancelledByDriver,
    bool clearSnapshot = true,
  }) async {
    if (_disposed || terminal || saving || !_isCancellationTerminal(status)) {
      return false;
    }
    if (clearSnapshot && !await _write(() => _finish(status))) {
      return false;
    }
    _terminalStatus = status;
    if (!_disposed) {
      notifyListeners();
    }
    return true;
  }

  bool _isCancellationTerminal(TripStatus status) {
    return status == TripStatus.cancelledByRider ||
        status == TripStatus.cancelledByDriver ||
        status == TripStatus.cancelledByAdmin;
  }

  Future<void> _finish(TripStatus status) async {
    final repository = _repository;
    if (repository is TerminalRideRepository && tripId != null) {
      await (repository as TerminalRideRepository).markTerminal(
        tripId!,
        status,
      );
      await (repository as TerminalRideRepository).clearForTrip(tripId!);
    } else {
      await repository.clear();
    }
  }

  bool recoveryRequired = false;
  bool _disposed = false;
  bool _writing = false;
  int _revision = 0;
  Object? persistenceError;
  bool get saving => _writing;
  PersistedActiveRide _snapshot(ActiveRideStage stage) =>
      snapshotBuilder?.call(stage) ??
      PersistedActiveRide(tripId: tripId ?? 'demo', stage: stage);
  Future<bool> _write(Future<void> Function() operation) async {
    if (_disposed || _writing) {
      return false;
    }
    _writing = true;
    _revision++;
    persistenceError = null;
    if (!_disposed) {
      notifyListeners();
    }
    try {
      await operation();
      return !_disposed;
    } catch (error) {
      persistenceError = error;
      return false;
    } finally {
      _writing = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  /// Errors are observable; fire-and-forget lifecycle saves never throw.
  Future<bool> persistNow() async {
    if (_disposed) { return false; }
    if (terminal || tripId == null) {
      return true;
    }
    return _write(() => _repository.save(_snapshot(_stage)));
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    super.dispose();
  }

  Future<void> restore() async {
    if (_disposed || terminal || saving) { return; }
    final revision = ++_revision;
    PersistedActiveRide? stored;
    try {
      stored = await _repository.read();
    } catch (error) {
      if (_disposed || terminal || saving || revision != _revision) { return; }
      persistenceError = error;
      notifyListeners();
      return;
    }
    if (_disposed || terminal || saving || revision != _revision) { return; }
    if (stored == null) {
      return;
    }
    if (tripId != null && stored.tripId != tripId) {
      return;
    }
    recoveryRequired = !stored.isFresh;
    persistenceError = null;
    if (recoveryRequired) {
      if (!_disposed) {
        notifyListeners();
      }
      return;
    }
    _stage = stored.stage;
    if (!_disposed) {
      notifyListeners();
    }
  }
}
