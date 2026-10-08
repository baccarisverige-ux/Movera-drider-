import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/location/driver_location_repository.dart';
import 'package:movera/core/ride/active_ride_repository.dart';
import 'package:movera/core/session/driver_runtime_config.dart';
import 'package:movera/presentation/driver/accept%20ride/accept_ride.dart';
import 'package:movera/presentation/driver/accept%20ride/adaptive_trip_island.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _PendingLocation implements DriverLocationRepository {
  @override
  Future<DriverLocation> getCurrentPosition() =>
      Completer<DriverLocation>().future;
  @override
  Stream<DriverLocation> watchPosition({int distanceFilterMeters = 8}) =>
      const Stream.empty();
}

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  final previous = DriverRuntimeConfig.current;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DriverRuntimeConfig.current = const DriverRuntimeConfig(
      externalRouting: false,
      liveMapTicker: false,
      reservationPopup: false,
      islandHint: false,
      simulatedArrival: false,
      skipAccountActivation: false,
    );
  });
  tearDown(() => DriverRuntimeConfig.current = previous);

  for (final atStop in [false, true]) {
    testWidgets(
      '${atStop ? 'stop' : 'pickup'} wait catches up immediately after lock and resume',
      (tester) async {
        var now = DateTime(2026, 10, 8, 12);
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final stage = atStop
            ? ActiveRideStage.onTrip
            : ActiveRideStage.waitingForRider;
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, __) => MaterialApp(
              home: AcceptRide(
                initialStage: stage,
                initialWaitSeconds: 30,
                waitNow: () => now,
                locationRepository: _PendingLocation(),
                restoredSnapshot: atStop
                    ? PersistedActiveRide(
                        tripId: 'demo-radar-offer',
                        stage: stage,
                        paidStopWait: true,
                      )
                    : null,
              ),
            ),
          ),
        );
        await _frames(tester);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        // The platform clock advances while no periodic timer callbacks run.
        now = now.add(const Duration(minutes: 4));
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await _frames(tester);
        expect(
          tester
              .widget<AdaptiveTripIsland>(find.byType(AdaptiveTripIsland))
              .waitingSeconds,
          270,
        );
        // Repeated lifecycle notifications must not add the same interval twice.
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await _frames(tester);
        expect(
          tester
              .widget<AdaptiveTripIsland>(find.byType(AdaptiveTripIsland))
              .waitingSeconds,
          270,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await _frames(tester);
      },
    );
  }
}
