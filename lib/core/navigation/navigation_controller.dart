import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/location/driver_location_repository.dart';
import 'package:movera/core/navigation/route_progress.dart';
import 'package:movera/core/ride/active_ride_repository.dart';
import 'package:movera/core/routing/route_instruction.dart';
import 'package:movera/core/routing/route_repository.dart';

class NavigationSnapshot {
  const NavigationSnapshot({
    required this.vehicle,
    required this.headingDegrees,
    required this.followCamera,
    required this.waitingAtPickup,
    this.route,
    this.banner,
    this.status,
    this.offRoute = false,
  });

  final GeoPoint vehicle;
  final double headingDegrees;
  final bool followCamera;
  final bool waitingAtPickup;
  final RoadRoute? route;
  final NavigationBanner? banner;
  final String? status;
  final bool offRoute;

  static const stockholm = GeoPoint(59.3262, 18.0595);
}

/// Owns live route progress, next-maneuver banner and displayed vehicle pose.
///
/// High-frequency GPS must not rebuild the whole trip screen. The ride
/// lifecycle stays in [ActiveRideController]; this controller never pops
/// navigation or completes a trip.
class NavigationController extends ChangeNotifier {
  NavigationController({
    required this.routeRepository,
    this.offRouteThresholdMeters = 50,
  }) : _progress = const RouteProgressCalculator();

  final RouteRepository routeRepository;
  final double offRouteThresholdMeters;
  final RouteProgressCalculator _progress;

  NavigationSnapshot _snapshot = const NavigationSnapshot(
    vehicle: NavigationSnapshot.stockholm,
    headingDegrees: 0,
    followCamera: true,
    waitingAtPickup: false,
  );
  RoadRoute? _route;
  GeoPoint? _destination;
  ActiveRideStage _stage = ActiveRideStage.headingToPickup;
  int _routeRequestToken = 0;
  DateTime? _lastRouteAt;
  GeoPoint? _lastRouteOrigin;
  int _instructionHint = 0;
  bool _userPausedFollow = false;
  String? _status;
  Timer? _rerouteDebounce;

  NavigationSnapshot get snapshot => _snapshot;
  RoadRoute? get route => _route;
  bool get followCamera => !_userPausedFollow;
  String? get status => _status;

  void setStage(ActiveRideStage stage) {
    _stage = stage;
    if (stage == ActiveRideStage.waitingForRider) {
      _status = null;
      _rebuildBanner();
      return;
    }
    _rebuildBanner();
  }

  void pauseFollow() {
    if (_userPausedFollow) return;
    _userPausedFollow = true;
    _rebuildBanner();
  }

  void resumeFollow() {
    _userPausedFollow = false;
    _rebuildBanner();
  }

  void setVehicle(DriverLocation location) {
    final moved = _snapshot.vehicle.distanceMetersTo(location.point);
    if (moved < 0.4 &&
        (location.headingDegrees - _snapshot.headingDegrees).abs() < 1) {
      return;
    }

    final heading = location.point.resolvedHeading(
      gpsHeading: location.headingDegrees,
      previous: _snapshot.vehicle,
      fallback: _snapshot.headingDegrees,
    );

    _snapshot = NavigationSnapshot(
      vehicle: location.point,
      headingDegrees: heading,
      followCamera: !_userPausedFollow,
      waitingAtPickup: _stage == ActiveRideStage.waitingForRider,
      route: _route,
      banner: _snapshot.banner,
      status: _status,
      offRoute: _snapshot.offRoute,
    );
    _rebuildBanner();
  }

  void keepLastKnown({String? status}) {
    _status = status ?? 'Location updating…';
    _rebuildBanner();
  }

  Future<void> ensureRoute({
    required GeoPoint origin,
    required GeoPoint destination,
    bool force = false,
  }) async {
    if (_stage == ActiveRideStage.waitingForRider) return;

    _destination = destination;
    final now = DateTime.now();
    final lastOrigin = _lastRouteOrigin;
    final lastAt = _lastRouteAt;
    if (!force && lastOrigin != null && lastAt != null) {
      final moved = lastOrigin.distanceMetersTo(origin);
      if (moved < 20 && now.difference(lastAt) < const Duration(seconds: 8)) {
        return;
      }
    }

    _lastRouteOrigin = origin;
    _lastRouteAt = now;
    final token = ++_routeRequestToken;
    _status = _route == null ? 'Route updating…' : _status;

    try {
      final route = await routeRepository.drivingRoute(
        origin: origin,
        destination: destination,
      );
      if (token != _routeRequestToken) return;
      _route = route;
      _instructionHint = 0;
      _status = null;
      _rebuildBanner();
    } catch (_) {
      if (token != _routeRequestToken) return;
      _status = 'Route updating…';
      _rebuildBanner();
    }
  }

  void _rebuildBanner() {
    final waiting = _stage == ActiveRideStage.waitingForRider;
    if (waiting) {
      _snapshot = NavigationSnapshot(
        vehicle: _snapshot.vehicle,
        headingDegrees: _snapshot.headingDegrees,
        followCamera: false,
        waitingAtPickup: true,
        route: _route,
        banner: const NavigationBanner(
          primary: 'Pickup',
          distanceLabel: 'Waiting for rider',
          symbol: NavigationBannerSymbol.arrive,
        ),
        status: _status,
      );
      notifyListeners();
      return;
    }

    final route = _route;
    RouteProgress? progress;
    if (route != null && route.geoPoints.length >= 2) {
      progress = _progress.measure(
        route: route,
        position: _snapshot.vehicle,
        instructionHint: _instructionHint,
      );
      _instructionHint = progress.instructionIndex;
    }

    if (progress != null &&
        progress.offRoute &&
        _destination != null &&
        _stage != ActiveRideStage.waitingForRider) {
      _status = 'Recalculating route…';
      _scheduleReroute();
    }

    _snapshot = NavigationSnapshot(
      vehicle: _snapshot.vehicle,
      headingDegrees: _snapshot.headingDegrees,
      followCamera: !_userPausedFollow,
      waitingAtPickup: false,
      route: route,
      banner: _bannerFor(progress),
      status: _status,
      offRoute: progress?.offRoute ?? false,
    );
    notifyListeners();
  }

  NavigationBanner _bannerFor(RouteProgress? progress) {
    final arrivingToPickup = _stage == ActiveRideStage.headingToPickup;
    final instruction = progress?.nextInstruction;
    if (instruction == null) {
      return NavigationBanner(
        primary: arrivingToPickup ? 'Navigate to pickup' : 'Navigate to drop-off',
        distanceLabel: _status ?? 'Route updating…',
        symbol: arrivingToPickup
            ? NavigationBannerSymbol.straight
            : NavigationBannerSymbol.arrive,
        status: _status,
      );
    }

    final meters = progress?.distanceToManeuverMeters ?? instruction.distanceMeters;
    if (instruction.isArrival || meters < 40) {
      if (arrivingToPickup) {
        return NavigationBanner(
          primary: meters < 25 ? 'Pickup ahead' : 'Pickup',
          distanceLabel: 'in ${RouteInstructionCopy.formatDistance(meters)}',
          roadName: instruction.roadName,
          symbol: NavigationBannerSymbol.arrive,
          status: _status,
        );
      }
      return NavigationBanner(
        primary: meters < 25 ? 'Drop-off ahead' : 'Drop-off',
        distanceLabel: 'in ${RouteInstructionCopy.formatDistance(meters)}',
        roadName: instruction.roadName,
        symbol: NavigationBannerSymbol.arrive,
        status: _status,
      );
    }

    return NavigationBanner(
      primary: instruction.text,
      distanceLabel: 'in ${RouteInstructionCopy.formatDistance(meters)}',
      roadName: instruction.roadName,
      symbol: RouteInstructionCopy.symbolFor(
        type: instruction.type,
        modifier: instruction.modifier,
      ),
      status: _status,
    );
  }

  void _scheduleReroute() {
    final destination = _destination;
    if (destination == null) return;
    _rerouteDebounce?.cancel();
    _rerouteDebounce = Timer(const Duration(seconds: 2), () {
      unawaited(
        ensureRoute(
          origin: _snapshot.vehicle,
          destination: destination,
          force: true,
        ),
      );
    });
  }

  @override
  void dispose() {
    _rerouteDebounce?.cancel();
    super.dispose();
  }
}
