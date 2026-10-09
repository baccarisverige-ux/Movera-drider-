import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/location/driver_location_repository.dart';
import 'package:movera/core/navigation/navigation_controller.dart';
import 'package:movera/core/routing/route_repository.dart';

const _origin = GeoPoint(59.3, 18);
const _destination = GeoPoint(59.31, 18);

class _Routes implements RouteRepository {
  final responses = <Completer<RoadRoute>>[];

  @override
  Future<RoadRoute> drivingRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  }) {
    final response = Completer<RoadRoute>();
    responses.add(response);
    return response.future;
  }
}

DriverLocation _fix(GeoPoint point) =>
    DriverLocation(point: point, measuredAt: DateTime.now(), accuracyMeters: 5);

RoadRoute _road() => RoadRoute(
  points: const [_origin, _destination],
  distanceMeters: 1000,
  durationSeconds: 100,
);

void main() {
  for (final fail in [false, true]) {
    test(
      'route ${fail ? 'failure' : 'success'} cannot clear an unresolved GPS warning',
      () async {
        final routes = _Routes();
        final navigation = NavigationController(routeRepository: routes);
        addTearDown(navigation.dispose);
        navigation.setVehicle(_fix(_origin));
        final request = navigation.ensureRoute(
          origin: _origin,
          destination: _destination,
        );
        navigation.keepLastKnown();
        if (fail) {
          routes.responses.single.completeError(
            StateError('Route unavailable'),
          );
        } else {
          routes.responses.single.complete(_road());
        }
        await request;
        expect(navigation.status, 'Location updating…');
        expect(navigation.snapshot.status, 'Location updating…');
        expect(navigation.snapshot.banner?.status, 'Location updating…');
        navigation.setVehicle(_fix(_origin));
        expect(
          navigation.routeState,
          fail ? RouteLoadState.failed : RouteLoadState.ready,
        );
        expect(navigation.status, fail ? 'Route unavailable — retry' : isNull);
        expect(routes.responses, hasLength(1));
      },
    );
  }

  for (final point in [_origin, const GeoPoint(59.3001, 18)]) {
    test(
      'GPS recovery at $point restores failed route feedback until Retry',
      () async {
        final routes = _Routes();
        final navigation = NavigationController(routeRepository: routes);
        addTearDown(navigation.dispose);
        navigation.setVehicle(_fix(_origin));
        final first = navigation.ensureRoute(
          origin: _origin,
          destination: _destination,
        );
        routes.responses.single.completeError(StateError('Route unavailable'));
        await first;
        expect(navigation.routeState, RouteLoadState.failed);
        navigation.keepLastKnown();
        expect(navigation.status, 'Location updating…');
        navigation.setVehicle(_fix(point));
        expect(navigation.routeState, RouteLoadState.failed);
        expect(navigation.status, 'Route unavailable — retry');
        expect(navigation.snapshot.status, 'Route unavailable — retry');
        expect(navigation.snapshot.banner?.status, 'Route unavailable — retry');
        expect(
          navigation.snapshot.banner?.distanceLabel,
          'Route unavailable — retry',
        );
        expect(navigation.route, isNull);
        expect(routes.responses, hasLength(1));

        final retry = navigation.retryRoute();
        expect(routes.responses, hasLength(2));
        routes.responses.last.complete(_road());
        await retry;
        expect(navigation.routeState, RouteLoadState.ready);
        expect(navigation.status, isNull);
        expect(navigation.snapshot.status, isNull);
        expect(navigation.route, isNotNull);
      },
    );
  }

  test(
    'GPS recovery restores pending route feedback without another request',
    () async {
      final routes = _Routes();
      final navigation = NavigationController(routeRepository: routes);
      addTearDown(navigation.dispose);
      navigation.setVehicle(_fix(_origin));
      final request = navigation.ensureRoute(
        origin: _origin,
        destination: _destination,
      );
      navigation.keepLastKnown();
      navigation.setVehicle(_fix(_origin));
      expect(navigation.routeState, RouteLoadState.loading);
      expect(navigation.status, 'Route updating…');
      expect(navigation.snapshot.banner?.status, 'Route updating…');
      expect(routes.responses, hasLength(1));
      routes.responses.single.complete(_road());
      await request;
      expect(navigation.routeState, RouteLoadState.ready);
      expect(navigation.status, isNull);
      expect(navigation.snapshot.banner?.status, isNull);
    },
  );
}
