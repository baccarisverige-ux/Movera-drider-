import 'dart:async';

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
      _terminalStatus == TripStatus.cancelledByAdmin ||
      _terminalStatus == TripStatus.noShow ||
      _terminalStatus == TripStatus.expired ||
      _terminalStatus == TripStatus.failed;
  bool get terminal => _terminalStatus != null;

  /// Canonical P1 status derived from the live stage and terminal outcome.
  /// Does not replace [ActiveRideStage] in UI.
  TripStatus get tripStatus => _terminalStatus ?? _stage.tripStatus;

  bool transitionTo(ActiveRideStage next) {
    if (terminal) return false;
    if (next == _stage) return true;

    final allowed = switch (_stage) {
      ActiveRideStage.headingToPickup =>
        next == ActiveRideStage.waitingForRider,
      ActiveRideStage.waitingForRider => next == ActiveRideStage.onTrip,
      ActiveRideStage.onTrip => false,
    };

    if (!allowed) return false;

    _stage = next;
    notifyListeners();
    persistNow();
    return true;
  }

  bool complete() {
    if (terminal || _stage != ActiveRideStage.onTrip) return false;
    _terminalStatus = TripStatus.completed;
    notifyListeners();
    unawaited(_repository.clear());
    return true;
  }

  bool cancel({
    TripStatus status = TripStatus.cancelledByDriver,
  }) {
    if (terminal || !_isCancellationTerminal(status)) return false;
    _terminalStatus = status;
    notifyListeners();
    unawaited(_repository.clear());
    return true;
  }

  bool _isCancellationTerminal(TripStatus status) {
    return status == TripStatus.cancelledByRider ||
        status == TripStatus.cancelledByDriver ||
        status == TripStatus.cancelledByAdmin ||
        status == TripStatus.noShow ||
        status == TripStatus.expired ||
        status == TripStatus.failed;
  }

  /// Write the current live snapshot. Safe to call from lifecycle pauses.
  void persistNow() {
    if (terminal) return;
    final id = tripId;
    if (id == null) return;
    final ride = snapshotBuilder?.call(_stage) ??
        PersistedActiveRide(tripId: id, stage: _stage);
    unawaited(_repository.save(ride));
  }

  Future<void> restore() async {
    final stored = await _repository.read();
    if (stored == null) return;
    if (tripId != null && stored.tripId != tripId) return;
    if (!stored.isFresh) return;
    _stage = stored.stage;
    notifyListeners();
  }
}
