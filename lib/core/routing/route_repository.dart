import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/core/geo/geo_point.dart';

class RoadRoute {
  const RoadRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  /// Map-layer points. Domain callers should use [geoPoints].
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  List<GeoPoint> get geoPoints =>
      [for (final point in points) GeoPoint.fromLatLng(point)];
}

abstract interface class RouteRepository {
  Future<RoadRoute> drivingRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  });
}
