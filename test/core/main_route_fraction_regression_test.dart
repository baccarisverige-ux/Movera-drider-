import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/location/driver_location_repository.dart';
import 'package:movera/core/navigation/navigation_controller.dart';
import 'package:movera/core/routing/route_repository.dart';

class _MismatchedRoute implements RouteRepository {
  @override
  Future<RoadRoute> drivingRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  }) async => const RoadRoute(
    points: [GeoPoint(59.3, 18.0), GeoPoint(59.31, 18.0)],
    distanceMeters: 3000,
    durationSeconds: 180,
  );
}

void main() {
  test('fraction tracks geometry instead of mismatched provider distance', () async {
    final navigation = NavigationController(routeRepository: _MismatchedRoute());
    addTearDown(navigation.dispose);
    const origin = GeoPoint(59.3, 18.0);
    const end = GeoPoint(59.31, 18.0);
    navigation.setVehicle(const DriverLocation(point: origin));
    await navigation.ensureRoute(origin: origin, destination: end, force: true);
    navigation.setVehicle(const DriverLocation(point: GeoPoint(59.305, 18.0)));
    expect(navigation.routeFraction, closeTo(0.5, 0.015));
    navigation.setVehicle(const DriverLocation(point: end));
    expect(navigation.routeFraction, closeTo(1, 0.001));
  });
}
