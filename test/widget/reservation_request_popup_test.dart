import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/admin/driver_home_admin_content.dart';
import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/session/driver_runtime_config.dart';
import 'package:movera/core/session/driver_session_controller.dart';
import 'package:movera/presentation/driver/home/components/reservation_request_sheet.dart';
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
    expect(
      find.text('Reservation accepted · Pickup today at 07:40'),
      findsOneWidget,
    );

    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('You have a new reservation request'), findsNothing);
    tester.takeException();
    await tester.pumpWidget(const SizedBox());
  });
}
