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
