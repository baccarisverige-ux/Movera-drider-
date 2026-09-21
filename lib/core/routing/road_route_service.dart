import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/routing/osrm_route_parser.dart';
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
  RoadRouteService({
    http.Client? client,
    OsrmRouteParser parser = const OsrmRouteParser(),
  })  : _client = client ?? http.Client(),
        _parser = parser;

  final http.Client _client;
  final OsrmRouteParser _parser;

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
      const <String, String>{
        'overview': 'full',
        'geometries': 'geojson',
        'steps': 'true',
        'annotations': 'false',
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

    try {
      return _parser.parseRoute(route);
    } on FormatException catch (error) {
      throw RoadRouteException(error.message);
    }
  }
}
