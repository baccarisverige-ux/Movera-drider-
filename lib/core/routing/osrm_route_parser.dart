import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/routing/route_instruction.dart';
import 'package:movera/core/routing/route_repository.dart';

/// Parses an OSRM `route` object into Movera domain models.
///
/// Presentation never sees provider JSON. A future backend adapter can
/// return [RoadRoute] without this parser.
class OsrmRouteParser {
  const OsrmRouteParser();

  RoadRoute parseRoute(Map<String, dynamic> route) {
    final geometry = route['geometry'];
    if (geometry is! Map<String, dynamic>) {
      throw const FormatException('Invalid route geometry.');
    }

    final coordinatesJson = geometry['coordinates'];
    if (coordinatesJson is! List || coordinatesJson.length < 2) {
      throw const FormatException('Route geometry is empty.');
    }

    final points = <LatLng>[];
    for (final coordinate in coordinatesJson) {
      if (coordinate is! List || coordinate.length < 2) continue;
      final longitude = coordinate[0];
      final latitude = coordinate[1];
      if (longitude is num && latitude is num) {
        points.add(LatLng(latitude.toDouble(), longitude.toDouble()));
      }
    }

    if (points.length < 2) {
      throw const FormatException('Route geometry is empty.');
    }

    final distance = route['distance'];
    final duration = route['duration'];

    return RoadRoute(
      points: points,
      distanceMeters: distance is num ? distance.toDouble() : 0,
      durationSeconds: duration is num ? duration.toDouble() : 0,
      instructions: parseInstructions(route),
    );
  }

  List<RouteInstruction> parseInstructions(Map<String, dynamic> route) {
    final legs = route['legs'];
    if (legs is! List) return const <RouteInstruction>[];

    final instructions = <RouteInstruction>[];
    for (final leg in legs) {
      if (leg is! Map<String, dynamic>) continue;
      final steps = leg['steps'];
      if (steps is! List) continue;
      for (final step in steps) {
        if (step is! Map<String, dynamic>) continue;
        final parsed = _parseStep(step);
        if (parsed != null) instructions.add(parsed);
      }
    }
    return instructions;
  }

  RouteInstruction? _parseStep(Map<String, dynamic> step) {
    final maneuver = step['maneuver'];
    if (maneuver is! Map<String, dynamic>) return null;

    final location = maneuver['location'];
    if (location is! List || location.length < 2) return null;
    final longitude = location[0];
    final latitude = location[1];
    if (longitude is! num || latitude is! num) return null;

    final type = RouteManeuverTypeX.fromOsrm(
      maneuver['type'] is String ? maneuver['type'] as String : null,
    );
    final modifier =
        maneuver['modifier'] is String ? maneuver['modifier'] as String : '';
    final roadName = step['name'] is String ? step['name'] as String : null;
    final exit = maneuver['exit'];
    final exitNumber = exit == null ? null : '$exit';
    final distance = step['distance'];

    return RouteInstruction(
      type: type,
      modifier: modifier,
      text: RouteInstructionCopy.build(
        type: type,
        modifier: modifier,
        roadName: roadName,
        exitNumber: exitNumber,
      ),
      distanceMeters: distance is num ? distance.toDouble() : 0,
      maneuverLocation: GeoPoint(latitude.toDouble(), longitude.toDouble()),
      roadName: roadName?.trim().isEmpty == true ? null : roadName,
      exitNumber: exitNumber,
    );
  }
}
