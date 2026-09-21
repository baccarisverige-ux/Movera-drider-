import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/routing/route_repository.dart';

class RoadRouteException implements Exception {
  const RoadRouteException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Frontend road-routing adapter.
///
/// The current implementation uses the public OSRM demo endpoint so the
/// frontend can follow actual roads without exposing a private routing key.
/// Production should swap this adapter for Movera's backend routing endpoint
/// while keeping the UI contract unchanged.
class RoadRouteService implements RouteRepository {
  RoadRouteService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<RoadRoute> drivingRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  }) async {
    final coordinates =
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}';

    final uri = Uri.https(
      'router.project-osrm.org',
      '/route/v1/driving/$coordinates',
      <String, String>{
        'overview': 'full',
        'geometries': 'geojson',
        'steps': 'false',
        'alternatives': 'false',
      },
    );

    final response = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw RoadRouteException(
        'Routing service returned ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['code'] != 'Ok') {
      throw const RoadRouteException('No road route was found.');
    }

    final routes = decoded['routes'];
    if (routes is! List || routes.isEmpty) {
      throw const RoadRouteException('No road route was found.');
    }

    final route = routes.first;
    if (route is! Map<String, dynamic>) {
      throw const RoadRouteException('Invalid route response.');
    }

    final geometry = route['geometry'];
    if (geometry is! Map<String, dynamic>) {
      throw const RoadRouteException('Invalid route geometry.');
    }

    final coordinatesJson = geometry['coordinates'];
    if (coordinatesJson is! List || coordinatesJson.length < 2) {
      throw const RoadRouteException('Route geometry is empty.');
    }

    final points = <LatLng>[];
    for (final coordinate in coordinatesJson) {
      if (coordinate is! List || coordinate.length < 2) continue;

      final longitude = coordinate[0];
      final latitude = coordinate[1];
      if (longitude is num && latitude is num) {
        points.add(
          LatLng(latitude.toDouble(), longitude.toDouble()),
        );
      }
    }

    if (points.length < 2) {
      throw const RoadRouteException('Route geometry is empty.');
    }

    final distance = route['distance'];
    final duration = route['duration'];

    return RoadRoute(
      points: points,
      distanceMeters: distance is num ? distance.toDouble() : 0,
      durationSeconds: duration is num ? duration.toDouble() : 0,
    );
  }
}
