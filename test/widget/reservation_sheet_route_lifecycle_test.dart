import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/admin/driver_home_admin_content.dart';
import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/session/driver_runtime_config.dart';
import 'package:movera/presentation/driver/home/components/reservation_request_sheet.dart';
import 'package:movera/presentation/driver/home/components/reservation_route_map.dart';

ReservationRequestPreview _request(
  double lat, {
  String time = '07:40',
  int minutes = 19,
  bool stops = false,
}) => ReservationRequestPreview(
  category: 'Comfort',
  fare: '126 kr',
  pickupLabel: 'Pickup today',
  pickupAddress: 'Long pickup address, building 45, entrance B, Stockholm',
  dropoffAddress: 'Long drop-off address, building 68, entrance C, Stockholm',
  pickupTime: time,
  pickupDay: 'Today',
  tripMinutes: minutes,
  tripKm: 9.4,
  pickup: GeoPoint(lat, 18.0),
  dropoff: GeoPoint(lat + .01, 18.01),
  stops: stops
      ? [
          for (var i = 0; i < 6; i++)
            ReservationStop(
              address: 'Stop $i, Stockholm',
              point: GeoPoint(lat, 18.002 + i * .001),
            ),
        ]
      : const [],
);

Widget _map(BuildContext context) => const ColoredBox(color: Colors.grey);

void main() {
  setUp(() {
    final previous = DriverRuntimeConfig.current;
    DriverRuntimeConfig.current = const DriverRuntimeConfig(
      simulatedArrival: false,
      externalRouting: false,
      skipAccountActivation: false,
    );
    addTearDown(() => DriverRuntimeConfig.current = previous);
  });

  testWidgets(
    'reused reservation sheet opens the route matching its new request',
    (tester) async {
      var request = _request(59.3);
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return ReservationRequestSheet(
                  request: request,
                  mapBuilder: _map,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      update(() => request = _request(59.4));
      await tester.pumpAndSettle();
      tester
          .widget<InkWell>(
            find.byKey(const ValueKey<String>('reservation-map-open')),
          )
          .onTap!();
      await tester.pumpAndSettle();
      final page = tester.widget<ReservationRouteMapPage>(
        find.byType(ReservationRouteMapPage),
      );
      expect(page.request, same(request));
      expect(await page.route, reservationWaypoints(request));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'disposed reservation map callback does not access State context',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReservationRequestSheet(
              request: _request(59.3),
              mapBuilder: _map,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final open = tester
          .widget<InkWell>(
            find.byKey(const ValueKey<String>('reservation-map-open')),
          )
          .onTap!;
      await tester.pumpWidget(const SizedBox());
      open();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'short enlarged-text map keeps long stop details bounded and scrollable',
    (tester) async {
      tester.view.physicalSize = const Size(568, 320);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final request = _request(59.3, stops: true);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: ReservationRouteMapPage(
            request: request,
            route: Future.value(reservationWaypoints(request)),
            mapBuilder: (context, _) => _map(context),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rect = tester.getRect(
        find.byKey(const ValueKey('reservation-route-details')),
      );
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(320));
      await tester.ensureVisible(find.text(request.dropoffAddress));
      await tester.pumpAndSettle();
      expect(find.text(request.dropoffAddress).hitTestable(), findsOneWidget);
      final address = tester.widget<Text>(find.text(request.dropoffAddress));
      expect(address.maxLines, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reservation map action has a named accessible button', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReservationRequestSheet(
            request: _request(59.3),
            mapBuilder: _map,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('View reservation route'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('arrival calculation does not normalize malformed times or negative durations', () {
    for (final time in ['24:00', '07:90', '-1:20', '07:-1']) {
      expect(_request(59.3, time: time).arrivalTime, time);
    }
    expect(_request(59.3, minutes: -1).arrivalTime, '07:40');
    expect(_request(59.3, time: '23:50', minutes: 25).arrivalTime, '00:15');
  });
}
