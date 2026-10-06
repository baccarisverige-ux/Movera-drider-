import 'dart:async';
import 'dart:io';

import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/location/driver_location_repository.dart';
import 'package:movera/core/navigation/driver_camera_controller.dart';
import 'package:movera/core/navigation/route_camera_geometry.dart';
import 'package:movera/core/routing/route_instruction.dart';
import 'package:movera/core/routing/route_repository.dart';

void check(bool value, String label) {
  if (!value) {
    throw StateError(label);
  }
}

class RecordingCamera implements DriverCameraPort {
  final List<DriverCameraPose> commands = [];
  final List<Completer<void>> completions = [];
  int interrupts = 0;
  bool disposed = false;
  int previews = 0;
  @override
  Future<void> animate(DriverCameraPose pose) {
    commands.add(pose);
    final done = Completer<void>();
    completions.add(done);
    return done.future;
  }

  @override
  Future<void> overview(List<GeoPoint> points, double padding) async {
    previews++;
  }

  @override
  void retarget(DriverCameraPose pose) {}

  @override
  void interrupt() {
    interrupts++;
  }

  @override
  void dispose() {
    disposed = true;
  }

  void complete() {
    for (final c in completions) {
      if (!c.isCompleted) {
        c.complete();
      }
    }
  }
}

Future<void> runCameraContractTests() async {
  final now = DateTime.utc(2026, 10, 6);
  DriverLocation fix(GeoPoint point, {double heading = 0, double speed = 10}) =>
      DriverLocation(
        point: point,
        headingDegrees: heading,
        speedMetersPerSecond: speed,
        measuredAt: now,
        accuracyMeters: 5,
      );
  const origin = GeoPoint(59.33, 18.06);
  const turn = GeoPoint(59.334, 18.06);
  const end = GeoPoint(59.334, 18.066);
  RoadRoute route(RouteManeuverType type) => RoadRoute(
    points: const [origin, turn, end],
    distanceMeters: 790,
    durationSeconds: 80,
    instructions: [
      RouteInstruction(
        type: type,
        modifier: 'right',
        text: 'Turn right',
        distanceMeters: 445,
        maneuverLocation: turn,
      ),
      const RouteInstruction(
        type: RouteManeuverType.arrive,
        modifier: '',
        text: 'Arrive',
        distanceMeters: 345,
        maneuverLocation: end,
      ),
    ],
  );
  for (final type in [
    RouteManeuverType.turn,
    RouteManeuverType.roundabout,
    RouteManeuverType.rotary,
    RouteManeuverType.fork,
    RouteManeuverType.offRamp,
  ]) {
    final policy = DriverCameraPolicy();
    final road = route(type);
    final cruise = policy.resolve(
      location: fix(origin),
      route: road,
      navigating: true,
      immediate: true,
    );
    final preview = policy.resolve(
      location: fix(const GeoPoint(59.3327, 18.06)),
      route: road,
      navigating: true,
      immediate: true,
    );
    final close = policy.resolve(
      location: fix(const GeoPoint(59.3339, 18.06)),
      route: road,
      navigating: true,
      immediate: true,
    );
    check(preview.zoom > cruise.zoom, '$type tightens inside 180m');
    check(preview.tilt < cruise.tilt, '$type flattens approaching junction');
    check(close.zoom > cruise.zoom, '$type closes in near maneuver');
    final after = policy.resolve(
      location: fix(const GeoPoint(59.334, 18.061)),
      route: road,
      navigating: true,
      immediate: true,
    );
    check((after.bearing - 90).abs() < 1, 'Follow route direction after turn');
    check(
      after.zoom == 16.5 && after.tilt == 45,
      'Recover speed zoom and driving tilt',
    );
  }
  final policy = DriverCameraPolicy();
  policy.resolve(location: fix(origin, heading: 359), immediate: true);
  final wrapped = policy.resolve(location: fix(origin, heading: 1));
  check(wrapped.bearing == 0, 'Explore is north-up independent of car course');
  check(policy.vehicleCourse == 1, 'Car holds real course in explore');
  policy.resolve(location: fix(origin, heading: 170, speed: .4));
  check(policy.vehicleCourse == 1, 'Stationary car holds last good GPS course');
  check(
    GeoPoint.shortestAngleLerp(359, 1, .5) < 2,
    'Shortest-angle interpolation crosses north without full circle',
  );
  check(DriverCameraPolicy.zoomForSpeed(3) == 17.5, 'Slow-speed zoom');
  check(DriverCameraPolicy.zoomForSpeed(10) == 16.5, 'Urban-speed zoom');
  check(DriverCameraPolicy.zoomForSpeed(20) == 15.5, 'Fast urban zoom');
  check(DriverCameraPolicy.zoomForSpeed(30) == 14.75, 'Highway zoom');
  check(wrapped.tilt == 0, 'Outside trip uses flat location following');
  final waiting = policy.resolve(
    location: fix(origin),
    waiting: true,
    navigating: true,
    immediate: true,
  );
  check(waiting.tilt == 0 && waiting.zoom == 17.2, 'Waiting is calm and close');
  final offRoute = policy.resolve(
    location: fix(const GeoPoint(59.32, 18.08), heading: 210),
    route: route(RouteManeuverType.turn),
    navigating: true,
    immediate: true,
  );
  check(
    offRoute.bearing == 210,
    'Off-route does not force wrong route bearing',
  );
  final smooth = policy.resolve(
    location: fix(origin),
    route: route(RouteManeuverType.turn),
    navigating: true,
  );
  check(
    smooth.duration.inMilliseconds == 450,
    'Time-based four-axis smoothing',
  );

  final curve = DriverCameraPolicy();
  final curvedRoute = route(RouteManeuverType.turn);
  curve.resolve(
    location: fix(origin),
    route: curvedRoute,
    navigating: true,
    immediate: true,
  );
  final anticipating = curve.resolve(
    location: fix(const GeoPoint(59.3338, 18.06), speed: 20),
    route: curvedRoute,
    navigating: true,
  );
  check(
    anticipating.bearing > 0 && anticipating.bearing <= 30,
    'Right bend rotates early with maximum 30 degree course lead',
  );
  check(
    anticipating.duration.inMilliseconds == 450,
    'Driving bearing smooths over 450 milliseconds',
  );
  final snapping = DriverCameraPolicy();
  final snapped = snapping.resolve(
    location: fix(const GeoPoint(59.332, 18.0601)),
    route: curvedRoute,
    navigating: true,
    immediate: true,
  );
  check(
    (snapped.target.longitude - 18.06).abs() < .000001,
    'On-route driver snaps to segment rather than next vertex',
  );
  final geometry = RouteCameraGeometry(curvedRoute.points);
  check(
    geometry.remaining(snapping.alongMeters).first == snapping.vehiclePoint,
    'Remaining stroke starts at snapped car, no thick line behind it',
  );
  final arrival = snapping.resolve(
    location: fix(end, heading: 90),
    route: curvedRoute,
    navigating: true,
    immediate: true,
  );
  check(arrival.tilt == 0, 'Arrival flattens');
  final fast = DriverCameraPolicy();
  fast.resolve(
    location: fix(origin, speed: 30),
    route: curvedRoute,
    navigating: true,
    immediate: true,
  );
  final fastJunction = fast.resolve(
    location: fix(const GeoPoint(59.3335, 18.06), speed: 30),
    route: curvedRoute,
    navigating: true,
  );
  check(
    fastJunction.zoom > 17 && fastJunction.tilt < 45,
    'Highway-speed junction framing does not wait for many GPS samples',
  );

  final camera = DriverCameraController(now: () => now);
  final port = RecordingCamera();
  camera.attach(port);
  check(camera.state == DriverCameraState.explore, 'App opens in explore');
  camera.update(location: fix(origin));
  camera.update(location: fix(turn));
  check(port.commands.length == 1, 'Serialize and coalesce GPS updates');
  camera.userGesture();
  check(
    camera.state == DriverCameraState.free,
    'Touch immediately enters Free',
  );
  camera.update(location: fix(end));
  check(port.commands.length == 1, 'Browsing suppresses follow commands');
  camera.recenter();
  check(
    port.commands.last.target == end,
    'Recenter uses latest GPS, not browse pose',
  );
  port.complete();
  await Future<void>.delayed(Duration.zero);
  check(
    port.commands.length == 2,
    'Old completion cannot replay pending command',
  );
  camera.suspend();
  camera.update(location: fix(turn));
  check(port.commands.length == 2, 'Background suppresses commands');
  camera.resume();
  check(port.commands.last.target == turn, 'Resume follows latest position');
  camera.userGesture();
  camera.suspend();
  camera.resume();
  check(
    camera.mode == DriverCameraMode.browsing,
    'Background retains manual mode',
  );
  await camera.preview([origin, end]);
  check(
    port.previews == 0,
    'Late route overview cannot steal browsed viewport',
  );
  camera.update(
    location: DriverLocation(
      point: origin,
      accuracyMeters: 5,
      measuredAt: now.subtract(const Duration(minutes: 1)),
    ),
  );
  camera.recenter();
  check(port.commands.last.target == turn, 'Reject stale GPS');
  final next = RecordingCamera();
  camera.attach(next);
  check(port.disposed, 'Map replacement releases old port');
  camera.dispose();
  next.complete();
  port.complete();
  await Future<void>.delayed(Duration.zero);
  camera.update(location: fix(origin));
  camera.recenter();
  check(next.disposed, 'Dispose releases camera port');

  final previewCamera = DriverCameraController(now: () => now);
  final previewPort = RecordingCamera();
  previewCamera.attach(previewPort);
  await previewCamera.preview([origin, end]);
  previewCamera.update(location: fix(origin), route: curvedRoute);
  check(
    previewCamera.state == DriverCameraState.preview &&
        previewPort.commands.isEmpty,
    'Destination preview does not follow GPS',
  );
  previewCamera.update(
    location: fix(origin),
    route: curvedRoute,
    navigating: true,
  );
  check(
    previewCamera.state == DriverCameraState.following &&
        previewPort.commands.single.duration.inMilliseconds == 900,
    'Guidance starts with one 900ms camera animation',
  );
  previewCamera.userGesture();
  previewCamera.update(
    location: fix(turn),
    route: route(RouteManeuverType.turn),
    navigating: true,
  );
  check(
    previewCamera.state == DriverCameraState.free,
    'Rerouting preserves manual viewport',
  );
  previewCamera.recenter();
  check(
    previewPort.commands.last.duration.inMilliseconds == 900,
    'Recenter restores guidance in one animation',
  );
  previewCamera.dispose();
  previewPort.complete();
}

Future<void> main() async {
  await runCameraContractTests();
  stdout.writeln(
    'PASS: Driver camera policy, follow/browse, recenter, lifecycle and queue contracts',
  );
}
