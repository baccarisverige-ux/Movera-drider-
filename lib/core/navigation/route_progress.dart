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

    var closestIndex = 0;
    var closestDistance = double.infinity;
    for (var i = 0; i < points.length; i++) {
      final d = position.distanceMetersTo(points[i]);
      if (d < closestDistance) {
        closestDistance = d;
        closestIndex = i;
      }
    }

    var remaining = 0.0;
    for (var i = closestIndex; i < points.length - 1; i++) {
      remaining += points[i].distanceMetersTo(points[i + 1]);
    }

    var instructionIndex = instructionHint.clamp(
      0,
      math.max(0, route.instructions.length - 1),
    );
    while (instructionIndex < route.instructions.length) {
      final instruction = route.instructions[instructionIndex];
      final toManeuver =
          position.distanceMetersTo(instruction.maneuverLocation);
      final passed = closestIndex > 0 &&
          _hasPassed(points, closestIndex, instruction.maneuverLocation);
      if (toManeuver > passedManeuverMeters && !passed) {
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

    final last =
        route.instructions.isEmpty ? null : route.instructions.last;
    final toLast = last == null
        ? remaining
        : position.distanceMetersTo(last.maneuverLocation);

    return RouteProgress(
      closestIndex: closestIndex,
      distanceFromRouteMeters: closestDistance,
      remainingMeters: remaining,
      instructionIndex: math.max(0, route.instructions.length - 1),
      nextInstruction:
          last?.copyWith(distanceMeters: toLast) ?? last,
      distanceToManeuverMeters: toLast,
      offRoute: closestDistance > offRouteThresholdMeters,
    );
  }

  bool _hasPassed(
    List<GeoPoint> points,
    int closestIndex,
    GeoPoint maneuver,
  ) {
    var bestBefore = double.infinity;
    var bestAfter = double.infinity;
    for (var i = 0; i <= closestIndex; i++) {
      bestBefore = math.min(bestBefore, points[i].distanceMetersTo(maneuver));
    }
    for (var i = closestIndex; i < points.length; i++) {
      bestAfter = math.min(bestAfter, points[i].distanceMetersTo(maneuver));
    }
    return bestBefore + 4 < bestAfter;
  }
}
