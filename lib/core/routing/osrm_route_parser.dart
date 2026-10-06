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

    final points = <GeoPoint>[];
    for (final coordinate in coordinatesJson) {
      if (coordinate is! List || coordinate.length < 2) {
        continue;
      }
      final longitude = coordinate[0];
      final latitude = coordinate[1];
      if (longitude is num && latitude is num) {
        points.add(GeoPoint(latitude.toDouble(), longitude.toDouble()));
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
    if (legs is! List) {
      return const <RouteInstruction>[];
    }

    final instructions = <RouteInstruction>[];
    for (final leg in legs) {
      if (leg is! Map<String, dynamic>) {
        continue;
      }
      final steps = leg['steps'];
      if (steps is! List) {
        continue;
      }
      for (var index = 0; index < steps.length; index++) {
        final step = steps[index];
        if (step is! Map<String, dynamic>) {
          continue;
        }
        final parsed = _parseStep(
          step,
          exitAngleDegrees: _exitAngle(steps, index),
        );
        if (parsed != null) {
          instructions.add(parsed);
        }
      }
    }
    return instructions;
  }

  // Entry bearing_after is the tangent onto the circle, not the exit.
  // Pair it with an explicit exit maneuver before drawing an outgoing arrow.
  double? _exitAngle(List<dynamic> steps, int index) {
    final step = steps[index];
    if (step is! Map<String, dynamic>) {
      return null;
    }
    final entry = step['maneuver'];
    if (entry is! Map<String, dynamic>) {
      return null;
    }
    final type = entry['type'];
    if (type != 'roundabout' && type != 'rotary' && type != 'roundabout turn') {
      return null;
    }
    double? bearing(dynamic value) =>
        value is num && value.isFinite && value >= 0 && value <= 360
        ? value.toDouble() % 360
        : null;
    final before = bearing(entry['bearing_before']);
    if (before == null) {
      return null;
    }
    double? after;
    if (type == 'roundabout turn') {
      after = bearing(entry['bearing_after']);
    } else {
      for (var next = index + 1; next < steps.length; next++) {
        final candidate = steps[next];
        if (candidate is! Map<String, dynamic>) {
          break;
        }
        final exit = candidate['maneuver'];
        if (exit is! Map<String, dynamic>) {
          break;
        }
        if (exit['type'] == 'exit roundabout' ||
            exit['type'] == 'exit rotary') {
          after = bearing(exit['bearing_after']);
          break;
        }
        if (exit['type'] != 'continue' &&
            exit['type'] != 'notification' &&
            exit['type'] != 'new name') {
          break;
        }
      }
    }
    return after == null ? null : (after - before + 540) % 360 - 180;
  }

  RouteInstruction? _parseStep(
    Map<String, dynamic> step, {
    double? exitAngleDegrees,
  }) {
    final maneuver = step['maneuver'];
    if (maneuver is! Map<String, dynamic>) {
      return null;
    }

    final location = maneuver['location'];
    if (location is! List || location.length < 2) {
      return null;
    }
    final longitude = location[0];
    final latitude = location[1];
    if (longitude is! num || latitude is! num) {
      return null;
    }

    final type = RouteManeuverTypeX.fromOsrm(
      maneuver['type'] is String ? maneuver['type'] as String : null,
    );
    final modifier = maneuver['modifier'] is String
        ? maneuver['modifier'] as String
        : '';
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
      exitAngleDegrees: exitAngleDegrees,
    );
  }
}
