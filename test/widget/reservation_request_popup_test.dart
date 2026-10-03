import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/admin/driver_home_admin_content.dart';
import 'package:movera/core/session/driver_runtime_config.dart';
import 'package:movera/core/session/driver_session_controller.dart';
import 'package:movera/presentation/driver/home/components/reservation_request_sheet.dart';
import 'package:movera/presentation/driver/home/home.dart';
import 'package:movera/presentation/driver/scheduled%20rides/scheduled_rides.dart';
import 'package:movera/widgets/layout_viewport.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _request = ReservationRequestPreview(
  category: 'Comfort',
  fare: '126.75 kr',
  pickupLabel: 'Pickup today at 07:40',
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final (label, viewTrip) in [('View trip', true), ('Dismiss', false)]) {
    testWidgets('reservation sheet $label resolves $viewTrip', (tester) async {
      bool? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  result = await showReservationRequestSheet(context, _request),
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
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(result, viewTrip);
      expect(find.text('You have a new reservation request'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Home announces a new reservation once and View trip opens it', (
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

    await tester.tap(find.text('View trip'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(ScheduledRidesScreen), findsOneWidget);

    await tester.pageBack();
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('You have a new reservation request'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
