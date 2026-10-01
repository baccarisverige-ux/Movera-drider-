import 'dart:math' as math;

import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/routing/route_instruction.dart';
import 'package:movera/core/routing/route_repository.dart';

class RouteProgress {
  const RouteProgress({
    required this.closestIndex,
    required this.distanceFromRouteMeters,
    required this.remainingMeters,
    required this.instructionIndex,
    required this.nextInstruction,
    required this.distanceToManeuverMeters,
    required this.offRoute,
  });

  final int closestIndex;
  final double distanceFromRouteMeters;
  final double remainingMeters;
  final int instructionIndex;
  final RouteInstruction? nextInstruction;
  final double distanceToManeuverMeters;
  final bool offRoute;
}

class RouteProgressCalculator {
  const RouteProgressCalculator({
    this.offRouteThresholdMeters = 50,
    this.passedManeuverMeters = 18,
  });

  final double offRouteThresholdMeters;
  final double passedManeuverMeters;

  RouteProgress measure({
    required RoadRoute route,
    required GeoPoint position,
    int instructionHint = 0,
  }) {
    final points = route.geoPoints;
    if (points.length < 2) {
      return RouteProgress(
        closestIndex: 0,
        distanceFromRouteMeters: 0,
        remainingMeters: route.distanceMeters,
        instructionIndex: 0,
        nextInstruction: route.instructions.isEmpty
            ? null
            : route.instructions.first,
        distanceToManeuverMeters: route.instructions.isEmpty
            ? route.distanceMeters
            : route.instructions.first.distanceMeters,
        offRoute: false,
      );
    }

    final projection = _project(points, position);
    final closestIndex = projection.index;
    final closestDistance = projection.distance;
    final remaining = projection.total - projection.along;

    var instructionIndex = instructionHint
        .clamp(0, math.max(0, route.instructions.length - 1))
        .toInt();
    while (instructionIndex < route.instructions.length) {
      final instruction = route.instructions[instructionIndex];
      final maneuver = _project(points, instruction.maneuverLocation);
      final toManeuver = math.max(0.0, maneuver.along - projection.along);
      final passed = projection.along > maneuver.along + 4;
      if (!passed || instruction.isArrival) {
        return RouteProgress(
          closestIndex: closestIndex,
          distanceFromRouteMeters: closestDistance,
          remainingMeters: remaining,
          instructionIndex: instructionIndex,
          nextInstruction: instruction.copyWith(distanceMeters: toManeuver),
          distanceToManeuverMeters: toManeuver,
          offRoute: closestDistance > offRouteThresholdMeters,
        );
      }
      instructionIndex++;
    }

    final last = route.instructions.isEmpty ? null : route.instructions.last;
    final toLast = last == null
        ? remaining
        : math.max(
            0.0,
            _project(points, last.maneuverLocation).along - projection.along,
          );

    return RouteProgress(
      closestIndex: closestIndex,
      distanceFromRouteMeters: closestDistance,
      remainingMeters: remaining,
      instructionIndex: math.max(0, route.instructions.length - 1),
      nextInstruction: last?.copyWith(distanceMeters: toLast) ?? last,
      distanceToManeuverMeters: toLast,
      offRoute: closestDistance > offRouteThresholdMeters,
    );
  }

  /// Project onto route segments rather than treating sparse vertices as roads.
  ({int index, double distance, double along, double total}) _project(
    List<GeoPoint> points,
    GeoPoint position,
  ) {
    var total = 0.0, bestDistance = double.infinity, along = 0.0;
    var index = 0;
    final scale = math.cos(position.latitude * math.pi / 180);
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i], b = points[i + 1];
      final dx = (b.longitude - a.longitude) * scale;
      final dy = b.latitude - a.latitude;
      final px = (position.longitude - a.longitude) * scale;
      final py = position.latitude - a.latitude;
      final length2 = dx * dx + dy * dy;
      final t = length2 == 0
          ? 0.0
          : ((px * dx + py * dy) / length2).clamp(0.0, 1.0);
      final projected = GeoPoint(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );
      final distance = position.distanceMetersTo(projected);
      final length = a.distanceMetersTo(b);
      if (distance < bestDistance) {
        bestDistance = distance;
        along = total + length * t;
        index = i;
      }
      total += length;
    }
    return (index: index, distance: bestDistance, along: along, total: total);
  }
}
