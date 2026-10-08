import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/contracts/trip_status.dart';
import 'package:movera/core/ride/active_ride_controller.dart';
import 'package:movera/core/ride/active_ride_repository.dart';

class _DelayedRead extends MemoryActiveRideRepository {
  final response = Completer<PersistedActiveRide?>();
  int writes = 0;
  @override
  Future<PersistedActiveRide?> read() => response.future;
  @override
  Future<void> save(PersistedActiveRide ride) async {
    writes++;
    await super.save(ride);
  }

  @override
  Future<void> clear() async {
    writes++;
    await super.clear();
  }
}

PersistedActiveRide _snapshot(ActiveRideStage stage) => PersistedActiveRide(
  tripId: 'owned-trip',
  stage: stage,
  savedAt: DateTime.now(),
);

void main() {
  test('late restore cannot regress a newly persisted stage', () async {
    final store = _DelayedRead();
    final ride = ActiveRideController(tripId: 'owned-trip', repository: store);
    final restore = ride.restore();
    expect(await ride.transitionTo(ActiveRideStage.waitingForRider), isTrue);
    store.response.complete(_snapshot(ActiveRideStage.headingToPickup));
    await restore;
    expect(ride.stage, ActiveRideStage.waitingForRider);
    ride.dispose();
  });

  test('late restore cannot change the stage after completion', () async {
    final store = _DelayedRead();
    final ride = ActiveRideController(
      tripId: 'owned-trip',
      repository: store,
      initialStage: ActiveRideStage.onTrip,
    );
    final restore = ride.restore();
    expect(await ride.complete(), isTrue);
    store.response.complete(_snapshot(ActiveRideStage.headingToPickup));
    await restore;
    expect(ride.stage, ActiveRideStage.onTrip);
    expect(ride.terminalStatus, TripStatus.completed);
    ride.dispose();
  });

  test(
    'late restore failure does not overwrite a newer successful operation',
    () async {
      final store = _DelayedRead();
      final ride = ActiveRideController(
        tripId: 'owned-trip',
        repository: store,
      );
      final restore = ride.restore();
      await ride.transitionTo(ActiveRideStage.waitingForRider);
      store.response.completeError(StateError('Old read failed'));
      await restore;
      expect(ride.persistenceError, isNull);
      expect(ride.stage, ActiveRideStage.waitingForRider);
      ride.dispose();
    },
  );

  test('a current restore failure is observable and does not escape', () async {
    final store = _DelayedRead();
    final ride = ActiveRideController(tripId: 'owned-trip', repository: store);
    final restore = ride.restore();
    store.response.completeError(StateError('Read failed'));
    await restore;
    expect(ride.persistenceError, isA<StateError>());
    expect(ride.stage, ActiveRideStage.headingToPickup);
    ride.dispose();
  });

  test(
    'disposed ride rejects commands without writing or becoming terminal',
    () async {
      final store = _DelayedRead();
      final ride = ActiveRideController(
        tripId: 'owned-trip',
        repository: store,
        initialStage: ActiveRideStage.onTrip,
      );
      ride.dispose();
      expect(await ride.complete(), isFalse);
      expect(await ride.cancel(), isFalse);
      expect(await ride.persistNow(), isFalse);
      expect(store.writes, 0);
      expect(ride.terminal, isFalse);
    },
  );
}
