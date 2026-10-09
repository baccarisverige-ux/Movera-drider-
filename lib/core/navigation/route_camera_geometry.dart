import 'dart:math' as math;

import 'package:movera/core/geo/geo_point.dart';

/// Along-route sampling shared by camera, car snapping and traveled stroke.
class RouteCameraGeometry {
  RouteCameraGeometry(List<GeoPoint> points)
    : points = List<GeoPoint>.unmodifiable(points) {
    for (var i = 1; i < points.length; i++) {
      distances.add(distances.last + points[i - 1].distanceMetersTo(points[i]));
    }
  }
  final List<GeoPoint> points;
  final List<double> distances = [0];
  double _boundedMeters(double meters) => meters.isNaN
      ? 0
      : math.min(distances.last, math.max(0, meters));

  GeoPoint at(double meters) {
    if (points.isEmpty) {
      throw StateError('Empty route');
    }
    final bounded = _boundedMeters(meters);
    for (var i = 1; i < points.length; i++) {
      if (distances[i] >= bounded) {
        final length = distances[i] - distances[i - 1];
        final t = length == 0
            ? 0.0
            : ((bounded - distances[i - 1]) / length).clamp(0.0, 1.0);
        final a = points[i - 1], b = points[i];
        return GeoPoint(
          a.latitude + (b.latitude - a.latitude) * t,
          a.longitude + (b.longitude - a.longitude) * t,
        );
      }
    }
    return points.last;
  }

  List<GeoPoint> remaining(double meters) {
    final bounded = _boundedMeters(meters);
    return [
      at(bounded),
      for (var i = 0; i < points.length; i++)
        if (distances[i] > bounded) points[i],
    ];
  }

  List<GeoPoint> traveled(double meters) {
    final bounded = _boundedMeters(meters);
    return [
      for (var i = 0; i < points.length; i++)
        if (distances[i] < bounded) points[i],
      at(bounded),
    ];
  }
}
