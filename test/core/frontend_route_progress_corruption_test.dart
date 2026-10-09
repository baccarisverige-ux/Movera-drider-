import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/navigation/route_progress.dart';
import 'package:movera/core/routing/route_repository.dart';

void main() {
  final route = RoadRoute(
    // Two passes within GPS tolerance; an invalid hint must not bias the
    // vehicle onto the earlier pass instead of the closer return leg.
    points: const [
      GeoPoint(59, 18),
      GeoPoint(59, 18.01),
      GeoPoint(59.00005, 18.01),
      GeoPoint(59.00005, 18),
    ],
    distanceMeters: 1300,
    durationSeconds: 180,
  );
  const position = GeoPoint(59.00005, 18.005);
  const calculator = RouteProgressCalculator();

  test('R24 NaN progress hint falls back to global projection', () {
    final expected = calculator.measure(route: route, position: position);
    final actual = calculator.measure(
      route: route,
      position: position,
      previousAlongMeters: double.nan,
    );
    expect(actual.alongMeters.isFinite, isTrue);
    expect(actual.alongMeters, closeTo(expected.alongMeters, 0.01));
    expect(actual.offRoute, expected.offRoute);
  });

  test('R24 infinite and negative progress hints are ignored', () {
    final expected = calculator.measure(route: route, position: position);
    for (final bad in [double.infinity, double.negativeInfinity, -100.0]) {
      final actual = calculator.measure(
        route: route,
        position: position,
        previousAlongMeters: bad,
      );
      expect(actual.alongMeters, closeTo(expected.alongMeters, 0.01));
      expect(actual.remainingMeters.isFinite, isTrue);
    }
  });
}
