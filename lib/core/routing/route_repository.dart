import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/routing/route_instruction.dart';

class RoadRoute {
  const RoadRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.instructions = const <RouteInstruction>[],
  });

  /// Domain polyline. Presentation converts via `RoadRouteMaps.latLngPoints`.
  final List<GeoPoint> points;
  final double distanceMeters;
  final double durationSeconds;
  final List<RouteInstruction> instructions;

  List<GeoPoint> get geoPoints => points;
}

abstract interface class RouteRepository {
  Future<RoadRoute> drivingRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  });
}
