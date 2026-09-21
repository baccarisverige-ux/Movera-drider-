import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/core/geo/geo_point.dart';

void main() {
  test('GeoPoint converts to and from LatLng without leaking maps types', () {
    const point = GeoPoint(59.3293, 18.0686);
    final latLng = point.toLatLng();

    expect(latLng, const LatLng(59.3293, 18.0686));
    expect(GeoPoint.fromLatLng(latLng), point);
  });
}
