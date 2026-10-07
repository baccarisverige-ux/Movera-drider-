import 'dart:async';
import 'dart:math' as math;

import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/location/driver_location_repository.dart';
import 'package:movera/core/routing/route_instruction.dart';
import 'package:movera/core/routing/route_repository.dart';
import 'package:movera/core/navigation/route_progress.dart';
import 'package:movera/core/navigation/route_camera_geometry.dart';

enum DriverCameraMode { following, browsing, overview }

enum DriverCameraState { explore, preview, following, free }

/// SDK-neutral output: no widgets, trip lifecycle or Google Maps dependency.
class DriverCameraPose {
  const DriverCameraPose(
    this.target,
    this.zoom,
    this.bearing,
    this.tilt, {
    this.duration = const Duration(milliseconds: 450),
    this.speedMetersPerSecond = 0,
    this.coast = false,
  });
  final GeoPoint target;
  final double zoom;
  final double bearing;
  final double tilt;
  final Duration duration;

  /// Used only to coast the chase point between GPS fixes. Never the car marker.
  final double speedMetersPerSecond;

  /// On-route driving only. Explore, waiting and off-route stays stay put.
  final bool coast;
}

abstract interface class DriverCameraPort {
  Future<void> animate(DriverCameraPose pose);

  /// Latest GPS while a follow animation is already running. Must not start
  /// a second command; the in-flight animation steers toward this pose.
  void retarget(DriverCameraPose pose);
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
  RouteCameraGeometry? _geometry;
  double _course = 0;
  GeoPoint? vehiclePoint;
  double get vehicleCourse => _course;
  double get alongMeters => _along ?? 0;
  bool autoZoom = true;

  static double zoomForSpeed(double speed) {
    final kmh = speed * 3.6;
    return kmh < 20
        ? 17.5
        : kmh < 50
        ? 16.5
        : kmh < 80
        ? 15.5
        : 14.75;
  }

  static double angleDelta(double from, double to) =>
      (to - from + 540) % 360 - 180;

  DriverCameraPose resolve({
    required DriverLocation location,
    RoadRoute? route,
    bool navigating = false,
    bool waiting = false,
    bool immediate = false,
  }) {
    if (!_samePolyline(route, _route)) {
      _along = null;
      _instructionHint = 0;
      _geometry = route == null || route.points.isEmpty
          ? null
          : RouteCameraGeometry(route.points);
    }
    _route = route;
    _course = location.courseOr(_course);
    vehiclePoint = location.point;
    final rawSpeed = location.speedMetersPerSecond;
    final speed = rawSpeed != null && rawSpeed.isFinite && rawSpeed >= 0
        ? rawSpeed
        : 0.0;
    var bearing = navigating && !waiting ? _course : 0.0;
    var zoom = waiting
        ? 17.2
        : navigating
        ? (autoZoom ? zoomForSpeed(speed) : (_previous?.zoom ?? 16.5))
        : 16.8;
    var tilt = navigating && !waiting ? 45.0 : 0.0;
    var onRoute = false;
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
        onRoute = true;
        final car = _geometry!.at(progress.alongMeters);
        vehiclePoint = car;
        final ahead = _geometry!.at(
          progress.alongMeters + (speed * 3).clamp(40.0, 250.0),
        );
        if (car.distanceMetersTo(ahead) > 1) {
          final roadBearing = car.bearingTo(ahead);
          // On guidance entry aim down the road even if GPS is stationary.
          // While moving, anticipate curves without leading course >30°.
          bearing = immediate
              ? roadBearing
              : speed < 1
              ? (_previous?.bearing ?? roadBearing)
              : (_course +
                        angleDelta(_course, roadBearing).clamp(-30.0, 30.0) *
                            .7 +
                        360) %
                    360;
        }
        final maneuver = progress.nextInstruction;
        final distance = progress.distanceToManeuverMeters;
        if (autoZoom &&
            maneuver != null &&
            _needsPreview(maneuver.type) &&
            distance < 180) {
          final approach = (1 - distance / 180).clamp(0.0, 1.0);
          zoom = math.max(zoom, 17.0 + .8 * approach);
          tilt = 45 - 25 * approach;
        }
        if (progress.remainingMeters < 35) {
          tilt = 0;
          zoom = 17.5;
        }
      }
    }
    // One noisy GPS heading must not spin the map. A sustained turn still
    // catches up; the SDK adapter damps what remains. Entry/recenter is immediate
    // and aims straight down the road.
    if (!immediate && navigating && !waiting && _previous != null) {
      final turn = angleDelta(_previous!.bearing, bearing).clamp(-55.0, 55.0);
      bearing = (_previous!.bearing + turn * 0.65 + 360) % 360;
    }
    return _previous = DriverCameraPose(
      vehiclePoint!,
      zoom,
      bearing,
      tilt,
      duration: Duration(milliseconds: immediate ? 900 : 450),
      speedMetersPerSecond: speed,
      coast: onRoute && speed >= 1,
    );
  }

  bool _samePolyline(RoadRoute? next, RoadRoute? previous) {
    if (identical(next, previous)) {
      return true;
    }
    if (next == null || previous == null) {
      return false;
    }
    final a = next.points;
    final b = previous.points;
    if (a.length != b.length) {
      return false;
    }
    if (a.isEmpty) {
      return true;
    }
    bool same(GeoPoint p, GeoPoint q) =>
        p.latitude == q.latitude && p.longitude == q.longitude;
    for (var i = 0; i < a.length; i++) {
      if (!same(a[i], b[i])) return false;
    }
    return true;
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
  DriverCameraState get state => mode == DriverCameraMode.browsing
      ? DriverCameraState.free
      : mode == DriverCameraMode.overview
      ? DriverCameraState.preview
      : isGuidance
      ? DriverCameraState.following
      : DriverCameraState.explore;
  GeoPoint? get vehiclePoint => _policy.vehiclePoint;
  double get vehicleCourse => _policy.vehicleCourse;
  double get alongMeters => _policy.alongMeters;
  bool get isGuidance => _navigating && !_waiting;
  bool get autoZoom => _policy.autoZoom;
  void setAutoZoom(bool enabled) {
    _policy.autoZoom = enabled;
    _request();
  }

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
    final enteringGuidance = navigating && !_navigating;
    _navigating = navigating;
    _waiting = waiting;
    // Track car/route progress even while the viewport belongs to the driver.
    final pose = _policy.resolve(
      location: location,
      route: route,
      navigating: navigating,
      waiting: waiting,
      immediate: enteringGuidance,
    );
    if (enteringGuidance && mode == DriverCameraMode.overview) {
      _mode = DriverCameraMode.following;
    }
    _request(immediate: enteringGuidance, resolved: pose);
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

  void _request({bool immediate = false, DriverCameraPose? resolved}) {
    final location = _location;
    if (!_canFollow || location == null || !location.isUsableAt(_now())) {
      return;
    }
    _pending =
        resolved ??
        _policy.resolve(
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
    final pending = _pending;
    if (_busy && pending != null) {
      _port?.retarget(pending);
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
    _throttle = Timer(const Duration(milliseconds: 16), () {
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
