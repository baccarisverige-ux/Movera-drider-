import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/location/driver_location_repository.dart';
import 'package:movera/core/navigation/driver_camera_controller.dart';
import 'package:movera/core/navigation/navigation_controller.dart';
import 'package:movera/core/routing/route_repository.dart';

class DelayedRoutes implements RouteRepository {
  final destinations = <GeoPoint>[];
  final responses = <Completer<RoadRoute>>[];
  @override
  Future<RoadRoute> drivingRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  }) {
    destinations.add(destination);
    final response = Completer<RoadRoute>();
    responses.add(response);
    return response.future;
  }
}

RoadRoute road(GeoPoint destination) => RoadRoute(
  points: [const GeoPoint(59.3, 18), destination],
  distanceMeters: 1000,
  durationSeconds: 100,
);
void main() {
  const origin = GeoPoint(59.3, 18);
  const a = GeoPoint(59.31, 18);
  const b = GeoPoint(59.32, 18);
  test(
    '008 stationary destination change requests B and rejects late A',
    () async {
      final repo = DelayedRoutes();
      final nav = NavigationController(routeRepository: repo);
      addTearDown(nav.dispose);
      nav.setVehicle(const DriverLocation(point: origin));
      final requestA = nav.ensureRoute(origin: origin, destination: a);
      final requestB = nav.ensureRoute(origin: origin, destination: b);
      expect(repo.destinations, [a, b]);
      final routeB = road(b);
      repo.responses[1].complete(routeB);
      await requestB;
      repo.responses[0].complete(road(a));
      await requestA;
      expect(nav.route, same(routeB));
      await nav.ensureRoute(origin: origin, destination: b);
      expect(repo.destinations, hasLength(2));
    },
  );
  test(
    '010 failed reroute drops stale guidance and stationary retry recovers',
    () async {
      final repo = DelayedRoutes();
      final nav = NavigationController(routeRepository: repo);
      addTearDown(nav.dispose);
      nav.setVehicle(const DriverLocation(point: origin));
      final first = nav.ensureRoute(origin: origin, destination: a);
      repo.responses[0].complete(road(a));
      await first;
      final changed = nav.ensureRoute(origin: origin, destination: b);
      expect(nav.snapshot.route, isNull);
      expect(nav.routeState, RouteLoadState.loading);
      repo.responses[1].completeError(TimeoutException('offline'));
      await changed;
      expect(nav.routeState, RouteLoadState.failed);
      expect(nav.snapshot.status, contains('unavailable'));
      expect(nav.snapshot.route, isNull);
      final retry = nav.retryRoute();
      expect(repo.destinations.last, b);
      repo.responses.last.complete(road(b));
      await retry;
      expect(nav.routeState, RouteLoadState.ready);
      expect(nav.status, isNull);
    },
  );
  test('009 an interior-only reroute replaces camera geometry', () {
    const points = [
      GeoPoint(59.3, 18),
      GeoPoint(59.301, 18),
      GeoPoint(59.302, 18),
      GeoPoint(59.303, 18),
      GeoPoint(59.304, 18),
    ];
    final changed = [...points]..[1] = const GeoPoint(59.301, 18.001);
    final old = RoadRoute(
      points: points,
      distanceMeters: 500,
      durationSeconds: 50,
    );
    final reroute = RoadRoute(
      points: changed,
      distanceMeters: 600,
      durationSeconds: 60,
    );
    final location = DriverLocation(
      point: changed[1],
      measuredAt: DateTime.now(),
      headingDegrees: 0,
    );
    final policy = DriverCameraPolicy();
    policy.resolve(location: location, route: old, navigating: true);
    policy.resolve(location: location, route: reroute, navigating: true);
    final fresh = DriverCameraPolicy();
    fresh.resolve(location: location, route: reroute, navigating: true);
    expect(
      policy.vehiclePoint!.distanceMetersTo(fresh.vehiclePoint!),
      lessThan(0.1),
    );
    expect(policy.alongMeters, closeTo(fresh.alongMeters, 0.1));
  });
}
