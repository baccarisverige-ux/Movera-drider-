import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:movera/core/admin/driver_home_admin_content.dart';
import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/presentation/driver/home/components/reservation_route_map.dart';
import 'package:movera/widgets/custom_google_map.dart';
import 'package:movera/widgets/route_mark_pins.dart';

import '../../integration_test/headless_map_platform.dart';

ReservationRequestPreview _request(double latitude) =>
    ReservationRequestPreview(
      category: 'Comfort',
      fare: '120 kr',
      pickupLabel: 'Pickup',
      pickupAddress: 'Stockholm',
      dropoffAddress: 'Solna',
      pickupTime: '08:15',
      pickupDay: 'Today',
      tripMinutes: 20,
      tripKm: 5,
      pickup: GeoPoint(latitude, 18),
      dropoff: GeoPoint(latitude + .01, 18.01),
    );

Future<void> _render(
  WidgetTester tester,
  ReservationRequestPreview request,
  Future<BitmapDescriptor> Function(RouteMarkKind, String, String?) icon, {
  bool labelled = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ReservationRouteMap(
          request: request,
          route: const [],
          markerIcon: icon,
          labelled: labelled,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Set<Marker> _markers(WidgetTester tester) =>
    tester.widget<CustomGoogleMap>(find.byType(CustomGoogleMap)).markers!;

void main() {
  setUp(() {
    final original = GoogleMapsFlutterPlatform.instance;
    GoogleMapsFlutterPlatform.instance = HeadlessMapPlatform();
    addTearDown(() => GoogleMapsFlutterPlatform.instance = original);
  });

  testWidgets(
    'changed reservation updates markers with an unchanged route list',
    (tester) async {
      Future<BitmapDescriptor> icon(
        RouteMarkKind kind,
        String title,
        String? time,
      ) async => BitmapDescriptor.defaultMarker;
      await _render(tester, _request(59.3), icon);
      expect(_markers(tester).first.position.latitude, 59.3);
      await _render(tester, _request(59.4), icon);
      expect(
        _markers(tester).map((m) => m.position.latitude),
        containsAll([59.4, closeTo(59.41, .000001)]),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'late marker work from an old reservation cannot replace new markers',
    (tester) async {
      final oldIcon = Completer<BitmapDescriptor>();
      var calls = 0;
      Future<BitmapDescriptor> icon(
        RouteMarkKind kind,
        String title,
        String? time,
      ) {
        if (++calls == 1) return oldIcon.future;
        return Future.value(BitmapDescriptor.defaultMarker);
      }

      await _render(tester, _request(59.3), icon);
      await _render(tester, _request(59.4), icon);
      oldIcon.complete(BitmapDescriptor.defaultMarker);
      await tester.pumpAndSettle();
      expect(
        _markers(tester).map((m) => m.position.latitude),
        containsAll([59.4, closeTo(59.41, .000001)]),
      );
      expect(calls, 3);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('label mode refreshes existing marker anchors', (tester) async {
    final request = _request(59.3);
    Future<BitmapDescriptor> icon(
      RouteMarkKind kind,
      String title,
      String? time,
    ) async => BitmapDescriptor.defaultMarker;
    await _render(tester, request, icon);
    expect(
      _markers(tester).every((m) => m.anchor == const Offset(.5, .5)),
      isTrue,
    );
    await _render(tester, request, icon, labelled: true);
    expect(
      _markers(tester).every((m) => m.anchor != const Offset(.5, .5)),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed marker rendering keeps endpoint markers with fallback icons',
    (tester) async {
      await _render(
        tester,
        _request(59.3),
        (_, _, _) async => throw StateError('Renderer unavailable'),
      );
      expect(_markers(tester), hasLength(2));
      expect(
        _markers(tester).every((m) => m.icon == BitmapDescriptor.defaultMarker),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
