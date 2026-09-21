import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/ride/active_ride_controller.dart';
import 'package:movera/core/ride/active_ride_repository.dart';

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

  test('complete is idempotent and rejects double completion', () {
    final ride = ActiveRideController();
    expect(ride.complete(), isFalse);

    expect(ride.transitionTo(ActiveRideStage.waitingForRider), isTrue);
    expect(ride.transitionTo(ActiveRideStage.onTrip), isTrue);
    expect(ride.complete(), isTrue);
    expect(ride.complete(), isFalse);
    expect(ride.cancelled, isFalse);
  });

  test('active ride persists stage through the repository', () async {
    final store = MemoryActiveRideRepository();
    final ride = ActiveRideController(
      tripId: 'nearby-1',
      repository: store,
    );

    expect(ride.transitionTo(ActiveRideStage.waitingForRider), isTrue);
    await Future<void>.delayed(Duration.zero);

    final restored = ActiveRideController(
      tripId: 'nearby-1',
      repository: store,
    );
    await restored.restore();
    expect(restored.stage, ActiveRideStage.waitingForRider);

    expect(restored.cancel(), isTrue);
    await Future<void>.delayed(Duration.zero);
    final afterCancel = ActiveRideController(
      tripId: 'nearby-1',
      repository: store,
    );
    await afterCancel.restore();
    expect(afterCancel.stage, ActiveRideStage.headingToPickup);
  });

  test('persistNow writes a snapshot builder payload', () async {
    final store = MemoryActiveRideRepository();
    final ride = ActiveRideController(
      tripId: 'nearby-1',
      repository: store,
      snapshotBuilder: (stage) => PersistedActiveRide(
        tripId: 'nearby-1',
        stage: stage,
        riderName: 'Angelica',
        pickupAddress: 'Kungsgatan 42, Stockholm',
      ),
    );

    ride.persistNow();
    await Future<void>.delayed(Duration.zero);
    final stored = await store.read();
    expect(stored, isNotNull);
    expect(stored!.riderName, 'Angelica');
    expect(stored.pickupAddress, 'Kungsgatan 42, Stockholm');
  });
}
