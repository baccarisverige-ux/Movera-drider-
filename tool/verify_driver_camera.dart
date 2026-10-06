import 'dart:async';
import 'dart:io';

import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/location/driver_location_repository.dart';
import 'package:movera/core/navigation/driver_camera_controller.dart';
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
  DriverLocation fix(GeoPoint point, {double heading = 0}) => DriverLocation(
    point: point,
    headingDegrees: heading,
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
    check(preview.zoom < cruise.zoom, '$type previews with wider zoom');
    check(close.zoom > cruise.zoom, '$type closes in near maneuver');
    final after = policy.resolve(
      location: fix(const GeoPoint(59.334, 18.061)),
      route: road,
      navigating: true,
      immediate: true,
    );
    check((after.bearing - 90).abs() < 1, 'Follow route direction after turn');
    check(after.zoom == 16.8, 'Recover cruise after maneuver');
  }
  final policy = DriverCameraPolicy();
  policy.resolve(location: fix(origin, heading: 359), immediate: true);
  final wrapped = policy.resolve(location: fix(origin, heading: 1));
  check(wrapped.bearing > 358 || wrapped.bearing < 2, 'Shortest bearing wrap');
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
  check((smooth.zoom - offRoute.zoom).abs() <= .25, 'Bound zoom changes');

  final camera = DriverCameraController(now: () => now);
  final port = RecordingCamera();
  camera.attach(port);
  camera.update(location: fix(origin));
  camera.update(location: fix(turn));
  check(port.commands.length == 1, 'Serialize and coalesce GPS updates');
  camera.userGesture();
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
}

Future<void> main() async {
  await runCameraContractTests();
  stdout.writeln(
    'PASS: Driver camera policy, follow/browse, recenter, lifecycle and queue contracts',
  );
}
