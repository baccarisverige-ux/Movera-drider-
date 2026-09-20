import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/ride/active_ride_controller.dart';

void main() {
  test('active ride only allows valid forward lifecycle transitions', () {
    final ride = ActiveRideController();

    expect(ride.stage, ActiveRideStage.headingToPickup);
    expect(ride.transitionTo(ActiveRideStage.onTrip), isFalse);
    expect(ride.stage, ActiveRideStage.headingToPickup);

    expect(ride.transitionTo(ActiveRideStage.waitingForRider), isTrue);
    expect(ride.stage, ActiveRideStage.waitingForRider);

    expect(ride.transitionTo(ActiveRideStage.onTrip), isTrue);
    expect(ride.stage, ActiveRideStage.onTrip);

    expect(ride.complete(), isTrue);
    expect(ride.completed, isTrue);
    expect(ride.transitionTo(ActiveRideStage.waitingForRider), isFalse);
  });

  test('cancelled ride becomes terminal', () {
    final ride = ActiveRideController();

    expect(ride.cancel(), isTrue);
    expect(ride.cancelled, isTrue);
    expect(
      ride.transitionTo(ActiveRideStage.waitingForRider),
      isFalse,
    );
  });
}
