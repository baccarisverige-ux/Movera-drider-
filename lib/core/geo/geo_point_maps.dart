import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/core/geo/geo_point.dart';

/// Maps-SDK adapter. Domain code imports [GeoPoint], not this file.
extension GeoPointMaps on GeoPoint {
  LatLng toLatLng() => LatLng(latitude, longitude);

  static GeoPoint fromLatLng(LatLng value) =>
      GeoPoint(value.latitude, value.longitude);
}
