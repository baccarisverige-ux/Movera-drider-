import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/location/driver_location_repository.dart';
import 'package:movera/core/navigation/navigation_controller.dart';
import 'package:movera/core/navigation/route_progress.dart';
import 'package:movera/core/ride/active_ride_repository.dart';
import 'package:movera/core/routing/osrm_route_parser.dart';
import 'package:movera/core/routing/route_instruction.dart';
import 'package:movera/core/routing/route_repository.dart';
import 'package:movera/presentation/driver/overlays/map_overlay_insets.dart';
import 'package:movera/widgets/movera_sheet_metrics.dart';

void main() {
  test('shortest heading interpolation never spins the long way', () {
    expect(GeoPoint.shortestAngleLerp(10, 350, 1), closeTo(350, 0.001));
    expect(GeoPoint.shortestAngleLerp(350, 10, 1), closeTo(10, 0.001));
    expect(GeoPoint.shortestAngleLerp(0, 180, 0.5), closeTo(90, 0.5));
  });

  test('OSRM parser maps steps into domain instructions', () {
    const parser = OsrmRouteParser();
    final route = parser.parseRoute(<String, dynamic>{
      'distance': 420.0,
      'duration': 96.0,
      'geometry': <String, dynamic>{
        'coordinates': <List<double>>[
          <double>[18.0615, 59.3279],
          <double>[18.0630, 59.3290],
          <double>[18.0649, 59.3326],
        ],
      },
      'legs': <Map<String, dynamic>>[
        <String, dynamic>{
          'steps': <Map<String, dynamic>>[
            <String, dynamic>{
              'name': 'Sveavägen',
              'distance': 300.0,
              'maneuver': <String, dynamic>{
                'type': 'turn',
                'modifier': 'left',
                'location': <double>[18.0630, 59.3290],
              },
            },
            <String, dynamic>{
              'name': '',
              'distance': 120.0,
              'maneuver': <String, dynamic>{
                'type': 'roundabout',
                'modifier': '',
                'exit': 2,
                'location': <double>[18.0649, 59.3326],
              },
            },
          ],
        },
      ],
    });

    expect(route.points, hasLength(3));
    expect(route.instructions, hasLength(2));
    expect(route.instructions.first.text, 'Turn left onto Sveavägen');
    expect(route.instructions.first.type, RouteManeuverType.turn);
    expect(
      route.instructions.last.text,
      'At roundabout, take exit 2',
    );
  });

  test('route progress advances to the next maneuver after it is passed', () {
    const calculator = RouteProgressCalculator();
    final route = RoadRoute(
      points: const [
        LatLng(59.3279, 18.0615),
        LatLng(59.3290, 18.0630),
        LatLng(59.3326, 18.0649),
      ],
      distanceMeters: 420,
      durationSeconds: 90,
      instructions: const [
        RouteInstruction(
          type: RouteManeuverType.turn,
          modifier: 'left',
          text: 'Turn left',
          distanceMeters: 80,
          maneuverLocation: GeoPoint(59.3290, 18.0630),
          roadName: 'Sveavägen',
        ),
        RouteInstruction(
          type: RouteManeuverType.arrive,
          modifier: '',
          text: 'Arrive at destination',
          distanceMeters: 200,
          maneuverLocation: GeoPoint(59.3326, 18.0649),
        ),
      ],
    );

    final before = calculator.measure(
      route: route,
      position: const GeoPoint(59.32795, 18.0616),
    );
    expect(before.nextInstruction?.type, RouteManeuverType.turn);
    expect(before.offRoute, isFalse);

    final after = calculator.measure(
      route: route,
      position: const GeoPoint(59.3318, 18.0644),
      instructionHint: 0,
    );
    expect(after.nextInstruction?.type, RouteManeuverType.arrive);
  });

  test('navigation keeps the trip and last banner when routing fails', () async {
    final navigation = NavigationController(
      routeRepository: _FailingRouteRepository(),
    );
    navigation.setVehicle(
      const DriverLocation(
        point: GeoPoint(59.3279, 18.0615),
        headingDegrees: 12,
      ),
    );
    await navigation.ensureRoute(
      origin: const GeoPoint(59.3279, 18.0615),
      destination: const GeoPoint(59.3326, 18.0649),
      force: true,
    );

    expect(navigation.route, isNull);
    expect(navigation.snapshot.status, 'Route updating…');
    expect(navigation.snapshot.banner, isNotNull);
  });

  test('waiting stage replaces turn-by-turn copy', () {
    final navigation = NavigationController(
      routeRepository: _FailingRouteRepository(),
    );
    navigation.setStage(ActiveRideStage.waitingForRider);
    expect(navigation.snapshot.banner?.primary, 'Pickup');
    expect(navigation.snapshot.banner?.distanceLabel, 'Waiting for rider');
    expect(navigation.snapshot.waitingAtPickup, isTrue);
  });

  test('home sheet snaps choose next stop from flick velocity', () {
    const snap = 0.42;
    expect(
      MoveraSheetMetrics.targetPosition(
        position: 0.10,
        velocityPxPerSec: -400,
        snap: snap,
      ),
      snap,
    );
    expect(
      MoveraSheetMetrics.targetPosition(
        position: 0.50,
        velocityPxPerSec: -400,
        snap: snap,
      ),
      1.0,
    );
    expect(
      MoveraSheetMetrics.targetPosition(
        position: 0.80,
        velocityPxPerSec: 400,
        snap: snap,
      ),
      snap,
    );
    expect(
      MoveraSheetMetrics.targetPosition(
        position: 0.12,
        velocityPxPerSec: 10,
        snap: snap,
      ),
      0,
    );
  });

  test('sheet spring and collapsed heights match the overlay contract', () {
    expect(MoveraSheetMetrics.collapsedHeight, 108);
    expect(MoveraSheetMetrics.activeCollapsedHeight, 148);
    expect(MoveraSheetMetrics.middleFraction, 0.46);
    expect(MoveraSheetMetrics.expandedFraction, 0.90);
    expect(MoveraSheetMetrics.springMass, 1.0);
    expect(MoveraSheetMetrics.springStiffness, 320);
    expect(MoveraSheetMetrics.springDamping, 32);
  });

  test('map overlay insets keep fitted routes in the visible map', () {
    final home = MapOverlayInsets.forHome(
      safeTop: 47,
      obscuredBottom: 188,
      hasTopBanner: true,
    );
    expect(home.top, 47 + 68);
    expect(home.bottom, 188 + 18);
    expect(home.boundsPadding, inInclusiveRange(36, 72));

    final ride = MapOverlayInsets.forActiveRide(safeTop: 47);
    expect(ride.top, 47 + 76);
    expect(ride.bottom, MoveraSheetMetrics.activeCollapsedHeight + 10);
    expect(ride.boundsPadding, inInclusiveRange(36, 72));
  });
}

class _FailingRouteRepository implements RouteRepository {
  @override
  Future<RoadRoute> drivingRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  }) async {
    throw Exception('offline');
  }
}
