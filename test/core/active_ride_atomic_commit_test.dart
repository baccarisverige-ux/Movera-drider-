import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/contracts/trip_status.dart';
import 'package:movera/core/ride/active_ride_controller.dart';
import 'package:movera/core/ride/active_ride_repository.dart';

class _Store extends MemoryActiveRideRepository {
  final savedStages = <ActiveRideStage>[];
  int clears = 0;

  @override
  Future<void> save(PersistedActiveRide ride) async {
    savedStages.add(ride.stage);
    await super.save(ride);
  }

  @override
  Future<void> clear() async {
    clears++;
    await super.clear();
  }
}

void main() {
  for (final projection in [false, true]) {
    test(
      '${projection ? 'projection' : 'transition'} commits stage before an idle listener can persist again',
      () async {
        final store = _Store();
        final ride = ActiveRideController(
          tripId: 'owned-trip',
          repository: store,
        );
        addTearDown(ride.dispose);
        Future<bool>? flush;
        final idleStages = <ActiveRideStage>[];
        var requested = false;
        ride.addListener(() {
          if (ride.saving) return;
          idleStages.add(ride.stage);
          if (!requested) {
            requested = true;
            flush = ride.persistNow();
          }
        });

        expect(
          await (projection
              ? ride.applyProjection(TripStatus.arrived)
              : ride.transitionTo(ActiveRideStage.waitingForRider)),
          isTrue,
        );
        expect(await flush!, isTrue);
        expect(idleStages, isNotEmpty);
        expect(idleStages, everyElement(ActiveRideStage.waitingForRider));
        expect(store.savedStages, [
          ActiveRideStage.waitingForRider,
          ActiveRideStage.waitingForRider,
        ]);
        expect((await store.read())?.stage, ActiveRideStage.waitingForRider);
        expect(ride.stage, ActiveRideStage.waitingForRider);
        expect(ride.saving, isFalse);
      },
    );
  }

  final terminalCommands =
      <String, Future<bool> Function(ActiveRideController)>{
        'completion': (ride) => ride.complete(),
        'cancellation': (ride) => ride.cancel(),
        'terminal projection': (ride) =>
            ride.applyProjection(TripStatus.noShow),
      };
  for (final entry in terminalCommands.entries) {
    test(
      '${entry.key} cannot be resurrected by an idle persistence listener',
      () async {
        final store = _Store();
        await store.save(
          const PersistedActiveRide(
            tripId: 'owned-trip',
            stage: ActiveRideStage.onTrip,
          ),
        );
        final ride = ActiveRideController(
          tripId: 'owned-trip',
          repository: store,
          initialStage: ActiveRideStage.onTrip,
        );
        addTearDown(ride.dispose);
        Future<bool>? flush;
        final idleTerminalStates = <bool>[];
        var requested = false;
        ride.addListener(() {
          if (ride.saving) return;
          idleTerminalStates.add(ride.terminal);
          if (!requested) {
            requested = true;
            flush = ride.persistNow();
          }
        });

        expect(await entry.value(ride), isTrue);
        expect(await flush!, isTrue);
        expect(idleTerminalStates, isNotEmpty);
        expect(idleTerminalStates, everyElement(isTrue));
        expect(store.clears, 1);
        expect(store.savedStages, [ActiveRideStage.onTrip]);
        expect(await store.read(), isNull);
        expect(ride.terminal, isTrue);
        expect(ride.saving, isFalse);
      },
    );
  }
}
