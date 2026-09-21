import 'dart:math' as math;

/// Neutral geographic point used by domain/repository boundaries.
///
/// Maps SDK conversion lives in `geo_point_maps.dart` (D3).
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

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

  /// Initial bearing from this point toward [other], degrees clockwise from north.
  double bearingTo(GeoPoint other) {
    final lat1 = latitude * math.pi / 180;
    final lat2 = other.latitude * math.pi / 180;
    final dLon = (other.longitude - longitude) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  /// Prefer GPS heading while moving, otherwise the segment bearing.
  double resolvedHeading({
    required double gpsHeading,
    required GeoPoint previous,
    required double fallback,
  }) {
    final moved = previous.distanceMetersTo(this);
    if (gpsHeading.isFinite && gpsHeading != 0 && moved >= 1.5) {
      return shortestAngleLerp(fallback, gpsHeading, 0.32);
    }
    if (moved >= 1.5) {
      return shortestAngleLerp(fallback, previous.bearingTo(this), 0.32);
    }
    return fallback;
  }

  static double shortestAngleLerp(double from, double to, double t) {
    var delta = (to - from) % 360;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    return (from + delta * t + 360) % 360;
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
