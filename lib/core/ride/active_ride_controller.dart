import 'package:flutter/foundation.dart';

enum ActiveRideStage {
  headingToPickup,
  waitingForRider,
  onTrip,
  completed,
  cancelled,
}

/// Owns the authoritative lifecycle state for one active ride.
///
/// UI widgets can render this state, but they should not invent independent
/// ride stages. Backend persistence/recovery can later be attached here.
class ActiveRideController extends ChangeNotifier {
  ActiveRideStage _stage = ActiveRideStage.headingToPickup;

  ActiveRideStage get stage => _stage;

  bool transitionTo(ActiveRideStage next) {
    if (next == _stage) return true;

    final allowed = switch (_stage) {
      ActiveRideStage.headingToPickup =>
        next == ActiveRideStage.waitingForRider ||
            next == ActiveRideStage.cancelled,
      ActiveRideStage.waitingForRider =>
        next == ActiveRideStage.onTrip ||
            next == ActiveRideStage.cancelled,
      ActiveRideStage.onTrip =>
        next == ActiveRideStage.completed ||
            next == ActiveRideStage.cancelled,
      ActiveRideStage.completed => false,
      ActiveRideStage.cancelled => false,
    };

    if (!allowed) return false;

    _stage = next;
    notifyListeners();
    return true;
  }

  bool complete() => transitionTo(ActiveRideStage.completed);

  bool cancel() => transitionTo(ActiveRideStage.cancelled);
}
