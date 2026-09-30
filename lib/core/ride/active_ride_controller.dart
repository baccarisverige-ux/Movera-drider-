import 'package:flutter/foundation.dart';
import 'package:movera/core/contracts/trip_status.dart';
import 'package:movera/core/ride/active_ride_repository.dart';

export 'package:movera/core/ride/active_ride_repository.dart' show ActiveRideStage;

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
  })  : _repository = repository ?? MemoryActiveRideRepository(),
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
    if (terminal || saving) return false;
    if (next == _stage) return true;

    final allowed = switch (_stage) {
      ActiveRideStage.headingToPickup =>
        next == ActiveRideStage.waitingForRider,
      ActiveRideStage.waitingForRider => next == ActiveRideStage.onTrip,
      ActiveRideStage.onTrip => false,
    };

    if (!allowed) return false;

    if (!await _write(() => _repository.save(_snapshot(next)))) return false;
    _stage = next;
    notifyListeners();
    return true;
  }

  Future<bool> complete({bool clearSnapshot = true}) async {
    if (terminal || saving || _stage != ActiveRideStage.onTrip) return false;
    if (clearSnapshot && !await _write(() => _finish(TripStatus.completed))) return false;
    _terminalStatus = TripStatus.completed;
    notifyListeners();
    return true;
  }

  Future<bool> cancel({
    TripStatus status = TripStatus.cancelledByDriver,
  }) async {
    if (terminal || saving || !_isCancellationTerminal(status)) return false;
    if (!await _write(() => _finish(status))) return false;
    _terminalStatus = status;
    notifyListeners();
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
      await repository.markTerminal(tripId!, status);
    }
    await repository.clear();
  }

  bool _disposed = false;
  bool _writing = false;
  Object? persistenceError;
  bool get saving => _writing;
  PersistedActiveRide _snapshot(ActiveRideStage stage) =>
      snapshotBuilder?.call(stage) ?? PersistedActiveRide(tripId: tripId ?? 'demo', stage: stage);
  Future<bool> _write(Future<void> Function() operation) async {
    if (_writing) return false;
    _writing = true;
    persistenceError = null;
    if (!_disposed) notifyListeners();
    try { await operation(); return true; }
    catch (error) { persistenceError = error; return false; }
    finally { _writing = false; if (!_disposed) notifyListeners(); }
  }
  /// Errors are observable; fire-and-forget lifecycle saves never throw.
  Future<bool> persistNow() async {
    if (terminal || tripId == null) return true;
    return _write(() => _repository.save(_snapshot(_stage)));
  }
  @override
  void dispose() { _disposed = true; super.dispose(); }

  Future<void> restore() async {
    final stored = await _repository.read();
    if (stored == null) return;
    if (tripId != null && stored.tripId != tripId) return;
    // Stale rides remain available for explicit recovery in Home.
    _stage = stored.stage;
    notifyListeners();
  }
}
