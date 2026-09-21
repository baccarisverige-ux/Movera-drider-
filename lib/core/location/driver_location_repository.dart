import 'package:movera/core/geo/geo_point.dart';

class DriverLocation {
  const DriverLocation({
    required this.point,
    this.headingDegrees = 0,
  });

  final GeoPoint point;
  final double headingDegrees;
}

abstract interface class DriverLocationRepository {
  Future<DriverLocation> getCurrentPosition();

  Stream<DriverLocation> watchPosition({
    int distanceFilterMeters = 8,
  });
}
