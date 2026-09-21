import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Neutral geographic point used by domain/repository boundaries.
///
/// Google Maps [LatLng] stays in adapters and presentation, not in core
/// interfaces that backend implementations will replace.
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  LatLng toLatLng() => LatLng(latitude, longitude);

  factory GeoPoint.fromLatLng(LatLng value) =>
      GeoPoint(value.latitude, value.longitude);

  double distanceMetersTo(GeoPoint other) {
    const earthRadiusMeters = 6371000.0;
    final lat1 = latitude * math.pi / 180;
    final lat2 = other.latitude * math.pi / 180;
    final dLat = (other.latitude - latitude) * math.pi / 180;
    final dLon = (other.longitude - longitude) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earthRadiusMeters * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  @override
  bool operator ==(Object other) {
    return other is GeoPoint &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoPoint($latitude, $longitude)';
}
