import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/location/driver_location_repository.dart';
import 'package:movera/core/navigation/route_progress.dart';
import 'package:movera/core/ride/active_ride_repository.dart';
import 'package:movera/core/routing/route_instruction.dart';
import 'package:movera/core/routing/route_repository.dart';

enum RouteLoadState { idle, loading, ready, failed }

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
  }) : _progress = RouteProgressCalculator(
         offRouteThresholdMeters: offRouteThresholdMeters,
       );

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
  double? _progressAlong;
  bool _userPausedFollow = false;
  String? _status;
  Timer? _rerouteDebounce;
  bool _disposed = false;
  bool _routeInFlight = false;
  String? _targetLabel;
  ActiveRideStage? _lastRouteStage;
  RouteLoadState _routeState = RouteLoadState.idle;
  RouteLoadState get routeState => _routeState;

  Future<void> retryRoute() async {
    final destination = _destination;
    if (destination == null || _disposed || _routeInFlight) return;
    await ensureRoute(
      origin: _snapshot.vehicle,
      destination: destination,
      force: true,
      targetLabel: _targetLabel,
    );
  }

  NavigationSnapshot get snapshot => _snapshot;
  RoadRoute? get route => _route;

  /// Share of the current route already driven, 0..1; null without one.
  double? get routeFraction {
    final route = _route;
    if (route == null || route.distanceMeters <= 0) {
      return null;
    }
    return ((_progressAlong ?? 0) / route.distanceMeters).clamp(0.0, 1.0);
  }

  bool get followCamera => !_userPausedFollow;
  String? get status => _status;

  void setStage(ActiveRideStage stage) {
    if (_stage != stage) {
      _routeRequestToken++;
      _routeInFlight = false;
      _rerouteDebounce?.cancel();
      _rerouteDebounce = null;
      _route = null;
      _routeState = RouteLoadState.idle;
      _instructionHint = 0;
      _progressAlong = null;
    }
    _stage = stage;
    if (stage == ActiveRideStage.waitingForRider) {
      _status = null;
      _rebuildBanner();
      return;
    }
    _rebuildBanner();
  }

  void pauseFollow() {
    if (_userPausedFollow) {
      return;
    }
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

    final heading = location.courseOr(_snapshot.headingDegrees);

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
    String? targetLabel,
  }) async {
    if (_disposed) {
      return;
    }
    _targetLabel = targetLabel;
    if (_stage == ActiveRideStage.waitingForRider) {
      return;
    }

    final previousDestination = _destination;
    final sameDestination =
        previousDestination != null &&
        previousDestination.latitude == destination.latitude &&
        previousDestination.longitude == destination.longitude &&
        _lastRouteStage == _stage;
    _destination = destination;
    final now = DateTime.now();
    final lastOrigin = _lastRouteOrigin;
    final lastAt = _lastRouteAt;
    if (!force &&
        sameDestination &&
        _routeState != RouteLoadState.failed &&
        lastOrigin != null &&
        lastAt != null) {
      final moved = lastOrigin.distanceMetersTo(origin);
      if (moved < 20 && now.difference(lastAt) < const Duration(seconds: 8)) {
        return;
      }
    }

    _rerouteDebounce?.cancel();
    _rerouteDebounce = null;
    _lastRouteStage = _stage;
    _lastRouteOrigin = origin;
    _lastRouteAt = now;
    final token = ++_routeRequestToken;
    _routeInFlight = true;
    _routeState = RouteLoadState.loading;
    _route = null;
    _instructionHint = 0;
    _progressAlong = null;
    _status = 'Route updating…';
    _rebuildBanner();

    try {
      final route = await routeRepository.drivingRoute(
        origin: origin,
        destination: destination,
      );
      if (_disposed || token != _routeRequestToken) {
        return;
      }
      if (route.points.length < 2 ||
          !route.distanceMeters.isFinite ||
          !route.durationSeconds.isFinite ||
          route.distanceMeters < 0 ||
          route.durationSeconds < 0) {
        throw const FormatException('Invalid route');
      }
      _routeState = RouteLoadState.ready;
      _route = route;
      _instructionHint = 0;
      _progressAlong = null;
      _status = null;
      _rebuildBanner();
    } catch (_) {
      if (_disposed || token != _routeRequestToken) {
        return;
      }
      _routeState = RouteLoadState.failed;
      _route = null;
      _status = 'Route unavailable — retry';
      _rebuildBanner();
    } finally {
      if (token == _routeRequestToken) {
        _routeInFlight = false;
      }
    }
  }

  void _rebuildBanner() {
    if (_disposed) {
      return;
    }
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
        previousAlongMeters: _progressAlong,
      );
      _instructionHint = progress.instructionIndex;
      _progressAlong = progress.offRoute ? null : progress.alongMeters;
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
        primary: arrivingToPickup
            ? 'Navigate to pickup'
            : 'Navigate to ${_targetLabel ?? 'drop-off'}',
        distanceLabel: _status ?? 'Route updating…',
        symbol: arrivingToPickup
            ? NavigationBannerSymbol.straight
            : NavigationBannerSymbol.arrive,
        status: _status,
      );
    }

    final meters =
        progress?.distanceToManeuverMeters ?? instruction.distanceMeters;
    if (instruction.isArrival) {
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
        primary: _targetLabel != null
            ? '${_targetLabel!}${meters < 25 ? ' ahead' : ''}'
            : (meters < 25 ? 'Drop-off ahead' : 'Drop-off'),
        distanceLabel: 'in ${RouteInstructionCopy.formatDistance(meters)}',
        roadName: instruction.roadName,
        symbol: NavigationBannerSymbol.arrive,
        status: _status,
      );
    }

    final action = RouteInstructionCopy.shortAction(
      type: instruction.type,
      modifier: instruction.modifier,
      exitNumber: instruction.exitNumber,
    );
    return NavigationBanner(
      primary: RouteInstructionCopy.livePrimary(action: action, meters: meters),
      distanceLabel: RouteInstructionCopy.formatDistance(meters),
      roadName: instruction.roadName,
      exitNumber: instruction.exitNumber,
      exitAngleDegrees: instruction.exitAngleDegrees,
      symbol: RouteInstructionCopy.symbolFor(
        type: instruction.type,
        modifier: instruction.modifier,
      ),
      status: _status,
    );
  }

  void _scheduleReroute() {
    final destination = _destination;
    if (_disposed ||
        destination == null ||
        _rerouteDebounce != null ||
        _routeInFlight) {
      return;
    }
    _rerouteDebounce = Timer(const Duration(seconds: 2), () {
      _rerouteDebounce = null;
      if (_disposed) {
        return;
      }
      unawaited(
        ensureRoute(
          origin: _snapshot.vehicle,
          destination: destination,
          force: true,
          targetLabel: _targetLabel,
        ),
      );
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _routeRequestToken++;
    _rerouteDebounce?.cancel();
    super.dispose();
  }
}
