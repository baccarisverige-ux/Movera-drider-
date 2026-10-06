import 'dart:async';

import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/location/driver_location_repository.dart';
import 'package:movera/core/routing/route_instruction.dart';
import 'package:movera/core/routing/route_repository.dart';
import 'package:movera/core/navigation/route_progress.dart';

enum DriverCameraMode { following, browsing, overview }

/// SDK-neutral output: no widgets, trip lifecycle or Google Maps dependency.
class DriverCameraPose {
  const DriverCameraPose(this.target, this.zoom, this.bearing, this.tilt);
  final GeoPoint target;
  final double zoom;
  final double bearing;
  final double tilt;
}

abstract interface class DriverCameraPort {
  Future<void> animate(DriverCameraPose pose);
  Future<void> overview(List<GeoPoint> points, double padding);
  void interrupt();
  void dispose();
}

/// Geometry and maneuver-aware framing. Each route replacement resets progress.
/// Preview an upcoming turn, close in at the maneuver, then recover to cruise.
class DriverCameraPolicy {
  final RouteProgressCalculator _progress = const RouteProgressCalculator();
  RoadRoute? _route;
  double? _along;
  int _instructionHint = 0;
  DriverCameraPose? _previous;

  DriverCameraPose resolve({
    required DriverLocation location,
    RoadRoute? route,
    bool navigating = false,
    bool waiting = false,
    bool immediate = false,
  }) {
    if (!identical(route, _route)) {
      _route = route;
      _along = null;
      _instructionHint = 0;
    }
    var bearing =
        location.headingDegrees.isFinite && location.headingDegrees >= 0
        ? location.headingDegrees % 360
        : (_previous?.bearing ?? 0.0);
    var zoom = waiting ? 17.2 : 16.8;
    var tilt = navigating && !waiting ? 40.0 : 0.0;
    if (navigating && !waiting && route != null && route.points.length > 1) {
      final progress = _progress.measure(
        route: route,
        position: location.point,
        instructionHint: _instructionHint,
        previousAlongMeters: _along,
      );
      _along = progress.alongMeters;
      _instructionHint = progress.instructionIndex;
      if (!progress.offRoute) {
        final index = progress.closestIndex;
        // Local tangent, not bearing to the final destination. Repeated points
        // and very short segments must not produce a spurious north bearing.
        final from = route.points[index];
        for (var i = index + 1; i < route.points.length; i++) {
          if (from.distanceMetersTo(route.points[i]) >= 12 ||
              i == route.points.length - 1) {
            if (from.distanceMetersTo(route.points[i]) >= 1) {
              bearing = from.bearingTo(route.points[i]);
            }
            break;
          }
        }
        final maneuver = progress.nextInstruction;
        final distance = progress.distanceToManeuverMeters;
        if (maneuver != null && _needsPreview(maneuver.type)) {
          if (distance <= 70) {
            // 16.1 -> 17.6 as the car approaches the intersection/roundabout.
            zoom = 16.1 + 1.5 * (1 - distance / 70).clamp(0.0, 1.0);
            tilt = 30;
          } else if (distance <= 250) {
            zoom = 16.1 + 0.7 * ((distance - 70) / 180);
            tilt = 30;
          }
        }
      }
    }
    final previous = _previous;
    if (!immediate && previous != null) {
      // Bound zoom changes and use the shortest rotation across 359° -> 0°.
      zoom = previous.zoom + (zoom - previous.zoom).clamp(-0.25, 0.25);
      bearing = GeoPoint.shortestAngleLerp(previous.bearing, bearing, 0.45);
      tilt = previous.tilt + (tilt - previous.tilt).clamp(-8.0, 8.0);
    }
    return _previous = DriverCameraPose(location.point, zoom, bearing, tilt);
  }

  bool _needsPreview(RouteManeuverType type) => switch (type) {
    RouteManeuverType.turn ||
    RouteManeuverType.endOfRoad ||
    RouteManeuverType.merge ||
    RouteManeuverType.fork ||
    RouteManeuverType.ramp ||
    RouteManeuverType.onRamp ||
    RouteManeuverType.offRamp ||
    RouteManeuverType.roundabout ||
    RouteManeuverType.rotary ||
    RouteManeuverType.roundaboutTurn ||
    RouteManeuverType.exitRoundabout ||
    RouteManeuverType.exitRotary => true,
    _ => false,
  };
}

/// One owner for follow/free mode, lifecycle and serialized camera commands.
/// GPS continues in browse mode but never steals the driver's viewport.
class DriverCameraController {
  DriverCameraController({DriverCameraPolicy? policy, DateTime Function()? now})
    : _policy = policy ?? DriverCameraPolicy(),
      _now = now ?? DateTime.now;
  final DateTime Function() _now;
  final DriverCameraPolicy _policy;
  DriverCameraPort? _port;
  DriverLocation? _location;
  RoadRoute? _route;
  bool _navigating = false;
  bool _waiting = false;
  bool _suspended = false;
  bool _disposed = false;
  bool _busy = false;
  int _epoch = 0;
  DriverCameraPose? _pending;
  Timer? _throttle;
  DriverCameraMode _mode = DriverCameraMode.following;
  DriverCameraMode get mode => _mode;

  void attach(DriverCameraPort port) {
    if (_disposed) {
      port.dispose();
      return;
    }
    _invalidate();
    _port?.dispose();
    _port = port;
    _busy = false;
    _request(immediate: true);
  }

  void update({
    required DriverLocation location,
    RoadRoute? route,
    bool navigating = false,
    bool waiting = false,
  }) {
    if (_disposed || !location.isUsableAt(_now())) {
      return;
    }
    _location = location;
    _route = route;
    _navigating = navigating;
    _waiting = waiting;
    _request();
  }

  void userGesture() {
    if (_disposed) {
      return;
    }
    _mode = DriverCameraMode.browsing;
    _invalidate();
  }

  void recenter() {
    if (_disposed) {
      return;
    }
    _mode = DriverCameraMode.following;
    _invalidate();
    _request(immediate: true);
  }

  Future<void> preview(List<GeoPoint> points, {double padding = 80}) async {
    if (_disposed ||
        _suspended ||
        mode == DriverCameraMode.browsing ||
        points.isEmpty ||
        _port == null) {
      return;
    }
    _invalidate();
    _mode = DriverCameraMode.overview;
    try {
      await _port!.overview(points, padding);
    } catch (_) {}
  }

  void suspend() {
    _suspended = true;
    _invalidate();
  }

  void resume() {
    _suspended = false;
    _request(immediate: true);
  }

  bool get _canFollow =>
      !_disposed &&
      !_suspended &&
      mode == DriverCameraMode.following &&
      _port != null;

  void _invalidate() {
    _epoch++;
    _pending = null;
    _throttle?.cancel();
    _throttle = null;
    _port?.interrupt();
    _busy = false;
  }

  void _request({bool immediate = false}) {
    final location = _location;
    if (!_canFollow || location == null || !location.isUsableAt(_now())) {
      return;
    }
    _pending = _policy.resolve(
      location: location,
      route: _route,
      navigating: _navigating,
      waiting: _waiting,
      immediate: immediate,
    );
    if (immediate) {
      _throttle?.cancel();
      _throttle = null;
    }
    if (!_busy && _throttle == null) {
      unawaited(_flush());
    }
  }

  Future<void> _flush() async {
    final port = _port;
    final pose = _pending;
    if (!_canFollow || _busy || port == null || pose == null) {
      return;
    }
    _pending = null;
    _busy = true;
    final epoch = _epoch;
    try {
      await port.animate(pose);
    } catch (_) {
      // An unavailable/disposed map must not break the trip lifecycle.
    }
    if (_disposed || epoch != _epoch) {
      return;
    }
    _busy = false;
    _throttle = Timer(const Duration(milliseconds: 250), () {
      _throttle = null;
      if (_canFollow) {
        unawaited(_flush());
      }
    });
  }

  void dispose() {
    _disposed = true;
    _invalidate();
    _port?.dispose();
    _port = null;
  }
}
