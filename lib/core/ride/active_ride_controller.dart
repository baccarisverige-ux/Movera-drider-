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
  }) : _repository = repository ?? MemoryActiveRideRepository();

  final String? tripId;
  final ActiveRideRepository _repository;
  ActiveRideStage _stage = ActiveRideStage.headingToPickup;
  bool _completed = false;
  bool _cancelled = false;

  ActiveRideStage get stage => _stage;
  bool get completed => _completed;
  bool get cancelled => _cancelled;
  bool get terminal => _completed || _cancelled;

  /// Canonical P1 status derived from the live stage and terminal flags.
  /// Does not replace [ActiveRideStage] in UI.
  TripStatus get tripStatus {
    if (_cancelled) return TripStatus.cancelledByDriver;
    if (_completed) return TripStatus.completed;
    return _stage.tripStatus;
  }

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
    _persist();
    return true;
  }

  bool complete() {
    if (terminal || _stage != ActiveRideStage.onTrip) return false;
    _completed = true;
    notifyListeners();
    unawaited(_repository.clear());
    return true;
  }

  bool cancel() {
    if (terminal) return false;
    _cancelled = true;
    notifyListeners();
    unawaited(_repository.clear());
    return true;
  }

  Future<void> restore() async {
    final stored = await _repository.read();
    if (stored == null) return;
    if (tripId != null && stored.tripId != tripId) return;
    _stage = stored.stage;
    notifyListeners();
  }

  void _persist() {
    final id = tripId;
    if (id == null) return;
    unawaited(
      _repository.save(
        PersistedActiveRide(tripId: id, stage: _stage),
      ),
    );
  }
}
