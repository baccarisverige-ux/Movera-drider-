import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/dispatch/dispatch_repository.dart';
import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/location/driver_location_repository.dart';
import 'package:movera/core/session/driver_runtime_config.dart';
import 'package:movera/presentation/driver/accept%20ride/accept_ride.dart';
import 'package:movera/presentation/driver/home/home.dart';
import 'package:movera/presentation/driver/home/components/island_messages.dart';
import 'package:shared_preferences/shared_preferences.dart';

RideOffer _offer(String id) => RideOffer(
  id: id,
  category: 'Comfort',
  fare: '100 kr',
  rating: '4.9',
  pickupMinutes: 2,
  pickupKm: 1,
  tripMinutes: 10,
  tripKm: 5,
  pickup: 'Pickup, Stockholm',
  dropoff: 'Dropoff, Stockholm',
  pickupPosition: const GeoPoint(59.3279, 18.0615),
  dropoffPosition: const GeoPoint(59.3326, 18.0649),
  isNearby: true,
  followsDestination: true,
);

class _Dispatch implements DispatchRepository {
  final updates = StreamController<List<RideOffer>>.broadcast();
  final claims = <Completer<ClaimResult>>[];
  @override
  Stream<List<RideOffer>> watchNearbyOffers({
    bool destinationModeActive = false,
  }) async* {
    yield [_offer('first'), _offer('second')];
    yield* updates.stream;
  }

  @override
  Stream<List<RideOffer>> watchNextTripOffers() => const Stream.empty();
  @override
  void refreshOffers() {}
  @override
  Future<ClaimResult> claimOffer(String offerId) {
    final claim = Completer<ClaimResult>();
    claims.add(claim);
    return claim.future;
  }
}

class _Location implements DriverLocationRepository {
  @override
  Future<DriverLocation> getCurrentPosition() =>
      Completer<DriverLocation>().future;
  @override
  Stream<DriverLocation> watchPosition({int distanceFilterMeters = 8}) =>
      const Stream.empty();
}

Future<void> _frames(WidgetTester tester, [int count = 8]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _mount(WidgetTester tester, _Dispatch dispatch) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(
        home: DriverHome(
          dispatchRepository: dispatch,
          locationRepository: _Location(),
        ),
      ),
    ),
  );
  await _frames(tester);
  await tester.tap(find.text('OFF'));
  await tester.pump(const Duration(milliseconds: 1550));
  await tester.pump(const Duration(milliseconds: 2300));
  await tester.pump(const Duration(milliseconds: 8500));
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pump(const Duration(milliseconds: 3100));
  await tester.tap(find.byKey(const ValueKey<String>('radar-home-refresh')));
  await _frames(tester);
  expect(
    find.byKey(const ValueKey<String>('radar-offer-first')),
    findsOneWidget,
  );
  expect(
    find.byKey(const ValueKey<String>('radar-offer-second')),
    findsOneWidget,
  );
}

Future<void> _match(WidgetTester tester, String id) async {
  final match = find.descendant(
    of: find.byKey(ValueKey<String>('radar-offer-$id')),
    matching: find.text('Match'),
  );
  await tester.ensureVisible(match);
  await tester.tap(match);
  await tester.pump();
}

void main() {
  final previous = DriverRuntimeConfig.current;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    IslandMessages.reset();
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

  testWidgets('Home recovers a thrown claim error and allows retry', (
    tester,
  ) async {
    final dispatch = _Dispatch();
    await _mount(tester, dispatch);
    await _match(tester, 'first');
    dispatch.claims.single.completeError(StateError('Transport disconnected'));
    await _frames(tester);
    expect(tester.takeException(), isNull);
    await _match(tester, 'first');
    expect(dispatch.claims, hasLength(2));
    dispatch.claims.last.complete(const ClaimResult.unavailable());
    await _frames(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await dispatch.updates.close();
  });

  testWidgets(
    'another offer disappearing cannot cancel the pending Home claim',
    (tester) async {
      final dispatch = _Dispatch();
      await _mount(tester, dispatch);
      await _match(tester, 'first');
      dispatch.updates.add([_offer('first')]);
      await _frames(tester);
      dispatch.claims.single.complete(ClaimResult.success(_offer('first')));
      await _frames(tester, 30);
      expect(find.byType(AcceptRide), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await dispatch.updates.close();
    },
  );

  testWidgets('a won Home claim stays locked until the active ride opens', (
    tester,
  ) async {
    final dispatch = _Dispatch();
    await _mount(tester, dispatch);
    await _match(tester, 'first');
    dispatch.claims.single.complete(ClaimResult.success(_offer('first')));
    await tester.pump();
    final secondButton = find.descendant(
      of: find.byKey(const ValueKey<String>('radar-offer-second')),
      matching: find.byType(FilledButton),
    );
    expect(tester.widget<FilledButton>(secondButton).onPressed, isNull);
    // The dispatch removal of our own claimed offer must not cancel opening.
    dispatch.updates.add([_offer('second')]);
    await _frames(tester, 30);
    expect(dispatch.claims, hasLength(1));
    expect(find.byType(AcceptRide), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await dispatch.updates.close();
  });
}
