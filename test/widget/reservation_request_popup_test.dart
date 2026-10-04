import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/admin/driver_home_admin_content.dart';
import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/session/driver_runtime_config.dart';
import 'package:movera/core/session/driver_session_controller.dart';
import 'package:movera/presentation/driver/home/components/reservation_request_sheet.dart';
import 'package:movera/presentation/driver/home/components/reservation_route_map.dart';
import 'package:movera/presentation/driver/home/home.dart';
import 'package:movera/widgets/layout_viewport.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _request = ReservationRequestPreview(
  category: 'Comfort',
  fare: '126.75 kr',
  pickupLabel: 'Pickup today at 07:40',
  pickupAddress: 'Gamla vägen, Stockholm',
  dropoffAddress: 'Solna centrum, Solna',
  pickupTime: '07:40',
  pickupDay: 'Today',
  tripMinutes: 19,
  tripKm: 9.4,
  pickup: GeoPoint(59.3362, 18.0714),
  dropoff: GeoPoint(59.3603, 18.0009),
);

Widget _fakeMap(BuildContext context) =>
    const ColoredBox(key: ValueKey<String>('fake-map'), color: Color(0xFFE6EAED));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('arrival time adds the ride to the pickup time', () {
    expect(_request.arrivalTime, '07:59');
    const late = ReservationRequestPreview(
      category: 'Comfort',
      fare: '1 kr',
      pickupLabel: '',
      pickupAddress: '',
      dropoffAddress: '',
      pickupTime: '23:50',
      pickupDay: 'Today',
      tripMinutes: 25,
      tripKm: 1,
      pickup: GeoPoint(0, 0),
      dropoff: GeoPoint(0, 0),
    );
    expect(late.arrivalTime, '00:15');
  });

  testWidgets('tapping the popup map opens the full route and Back returns', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const withStop = ReservationRequestPreview(
      category: 'Comfort',
      fare: '126.75 kr',
      pickupLabel: 'Pickup today at 07:40',
      pickupAddress: 'Gamla vägen, Stockholm',
      dropoffAddress: 'Solna centrum, Solna',
      pickupTime: '07:40',
      pickupDay: 'Today',
      tripMinutes: 19,
      tripKm: 9.4,
      pickup: GeoPoint(59.3362, 18.0714),
      dropoff: GeoPoint(59.3603, 18.0009),
      stops: [
        ReservationStop(
          address: 'Odenplan, Stockholm',
          point: GeoPoint(59.3430, 18.0496),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showReservationRequestSheet(
              context,
              withStop,
              mapBuilder: _fakeMap,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Stop 1'), findsOneWidget);
    expect(find.text('Odenplan, Stockholm'), findsOneWidget);
    expect(find.text('View route'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('reservation-map-open')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ReservationRouteMapPage), findsOneWidget);
    expect(find.text('07:59'), findsOneWidget);
    expect(find.text('Solna centrum, Solna'), findsWidgets);
    tester.takeException();

    await tester.tap(find.byKey(const ValueKey<String>('reservation-map-close')));
    await tester.pumpAndSettle();
    expect(find.byType(ReservationRouteMapPage), findsNothing);
    expect(find.text('You have a new reservation request'), findsOneWidget);
    tester.takeException();
  });

  for (final (label, expected) in [
    ('Accept', ReservationDecision.accepted),
    ('Deny', ReservationDecision.denied),
  ]) {
    testWidgets('reservation sheet $label resolves $expected', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      ReservationDecision? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await showReservationRequestSheet(
                context,
                _request,
                mapBuilder: _fakeMap,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('You have a new reservation request'), findsOneWidget);
      expect(find.text('Comfort'), findsOneWidget);
      expect(find.text('126.75 kr'), findsOneWidget);
      expect(find.text('Pickup today at 07:40'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('fake-map')), findsOneWidget);
      expect(find.text('Gamla vägen, Stockholm'), findsOneWidget);
      expect(find.text('Solna centrum, Solna'), findsOneWidget);
      expect(find.text('07:40'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.textContaining('away'), findsNothing);
      expect(find.text('19 min'), findsOneWidget);
      expect(find.text('9.4 km ride'), findsOneWidget);
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(result, expected);
      expect(find.text('You have a new reservation request'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Home announces a new reservation once and Accept confirms it', (
    tester,
  ) async {
    final previous = DriverRuntimeConfig.current;
    DriverRuntimeConfig.current = DriverRuntimeConfig(
      simulatedArrival: previous.simulatedArrival,
      externalRouting: previous.externalRouting,
      skipAccountActivation: previous.skipAccountActivation,
      liveMapTicker: previous.liveMapTicker,
      islandHint: previous.islandHint,
    );
    addTearDown(() => DriverRuntimeConfig.current = previous);
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      LayoutViewport(
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          useInheritedMediaQuery: true,
          builder: (_, __) => MaterialApp(
            home: DriverHome(sessionController: DriverSessionController()),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('You have a new reservation request'), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('You have a new reservation request'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('reservation-accept')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('You have a new reservation request'), findsNothing);
    // The island confirms it; tapping it opens the scheduled rides.
    expect(find.text('Reservation accepted'), findsOneWidget);

    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('You have a new reservation request'), findsNothing);
    tester.takeException();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Home shows the reservation popup while Radar is online', (
    tester,
  ) async {
    final previous = DriverRuntimeConfig.current;
    DriverRuntimeConfig.current = DriverRuntimeConfig(
      simulatedArrival: previous.simulatedArrival,
      externalRouting: previous.externalRouting,
      skipAccountActivation: previous.skipAccountActivation,
      liveMapTicker: previous.liveMapTicker,
      islandHint: previous.islandHint,
    );
    addTearDown(() => DriverRuntimeConfig.current = previous);
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final session = DriverSessionController(initialOnline: true);
    await tester.pumpWidget(
      LayoutViewport(
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          useInheritedMediaQuery: true,
          builder: (_, __) => MaterialApp(
            home: DriverHome(sessionController: session, initialOnline: true),
          ),
        ),
      ),
    );
    var shown = false;
    for (var i = 0; i < 240 && !shown; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      shown = find.text('You have a new reservation request').evaluate().isNotEmpty;
    }
    expect(shown, isTrue);
    expect(session.isOnline, isTrue);
    final deny = find.byKey(const ValueKey<String>('reservation-deny'));
    await tester.ensureVisible(deny);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(deny);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Reservation declined'), findsOneWidget);
    expect(session.isOnline, isTrue);
    tester.takeException();
    await tester.pumpWidget(const SizedBox());
  });
}
