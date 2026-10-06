import 'package:movera/core/geo/geo_point.dart';

class DriverLocation {
  const DriverLocation({
    required this.point,
    this.headingDegrees = 0,
    this.speedMetersPerSecond,
    this.measuredAt,
    this.accuracyMeters,
  });

  final GeoPoint point;
  final double headingDegrees;
  final double? speedMetersPerSecond;

  /// A stationary/invalid GPS course must never spin the vehicle marker.
  double courseOr(double previous) =>
      speedMetersPerSecond != null &&
          speedMetersPerSecond!.isFinite &&
          speedMetersPerSecond! >= 1 &&
          headingDegrees.isFinite &&
          headingDegrees >= 0
      ? headingDegrees % 360
      : previous;
  final DateTime? measuredAt;
  final double? accuracyMeters;
  bool isUsableAt(DateTime now) {
    final at = measuredAt, accuracy = accuracyMeters;
    if (at == null ||
        accuracy == null ||
        !accuracy.isFinite ||
        accuracy < 0 ||
        accuracy > 50) {
      return false;
    }
    final age = now.difference(at);
    return !age.isNegative &&
        age <= const Duration(seconds: 30) &&
        point.latitude.isFinite &&
        point.longitude.isFinite &&
        point.latitude.abs() <= 90 &&
        point.longitude.abs() <= 180;
  }
}

abstract interface class DriverLocationRepository {
  Future<DriverLocation> getCurrentPosition();

  Stream<DriverLocation> watchPosition({int distanceFilterMeters = 8});
}
