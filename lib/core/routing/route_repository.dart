import 'package:google_maps_flutter/google_maps_flutter.dart';

class RoadRoute {
  const RoadRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
}

abstract interface class RouteRepository {
  Future<RoadRoute> drivingRoute({
    required LatLng origin,
    required LatLng destination,
  });
}
