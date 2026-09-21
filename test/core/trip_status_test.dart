import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/contracts/trip_status.dart';
import 'package:movera/core/ride/active_ride_controller.dart';
import 'package:movera/core/ride/active_ride_repository.dart';

void main() {
  test('Driver live stages map onto canonical TripStatus', () {
    expect(
      ActiveRideStage.headingToPickup.tripStatus,
      TripStatus.driverToPickup,
    );
    expect(ActiveRideStage.waitingForRider.tripStatus, TripStatus.arrived);
    expect(ActiveRideStage.onTrip.tripStatus, TripStatus.inTrip);
  });

  test('wire names are snake_case and tripId is the identifier name', () {
    expect(TripStatus.driverToPickup.wireName, 'driver_to_pickup');
    expect(TripStatus.cancelledByRider.wireName, 'cancelled_by_rider');
    expect(TripStatus.inTrip.wireName, 'in_trip');
  });

  test('ActiveRideController exposes canonical status without changing stages',
      () {
    final ride = ActiveRideController(tripId: 'trip-1');
    expect(ride.tripStatus, TripStatus.driverToPickup);

    expect(ride.transitionTo(ActiveRideStage.waitingForRider), isTrue);
    expect(ride.tripStatus, TripStatus.arrived);

    expect(ride.transitionTo(ActiveRideStage.onTrip), isTrue);
    expect(ride.tripStatus, TripStatus.inTrip);

    expect(ride.complete(), isTrue);
    expect(ride.tripStatus, TripStatus.completed);
  });
}
