import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/navigation/route_progress.dart';
import 'package:movera/core/routing/route_repository.dart';

void main() {
  final route = RoadRoute(
    points: const [GeoPoint(59.3, 18.0), GeoPoint(59.31, 18.01)],
    distanceMeters: 1300,
    durationSeconds: 180,
  );
  final position = const GeoPoint(59.305, 18.005);
  const calculator = RouteProgressCalculator();

  test('NaN persisted progress falls back to global projection', () {
    final expected = calculator.measure(route: route, position: position);
    final actual = calculator.measure(
      route: route, position: position, previousAlongMeters: double.nan,
    );
    expect(actual.alongMeters.isFinite, isTrue);
    expect(actual.alongMeters, closeTo(expected.alongMeters, 0.01));
    expect(actual.offRoute, expected.offRoute);
  });

  test('infinite and negative persisted progress are ignored', () {
    final expected = calculator.measure(route: route, position: position);
    for (final bad in [double.infinity, double.negativeInfinity, -100.0]) {
      final actual = calculator.measure(
        route: route, position: position, previousAlongMeters: bad,
      );
      expect(actual.alongMeters, closeTo(expected.alongMeters, 0.01));
      expect(actual.remainingMeters.isFinite, isTrue);
    }
  });
}
