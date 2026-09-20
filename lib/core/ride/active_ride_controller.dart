import 'package:flutter/foundation.dart';

enum ActiveRideStage {
  headingToPickup,
  waitingForRider,
  onTrip,
}

/// Single source of truth for the lifecycle stage of one active ride.
///
/// Terminal outcomes are tracked separately so presentation switches only need
/// to render the three live stages. Backend persistence/recovery can attach to
/// this controller without moving lifecycle rules back into widgets.
class ActiveRideController extends ChangeNotifier {
  ActiveRideStage _stage = ActiveRideStage.headingToPickup;
  bool _completed = false;
  bool _cancelled = false;

  ActiveRideStage get stage => _stage;
  bool get completed => _completed;
  bool get cancelled => _cancelled;
  bool get terminal => _completed || _cancelled;

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
    return true;
  }

  bool complete() {
    if (terminal || _stage != ActiveRideStage.onTrip) return false;
    _completed = true;
    notifyListeners();
    return true;
  }

  bool cancel() {
    if (terminal) return false;
    _cancelled = true;
    notifyListeners();
    return true;
  }
}
