import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/geo/geo_point_maps.dart';

void main() {
  test('GeoPoint converts to and from LatLng in the maps adapter', () {
    const point = GeoPoint(59.3293, 18.0686);
    final latLng = point.toLatLng();

    expect(latLng, const LatLng(59.3293, 18.0686));
    expect(GeoPointMaps.fromLatLng(latLng), point);
  });

  test('geo_point.dart does not import the maps SDK', () {
    final dart = File('lib/core/geo/geo_point.dart').readAsStringSync();
    expect(dart.contains('google_maps_flutter'), isFalse);
    expect(dart.contains('toLatLng'), isFalse);
    expect(dart.contains('fromLatLng'), isFalse);
  });

  test('GeoPoint distance is road-agnostic meters between two points', () {
    const origin = GeoPoint(59.3293, 18.0686);
    const nearby = GeoPoint(59.3303, 18.0686);

    expect(origin.distanceMetersTo(origin), 0);
    expect(origin.distanceMetersTo(nearby), closeTo(111.2, 2));
  });
}
