import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/core/location/driver_location_service.dart';
import 'package:movera/core/routing/road_route_service.dart';
import 'package:movera/core/waybill/waybill.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/presentation/common/chat/chat.dart';
import 'package:movera/presentation/driver/ride%20completed/ride_completed.dart';
import 'package:movera/presentation/driver/safety%20toolkits/safety_toolkits.dart';
import 'package:movera/presentation/driver/waybill/waybill_sheet.dart';
import 'package:movera/widgets/custom_google_map.dart';
import 'package:movera/widgets/navigation_transition.dart';

class AcceptRide extends StatefulWidget {
  const AcceptRide({
    super.key,
    this.offerId = 'demo-radar-offer',
    this.riderName = 'Angelica',
    this.riderRating = 4.9,
    this.riderTrips = 312,
    this.fare = '—',
    this.category = 'Movera',
    this.matchedVia = 'Movera Radar',
    this.pickupAddress = 'Odlarvägen 22',
    this.pickupArea = 'Enhörna',
    this.dropoffAddress = 'T-Centralen, Stockholm',
    this.pickupPosition = const LatLng(59.3279, 18.0615),
    this.dropoffPosition = const LatLng(59.3326, 18.0649),
  });

  final String offerId;
  final String riderName;
  final double riderRating;
  final int riderTrips;
  final String fare;
  final String category;
  final String matchedVia;
  final String pickupAddress;
  final String pickupArea;
  final String dropoffAddress;
  final LatLng pickupPosition;
  final LatLng dropoffPosition;

  @override
  State<AcceptRide> createState() => _AcceptRideState();
}

enum _RideStage { headingToPickup, waitingForRider, onTrip }

enum _OnTripRadarState { off, scanning, offerAvailable, matching, secured }

class _NextTripRadarOffer {
  const _NextTripRadarOffer({
    required this.id,
    required this.category,
    required this.fare,
    required this.rating,
    required this.pickupMinutes,
    required this.tripMinutes,
    required this.riderName,
    required this.pickup,
    required this.dropoff,
  });

  final String id;
  final String category;
  final String fare;
  final double rating;
  final int pickupMinutes;
  final int tripMinutes;
  final String riderName;
  final String pickup;
  final String dropoff;
}

class _TripCancellationReason {
  const _TripCancellationReason({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String code;
  final String title;
  final String subtitle;
  final IconData icon;
}

class _AcceptRideState extends State<AcceptRide> {
  static const Color _ink = Color(0xFF252E3A);
  static const Color _panel = Color(0xFFFFFFFF);
  static const Color _panel2 = Color(0xFFF1F5F3);
  static const Color _canvas = Color(0xFFF4F6F7);
  static const Color _muted = Color(0xFF7D898F);
  static const Color _green = Color(0xFF19865C);
  static const Color _mint = Color(0xFFE6F5EE);
  static const Color _line = Color(0xFFE5E9EB);
  static const Color _danger = Color(0xFFE75D65);

  static const List<_TripCancellationReason> _preTripCancellationReasons = [
    _TripCancellationReason(
      code: 'rider_requested_cancel',
      title: 'Rider requested cancellation',
      subtitle: 'The rider asked not to continue with this pickup',
      icon: Icons.person_off_outlined,
    ),
    _TripCancellationReason(
      code: 'rider_not_at_pickup',
      title: 'Rider not at pickup',
      subtitle: 'You arrived but could not find or reach the rider',
      icon: Icons.location_off_outlined,
    ),
    _TripCancellationReason(
      code: 'unsafe_pickup',
      title: 'Pickup is unsafe or inaccessible',
      subtitle: 'You cannot stop or complete the pickup safely',
      icon: Icons.warning_amber_rounded,
    ),
    _TripCancellationReason(
      code: 'vehicle_issue_before_start',
      title: 'Vehicle problem',
      subtitle: 'A vehicle issue prevents the trip from starting',
      icon: Icons.car_repair_outlined,
    ),
    _TripCancellationReason(
      code: 'driver_emergency_before_start',
      title: 'Personal emergency',
      subtitle: 'An urgent situation prevents you from continuing',
      icon: Icons.emergency_outlined,
    ),
    _TripCancellationReason(
      code: 'other_before_start',
      title: 'Other reason',
      subtitle: 'Another issue prevents this pickup',
      icon: Icons.more_horiz_rounded,
    ),
  ];

  static const List<_TripCancellationReason> _onTripCancellationReasons = [
    _TripCancellationReason(
      code: 'rider_requested_early_end',
      title: 'Rider asked to end the trip',
      subtitle: 'The rider wants to leave before the destination',
      icon: Icons.person_outline_rounded,
    ),
    _TripCancellationReason(
      code: 'safety_concern_on_trip',
      title: 'Safety concern',
      subtitle: 'Continuing the trip may be unsafe',
      icon: Icons.shield_outlined,
    ),
    _TripCancellationReason(
      code: 'vehicle_issue_on_trip',
      title: 'Vehicle problem',
      subtitle: 'A vehicle issue makes it unsafe to continue',
      icon: Icons.car_repair_outlined,
    ),
    _TripCancellationReason(
      code: 'accident_or_road_emergency',
      title: 'Accident or road emergency',
      subtitle: 'An incident or emergency prevents continuing',
      icon: Icons.report_gmailerrorred_rounded,
    ),
    _TripCancellationReason(
      code: 'rider_behavior',
      title: 'Rider behavior',
      subtitle: 'The rider’s behavior requires the trip to end',
      icon: Icons.record_voice_over_outlined,
    ),
    _TripCancellationReason(
      code: 'trip_or_destination_issue',
      title: 'Trip or destination issue',
      subtitle: 'A trip detail or destination problem prevents continuing',
      icon: Icons.alt_route_rounded,
    ),
    _TripCancellationReason(
      code: 'other_on_trip',
      title: 'Other reason',
      subtitle: 'Another issue requires the trip to end early',
      icon: Icons.more_horiz_rounded,
    ),
  ];

  static const LatLng _fallbackDriverPosition = LatLng(59.3262, 18.0595);

  static const _NextTripRadarOffer _demoNextTripOffer =
      _NextTripRadarOffer(
    id: 'on-trip-radar-demo-1',
    category: 'Comfort',
    fare: '128,40 kr',
    rating: 4.94,
    pickupMinutes: 4,
    tripMinutes: 16,
    riderName: 'Maya',
    pickup: 'Vasagatan 10, Stockholm',
    dropoff: 'Södermalm, Stockholm',
  );



  final DriverLocationService _locationService =
      const DriverLocationService();
  final RoadRouteService _routeService = RoadRouteService();

  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSubscription;
  _RideStage _stage = _RideStage.headingToPickup;
  Timer? _waitTimer;
  Timer? _nextTripRadarDemoTimer;
  Timer? _nextTripRadarMatchTimer;
  int _waitSeconds = 0;
  _OnTripRadarState _onTripRadarState = _OnTripRadarState.off;
  _NextTripRadarOffer? _nextTripRadarOffer;

  LatLng _driverPosition = _fallbackDriverPosition;
  List<LatLng> _roadRoutePoints = <LatLng>[];
  double? _routeDistanceMeters;
  double? _routeDurationSeconds;
  LatLng? _lastRouteOrigin;
  DateTime? _lastRouteAt;
  bool _hasLiveLocation = false;
  bool _routeLoading = false;
  bool _stageTransitioning = false;
  int _routeRequestToken = 0;
  String? _locationStatus;

  @override
  void initState() {
    super.initState();
    WaybillStore.beginCurrent(_buildCurrentWaybill());
    _startLiveLocation();
  }

  @override
  void dispose() {
    _waitTimer?.cancel();
    _nextTripRadarDemoTimer?.cancel();
    _nextTripRadarMatchTimer?.cancel();
    _positionSubscription?.cancel();
    _mapController = null;
    super.dispose();
  }

  WaybillRecord _buildCurrentWaybill() {
    return WaybillRecord(
      tripId: widget.offerId,
      statusLabel: 'Current trip',
      issuedAt: DateTime.now(),
      fare: widget.fare,
      service: widget.category,
      riderName: widget.riderName,
      pickup: widget.pickupAddress,
      dropoff: widget.dropoffAddress,
      source: widget.matchedVia,
      driverName: 'Movera Driver',
      vehicle: 'Movera partner vehicle',
      licensePlate: 'MVR 418',
      passengerCapacity: 4,
    );
  }

  WaybillRecord _buildNextWaybill(_NextTripRadarOffer offer) {
    return WaybillRecord(
      tripId: offer.id,
      statusLabel: 'Next trip secured',
      issuedAt: DateTime.now(),
      fare: offer.fare,
      service: offer.category,
      riderName: offer.riderName,
      pickup: offer.pickup,
      dropoff: offer.dropoff,
      source: 'Movera Radar',
      driverName: 'Movera Driver',
      vehicle: 'Movera partner vehicle',
      licensePlate: 'MVR 418',
      passengerCapacity: 4,
    );
  }

  LatLng get _routeTarget =>
      _stage == _RideStage.onTrip
          ? widget.dropoffPosition
          : widget.pickupPosition;

  List<LatLng> get _routePoints => _roadRoutePoints;

  Set<Marker> get _markers {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('driver'),
        position: _driverPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You'),
      ),
    };

    if (_stage != _RideStage.onTrip) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: widget.pickupPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: widget.pickupAddress),
        ),
      );
    } else {
      markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: widget.dropoffPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: widget.dropoffAddress),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> get _polylines {
    if (_roadRoutePoints.length < 2) return <Polyline>{};

    return {
      Polyline(
        polylineId: const PolylineId('active-road-route'),
        points: _roadRoutePoints,
        width: 6,
        color: _green,
        geodesic: false,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  Future<void> _startLiveLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;

      await _applyDriverPosition(position, forceRoute: true);

      _positionSubscription?.cancel();
      _positionSubscription = _locationService
          .watchPosition(distanceFilterMeters: 8)
          .listen(
        (position) {
          _applyDriverPosition(position);
        },
        onError: (Object error) {
          if (!mounted) return;
          setState(() {
            _locationStatus = 'Live location interrupted';
          });
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasLiveLocation = false;
        _locationStatus = 'Location unavailable';
        _roadRoutePoints = <LatLng>[];
        _routeDistanceMeters = null;
        _routeDurationSeconds = null;
      });
    }
  }

  Future<void> _applyDriverPosition(
    Position position, {
    bool forceRoute = false,
  }) async {
    final next = LatLng(position.latitude, position.longitude);
    if (!mounted) return;

    setState(() {
      _driverPosition = next;
      _hasLiveLocation = true;
      _locationStatus = null;
    });

    if (_stage != _RideStage.waitingForRider) {
      await _refreshRoadRoute(force: forceRoute);
    }
  }

  Future<void> _refreshRoadRoute({bool force = false}) async {
    if (!_hasLiveLocation || _stage == _RideStage.waitingForRider) return;

    final now = DateTime.now();
    final lastOrigin = _lastRouteOrigin;
    final lastAt = _lastRouteAt;

    if (!force && lastOrigin != null && lastAt != null) {
      final movedMeters = Geolocator.distanceBetween(
        lastOrigin.latitude,
        lastOrigin.longitude,
        _driverPosition.latitude,
        _driverPosition.longitude,
      );

      if (movedMeters < 20 &&
          now.difference(lastAt) < const Duration(seconds: 5)) {
        return;
      }
    }

    _lastRouteOrigin = _driverPosition;
    _lastRouteAt = now;

    final requestToken = ++_routeRequestToken;
    final requestStage = _stage;
    final requestTarget = _routeTarget;
    final requestOrigin = _driverPosition;

    if (mounted) {
      setState(() {
        _routeLoading = true;
      });
    }

    try {
      final route = await _routeService.drivingRoute(
        origin: requestOrigin,
        destination: requestTarget,
      );

      if (!mounted ||
          requestToken != _routeRequestToken ||
          requestStage != _stage ||
          requestTarget != _routeTarget) {
        return;
      }

      setState(() {
        _roadRoutePoints = route.points;
        _routeDistanceMeters = route.distanceMeters;
        _routeDurationSeconds = route.durationSeconds;
        _routeLoading = false;
      });
    } catch (_) {
      if (!mounted ||
          requestToken != _routeRequestToken ||
          requestStage != _stage) {
        return;
      }

      setState(() {
        // Never draw a fake straight line when road routing is unavailable.
        _roadRoutePoints = <LatLng>[];
        _routeDistanceMeters = null;
        _routeDurationSeconds = null;
        _routeLoading = false;
      });
    }
  }

  String get _routeEtaText {
    final seconds = _routeDurationSeconds;
    if (seconds == null) return _routeLoading ? 'Routing…' : '—';
    final minutes = math.max(1, (seconds / 60).ceil());
    return '$minutes min';
  }

  String get _routeDistanceText {
    final meters = _routeDistanceMeters;
    if (meters == null) return _routeLoading ? 'road route' : '—';

    if (meters < 1000) {
      return '${meters.round()} m';
    }

    final km = meters / 1000;
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
  }

  Future<void> _fitRoute() async {
    final controller = _mapController;
    if (controller == null) return;

    final points = _roadRoutePoints.isNotEmpty
        ? _roadRoutePoints
        : <LatLng>[_driverPosition, _routeTarget];
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          100,
        ),
      );
    } catch (_) {}
  }

  Future<void> _advanceRide() async {
    if (_stageTransitioning || !mounted) return;

    _stageTransitioning = true;
    _routeRequestToken++;

    try {
      switch (_stage) {
        case _RideStage.headingToPickup:
          setState(() {
            _stage = _RideStage.waitingForRider;
            _waitSeconds = 0;
            _roadRoutePoints = <LatLng>[];
            _routeDistanceMeters = null;
            _routeDurationSeconds = null;
            _routeLoading = false;
          });
          _startWaitTimer();
          await _focusWaitingPickup();
          break;

        case _RideStage.waitingForRider:
          _waitTimer?.cancel();
          setState(() {
            _stage = _RideStage.onTrip;
            _roadRoutePoints = <LatLng>[];
            _routeDistanceMeters = null;
            _routeDurationSeconds = null;
          });
          _startOnTripRadar();
          await _refreshRoadRoute(force: true);
          if (mounted) {
            await _fitRoute();
          }
          break;

        case _RideStage.onTrip:
          _waitTimer?.cancel();
          _nextTripRadarDemoTimer?.cancel();
          _nextTripRadarMatchTimer?.cancel();
          WaybillStore.completeCurrent();

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            BottomToTopTransition(const DriverRideCompleted()),
          );
          return;
      }
    } finally {
      if (mounted) {
        _stageTransitioning = false;
      }
    }
  }

  Future<void> _focusWaitingPickup() async {
    final controller = _mapController;
    if (controller == null) return;

    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: widget.pickupPosition,
            zoom: 17.2,
          ),
        ),
      );
    } catch (_) {}
  }

  void _startOnTripRadar() {
    _nextTripRadarDemoTimer?.cancel();
    _nextTripRadarMatchTimer?.cancel();

    if (!mounted || _stage != _RideStage.onTrip) return;

    setState(() {
      _onTripRadarState = _OnTripRadarState.scanning;
      _nextTripRadarOffer = null;
    });

    // Frontend demo only. Production will replace this timer with a realtime
    // dispatch stream filtered for requests that can be served after drop-off.
    _nextTripRadarDemoTimer = Timer(
      const Duration(milliseconds: 4200),
      () {
        if (!mounted || _stage != _RideStage.onTrip) return;
        setState(() {
          _nextTripRadarOffer = _demoNextTripOffer;
          _onTripRadarState = _OnTripRadarState.offerAvailable;
        });
      },
    );
  }

  Future<void> _openNextTripRadar() async {
    if (_stage != _RideStage.onTrip) return;

    final offer = _nextTripRadarOffer;
    if (offer == null) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.22),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final secured =
                _onTripRadarState == _OnTripRadarState.secured;
            final matching =
                _onTripRadarState == _OnTripRadarState.matching;

            return Container(
              key: const ValueKey<String>('on-trip-radar-offer-sheet'),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FBFA),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD7DEDB),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _moveraRadarMark(size: 42),
                        const SizedBox(width: 11),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Next trip',
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Available after your current drop-off',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          offer.fare,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _nextTripMeta(
                                icon: Icons.local_taxi_outlined,
                                text: offer.category,
                              ),
                              const SizedBox(width: 12),
                              _nextTripMeta(
                                icon: Icons.star_rounded,
                                text: offer.rating.toStringAsFixed(2),
                              ),
                              const SizedBox(width: 12),
                              _nextTripMeta(
                                icon: Icons.schedule_rounded,
                                text: '${offer.pickupMinutes} min pickup',
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _nextTripLocationRow(
                            color: _green,
                            label: 'Pickup',
                            address: offer.pickup,
                          ),
                          const SizedBox(height: 10),
                          _nextTripLocationRow(
                            color: _ink,
                            label: '${offer.tripMinutes} min trip',
                            address: offer.dropoff,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.volume_off_outlined,
                          color: Color(0xFF7D898F),
                          size: 17,
                        ),
                        SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Silent Radar does not change your map, route or current-trip controls.',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 9.5,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        key: const ValueKey<String>(
                          'on-trip-radar-match-next',
                        ),
                        onPressed: secured || matching
                            ? null
                            : () {
                                setState(() {
                                  _onTripRadarState =
                                      _OnTripRadarState.matching;
                                });
                                setSheetState(() {});

                                _nextTripRadarMatchTimer?.cancel();
                                _nextTripRadarMatchTimer = Timer(
                                  const Duration(milliseconds: 900),
                                  () {
                                    if (!mounted ||
                                        _stage != _RideStage.onTrip) {
                                      return;
                                    }
                                    setState(() {
                                      _onTripRadarState =
                                          _OnTripRadarState.secured;
                                    });
                                    WaybillStore.secureNext(
                                      _buildNextWaybill(offer),
                                    );
                                    if (sheetContext.mounted) {
                                      setSheetState(() {});
                                    }
                                    Future<void>.delayed(
                                      const Duration(milliseconds: 550),
                                      () {
                                        if (sheetContext.mounted) {
                                          Navigator.pop(sheetContext);
                                        }
                                      },
                                    );
                                  },
                                );
                              },
                        style: FilledButton.styleFrom(
                          elevation: 0,
                          backgroundColor: _ink,
                          disabledBackgroundColor: secured
                              ? const Color(0xFFE6F5EE)
                              : const Color(0xFFE3E7E8),
                          foregroundColor: Colors.white,
                          disabledForegroundColor:
                              secured ? _green : const Color(0xFF7D898F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: matching
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 15,
                                    height: 15,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF7D898F),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Matching…',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                secured
                                    ? 'Next trip secured'
                                    : 'Match next trip',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _moveraRadarMark({double size = 34}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _mint,
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(
          color: const Color(0xFFD3E9DF),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.55,
            height: size * 0.55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _green.withOpacity(0.26),
                width: 1,
              ),
            ),
          ),
          Container(
            width: size * 0.31,
            height: size * 0.31,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _green.withOpacity(0.48),
                width: 1,
              ),
            ),
          ),
          Positioned(
            top: size * 0.20,
            right: size * 0.22,
            child: Container(
              width: size * 0.12,
              height: size * 0.12,
              decoration: const BoxDecoration(
                color: _green,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Text(
            'M',
            style: TextStyle(
              color: _green,
              fontSize: size * 0.27,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuredNextTripDetails() {
    final offer = _nextTripRadarOffer;
    if (_stage != _RideStage.onTrip ||
        _onTripRadarState != _OnTripRadarState.secured ||
        offer == null) {
      return const SizedBox.shrink();
    }

    return Container(
      key: const ValueKey<String>('secured-next-trip-details'),
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE8E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _moveraRadarMark(size: 34),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Next trip secured',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                offer.fare,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          _nextTripLocationRow(
            color: _green,
            label: 'Pickup · ${offer.pickupMinutes} min',
            address: offer.pickup,
          ),
          const SizedBox(height: 9),
          _nextTripLocationRow(
            color: _ink,
            label: 'Drop-off · ${offer.tripMinutes} min trip',
            address: offer.dropoff,
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${offer.category} · ${offer.riderName}',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                key: const ValueKey<String>('next-trip-waybill'),
                onPressed: () {
                  final record = WaybillStore.next;
                  if (record != null) {
                    showMoveraWaybillSheet(
                      context,
                      record,
                      title: 'Next trip waybill',
                    );
                  }
                },
                icon: const Icon(
                  Icons.receipt_long_outlined,
                  size: 15,
                ),
                label: const Text('Waybill'),
                style: TextButton.styleFrom(
                  foregroundColor: _green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nextTripMeta({
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF7D898F), size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF657178),
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _nextTripLocationRow({
    required Color color,
    required String label,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOnTripRadarStrip() {
    if (_stage != _RideStage.onTrip ||
        _onTripRadarState == _OnTripRadarState.off) {
      return const SizedBox.shrink();
    }

    final hasOffer = _nextTripRadarOffer != null;
    final secured = _onTripRadarState == _OnTripRadarState.secured;
    final matching = _onTripRadarState == _OnTripRadarState.matching;

    final title = secured
        ? 'Next trip secured'
        : hasOffer
            ? 'Next trip available'
            : 'Next trip Radar';
    final subtitle = secured
        ? 'Ready after drop-off'
        : hasOffer
            ? '${_nextTripRadarOffer!.fare} · '
                '${_nextTripRadarOffer!.pickupMinutes} min pickup'
            : 'Scanning quietly while you drive';

    return Material(
      key: const ValueKey<String>('on-trip-radar-strip'),
      color: secured ? const Color(0xFFEAF6F0) : const Color(0xFFF7F9F8),
      borderRadius: BorderRadius.circular(17),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: hasOffer ? _openNextTripRadar : null,
        child: Container(
          padding: const EdgeInsets.fromLTRB(11, 9, 10, 9),
          decoration: BoxDecoration(
            border: Border.all(
              color: secured
                  ? const Color(0xFFD1E9DD)
                  : const Color(0xFFE5E9EB),
            ),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: secured ? Colors.white : _mint,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: matching
                    ? const Padding(
                        padding: EdgeInsets.all(9),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _green,
                        ),
                      )
                    : _moveraRadarMark(size: 34),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      matching ? 'Matching next trip…' : title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 8.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasOffer && !matching)
                Icon(
                  secured
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: secured ? _green : const Color(0xFF98A3A8),
                  size: 19,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _startWaitTimer() {
    _waitTimer?.cancel();
    _waitTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _stage != _RideStage.waitingForRider) return;
      setState(() => _waitSeconds++);
    });
  }

  String get _waitLabel {
    final minutes = _waitSeconds ~/ 60;
    final seconds = (_waitSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _title {
    switch (_stage) {
      case _RideStage.headingToPickup:
        return 'Heading to pickup';
      case _RideStage.waitingForRider:
        return 'Waiting for rider';
      case _RideStage.onTrip:
        return 'Dropping off ${widget.riderName}';
    }
  }

  String get _subtitle {
    switch (_stage) {
      case _RideStage.headingToPickup:
        return '${widget.riderName} is waiting at ${widget.pickupAddress}';
      case _RideStage.waitingForRider:
        return '${widget.riderName} will be out shortly';
      case _RideStage.onTrip:
        return 'On the way to ${widget.dropoffAddress}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final panelHeight = math.min(420.0, constraints.maxHeight * 0.47);
          final safeTop = MediaQuery.paddingOf(context).top;

          return Stack(
            fit: StackFit.expand,
            children: [
              CustomGoogleMap(
                initialPosition: CameraPosition(
                  target: _driverPosition,
                  zoom: 15.8,
                ),
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                trafficEnabled: false,
                buildingsEnabled: true,
                indoorViewEnabled: false,
                mapType: MapType.normal,
                padding: EdgeInsets.only(bottom: panelHeight - 12),
                onMapCreated: (controller) {
                  _mapController = controller;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _fitRoute();
                  });
                },
              ),
              Positioned(
                left: 14,
                right: 14,
                top: safeTop + 10,
                child: _buildNavigationCard(),
              ),
              Positioned(
                right: 14,
                bottom: panelHeight + 16,
                child: _buildMapControls(),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: panelHeight,
                child: _buildRidePanel(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavigationCard() {
    final onTrip = _stage == _RideStage.onTrip;
    final waiting = _stage == _RideStage.waitingForRider;
    final eyebrow = waiting
        ? 'PICKUP'
        : onTrip
            ? 'DROP-OFF'
            : 'TO PICKUP';
    final headline = waiting
        ? widget.pickupAddress
        : onTrip
            ? widget.dropoffAddress
            : widget.pickupAddress;

    return Container(
      key: const ValueKey<String>('active-ride-navigation-card'),
      padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172027).withOpacity(0.12),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: waiting ? const Color(0xFFF1F3F4) : _mint,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              waiting
                  ? Icons.location_on_outlined
                  : onTrip
                      ? Icons.flag_outlined
                      : Icons.near_me_outlined,
              color: waiting ? _ink : _green,
              size: 23,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: TextStyle(
                    color: waiting ? _muted : _green,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.35,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  waiting
                      ? widget.pickupArea
                      : onTrip
                          ? 'Live route to destination'
                          : '${widget.pickupArea} · $_routeEtaText',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Container(
            constraints: const BoxConstraints(minWidth: 62),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: waiting ? const Color(0xFFF3F5F6) : _mint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  waiting ? _waitLabel : _routeEtaText,
                  style: TextStyle(
                    color: waiting ? _ink : _green,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  waiting ? 'WAIT' : _routeDistanceText,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControls() {
    return Column(
      children: [
        _mapCircleButton(
          icon: Icons.my_location_rounded,
          onTap: _fitRoute,
        ),
        const SizedBox(height: 9),
        _mapCircleButton(
          icon: Icons.shield_outlined,
          accent: _green,
          onTap: () => showSafetyToolKitSheet(context),
        ),
        const SizedBox(height: 9),
        _mapCircleButton(
          icon: Icons.layers_outlined,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Map layers will be connected to settings.'),
                backgroundColor: _ink,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _mapCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color accent = _ink,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: const Color(0xFF172027).withOpacity(0.16),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: 44,
          width: 44,
          child: Icon(icon, color: accent, size: 20),
        ),
      ),
    );
  }

  Widget _buildRidePanel() {
    return Container(
      key: ValueKey<String>('active-ride-panel-${_stage.name}'),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: _line)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172027).withOpacity(0.12),
            blurRadius: 28,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8DEDF),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 13),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _stagePill(),
                        const SizedBox(height: 8),
                        Text(
                          _title,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.55,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 10.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 7),
                        _liveStatus(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildEtaTile(),
                ],
              ),
              const SizedBox(height: 14),
              _buildProgress(),
              if (_stage == _RideStage.onTrip) ...[
                const SizedBox(height: 10),
                _buildOnTripRadarStrip(),
              ],
              const SizedBox(height: 14),
              _buildRiderRow(),
              const SizedBox(height: 14),
              _buildPrimaryAction(),
              if (_stage == _RideStage.onTrip)
                _buildSecuredNextTripDetails(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stagePill() {
    final label = switch (_stage) {
      _RideStage.headingToPickup => 'PICKUP',
      _RideStage.waitingForRider => 'WAITING',
      _RideStage.onTrip => 'ON TRIP',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _mint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _green,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  Widget _liveStatus() {
    final text = _hasLiveLocation
        ? (_routeLoading
            ? 'Live GPS · updating road route'
            : 'Live GPS · road route active')
        : (_locationStatus ?? 'Locating driver…');

    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: _hasLiveLocation ? _green : const Color(0xFF9AA4A9),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _muted,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEtaTile() {
    final main = _stage == _RideStage.waitingForRider
        ? _waitLabel
        : _routeEtaText;
    final sub = _stage == _RideStage.waitingForRider
        ? 'WAITING'
        : _routeDistanceText;

    return Container(
      constraints: const BoxConstraints(minWidth: 76),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _panel2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE7E2)),
      ),
      child: Column(
        children: [
          Text(
            main,
            style: const TextStyle(
              color: _ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              color: _muted,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    final current = switch (_stage) {
      _RideStage.headingToPickup => 1,
      _RideStage.waitingForRider => 2,
      _RideStage.onTrip => 3,
    };

    final items = const [
      ('Matched', Icons.check_rounded),
      ('Pickup', Icons.location_on_outlined),
      ('Rider', Icons.person_outline_rounded),
      ('Trip', Icons.route_outlined),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final done = index < current;
          final active = index == current;
          final color = done || active ? _green : const Color(0xFFA6B0B4);

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: active ? 26 : 22,
                        height: active ? 26 : 22,
                        decoration: BoxDecoration(
                          color: done
                              ? _green
                              : active
                                  ? _mint
                                  : const Color(0xFFEEF1F2),
                          shape: BoxShape.circle,
                          border: active
                              ? Border.all(color: _green, width: 1.5)
                              : null,
                        ),
                        child: Icon(
                          items[index].$2,
                          size: 13,
                          color: done ? Colors.white : color,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        items[index].$1,
                        style: TextStyle(
                          color: done || active ? _ink : _muted,
                          fontSize: 8,
                          fontWeight:
                              active ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index != items.length - 1)
                  Container(
                    width: 8,
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    color: done ? _green : const Color(0xFFDDE3E4),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRiderRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD9E4DF)),
            ),
            child: const CircleAvatar(
              backgroundImage: AssetImage(AppAssets.profileImg),
              backgroundColor: Color(0xFFE9EEEC),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: _showRiderProfile,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.riderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${widget.riderRating.toStringAsFixed(1)} ★ · ${widget.riderTrips} rides',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          _riderAction(
            tooltip: 'Call rider',
            icon: Icons.call_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Phone integration will call the rider.'),
                  backgroundColor: _ink,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          _riderAction(
            tooltip: 'Message rider',
            icon: Icons.chat_bubble_outline_rounded,
            onTap: () {
              Navigator.push(
                context,
                BottomToTopTransition(const Chat()),
              );
            },
          ),
          const SizedBox(width: 6),
          _riderAction(
            tooltip: 'Rider profile',
            icon: Icons.person_outline_rounded,
            onTap: _showRiderProfile,
          ),
        ],
      ),
    );
  }

  Widget _riderAction({
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: _mint,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: SizedBox(
            width: 37,
            height: 37,
            child: Icon(icon, color: _green, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryAction() {
    return Row(
      children: [
        Material(
          key: const ValueKey<String>('active-ride-trip-options'),
          color: const Color(0xFFF0F3F2),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: _showTripOptions,
            borderRadius: BorderRadius.circular(16),
            child: const SizedBox(
              height: 54,
              width: 54,
              child: Icon(
                Icons.tune_rounded,
                color: _ink,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SlideRideAction(
            key: ValueKey<String>('active-ride-primary-action-${_stage.name}'),
            semanticsKey:
                const ValueKey<String>('active-ride-primary-action'),
            label: switch (_stage) {
              _RideStage.headingToPickup => 'Slide to confirm pickup',
              _RideStage.waitingForRider => 'Slide to start trip',
              _RideStage.onTrip => 'Slide to complete trip',
            },
            icon: switch (_stage) {
              _RideStage.headingToPickup => Icons.location_on_outlined,
              _RideStage.waitingForRider => Icons.play_arrow_rounded,
              _RideStage.onTrip => Icons.flag_outlined,
            },
            onConfirmed: () {
              _advanceRide();
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showRiderProfile() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          decoration: const BoxDecoration(
            color: Color(0xFFF7F9F8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundImage: AssetImage(AppAssets.profileImg),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.riderName,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${widget.riderRating.toStringAsFixed(1)} ★ · ${widget.riderTrips} rides',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _line),
                  ),
                  child: const Text(
                    'Rider details from the booking will appear here when the backend profile is connected.',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showTripOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
          decoration: const BoxDecoration(
            color: Color(0xFFF7F9F9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DEDF),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 16),
                _optionTile(
                  key: const ValueKey<String>('current-trip-waybill-option'),
                  icon: Icons.receipt_long_outlined,
                  title: 'Current waybill',
                  subtitle: '${widget.pickupAddress} → ${widget.dropoffAddress}',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    final record = WaybillStore.current;
                    if (record != null) {
                      showMoveraWaybillSheet(
                        context,
                        record,
                        title: 'Current trip waybill',
                      );
                    }
                  },
                ),
                if (_onTripRadarState == _OnTripRadarState.secured &&
                    WaybillStore.next != null)
                  _optionTile(
                    key: const ValueKey<String>('next-trip-waybill-option'),
                    icon: Icons.radar_rounded,
                    title: 'Next trip waybill',
                    subtitle: WaybillStore.next!.dropoff,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      showMoveraWaybillSheet(
                        context,
                        WaybillStore.next!,
                        title: 'Next trip waybill',
                      );
                    },
                  ),
                _optionTile(
                  icon: Icons.shield_outlined,
                  title: 'Safety toolkit',
                  subtitle: 'Share trip, record audio or get help',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    showSafetyToolKitSheet(context);
                  },
                ),
                _optionTile(
                  key: const ValueKey<String>('active-ride-cancel-option'),
                  icon: _stage == _RideStage.onTrip
                      ? Icons.stop_circle_outlined
                      : Icons.close_rounded,
                  title: _stage == _RideStage.onTrip
                      ? 'End trip early'
                      : 'Cancel trip',
                  subtitle: _stage == _RideStage.onTrip
                      ? 'Stop safely first · reason required'
                      : 'Choose a reason before cancelling',
                  danger: true,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showCancellationReasons();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _optionTile({
    Key? key,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return Material(
      key: key,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: danger
                      ? const Color(0xFFFFECEE)
                      : const Color(0xFFEAF1EE),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: danger ? _danger : const Color(0xFF315E4D),
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: danger ? _danger : const Color(0xFF252E3A),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7D898F),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFA7B0B4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCancellationReasons() async {
    final isOnTrip = _stage == _RideStage.onTrip;
    final reasons =
        isOnTrip ? _onTripCancellationReasons : _preTripCancellationReasons;

    final reason = await showModalBottomSheet<_TripCancellationReason>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.32),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: isOnTrip ? 0.72 : 0.66,
          minChildSize: 0.48,
          maxChildSize: 0.88,
          expand: false,
          builder: (context, controller) {
            return Container(
              key: const ValueKey<String>('trip-cancellation-reasons-sheet'),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAF9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7DEDB),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOnTrip
                                ? 'Why are you ending the trip?'
                                : 'Why are you cancelling?',
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            isOnTrip
                                ? 'Stop the vehicle in a safe place before ending an active trip.'
                                : 'Choose the reason that best explains the cancellation.',
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 11,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(14, 2, 14, 20),
                        itemCount: reasons.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 7),
                        itemBuilder: (context, index) {
                          final reason = reasons[index];
                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(17),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              key: ValueKey<String>(
                                'trip-cancel-reason-${reason.code}',
                              ),
                              onTap: () =>
                                  Navigator.pop(sheetContext, reason),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  11,
                                  10,
                                  11,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 39,
                                      height: 39,
                                      decoration: BoxDecoration(
                                        color: isOnTrip
                                            ? const Color(0xFFFFEEF0)
                                            : const Color(0xFFF0F3F2),
                                        borderRadius:
                                            BorderRadius.circular(13),
                                      ),
                                      child: Icon(
                                        reason.icon,
                                        color: isOnTrip
                                            ? _danger
                                            : const Color(0xFF58656C),
                                        size: 19,
                                      ),
                                    ),
                                    const SizedBox(width: 11),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            reason.title,
                                            style: const TextStyle(
                                              color: _ink,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            reason.subtitle,
                                            style: const TextStyle(
                                              color: _muted,
                                              fontSize: 9.5,
                                              height: 1.3,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: Color(0xFFA5AFB4),
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || reason == null) return;
    await _confirmCancellationReason(reason);
  }

  Future<void> _confirmCancellationReason(
    _TripCancellationReason reason,
  ) async {
    final isOnTrip = _stage == _RideStage.onTrip;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.34),
      builder: (sheetContext) {
        return Container(
          key: const ValueKey<String>('trip-cancellation-confirmation'),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAF9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DEDB),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 17),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECEE),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(
                    isOnTrip
                        ? Icons.stop_circle_outlined
                        : Icons.close_rounded,
                    color: _danger,
                    size: 25,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isOnTrip ? 'End this trip early?' : 'Cancel this trip?',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  reason.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isOnTrip) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5E8),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFB87512),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Only end the trip after you have stopped in a safe place and the rider can exit safely.',
                            style: TextStyle(
                              color: Color(0xFF8B641F),
                              fontSize: 10,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 17),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    key: const ValueKey<String>(
                      'confirm-trip-cancellation',
                    ),
                    onPressed: () => Navigator.pop(sheetContext, true),
                    style: FilledButton.styleFrom(
                      elevation: 0,
                      backgroundColor: _danger,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      isOnTrip ? 'End trip early' : 'Cancel trip',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext, false),
                  child: const Text(
                    'Keep trip',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;
    _submitTripCancellation(reason);
  }

  void _submitTripCancellation(_TripCancellationReason reason) {
    _waitTimer?.cancel();

    // Frontend contract: reason.code is ready to be sent with the backend
    // cancellation event once trip persistence is connected.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _stage == _RideStage.onTrip
              ? 'Trip ended early · ${reason.title}'
              : 'Trip cancelled · ${reason.title}',
        ),
        backgroundColor: _ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );

    Navigator.pop(context);
  }

}

class _SlideRideAction extends StatefulWidget {
  const _SlideRideAction({
    super.key,
    required this.semanticsKey,
    required this.label,
    required this.icon,
    required this.onConfirmed,
  });

  final Key semanticsKey;
  final String label;
  final IconData icon;
  final VoidCallback onConfirmed;

  @override
  State<_SlideRideAction> createState() => _SlideRideActionState();
}

class _SlideRideActionState extends State<_SlideRideAction> {
  static const double _height = 54;
  static const double _thumb = 46;
  static const double _trigger = 0.78;

  double _fraction = 0;
  bool _dragging = false;
  bool _confirmed = false;

  void _update(double delta, double maxTravel) {
    if (_confirmed || maxTravel <= 0) return;
    setState(() {
      _dragging = true;
      _fraction = (_fraction + (delta / maxTravel)).clamp(0.0, 1.0);
    });
  }

  void _finish() {
    if (_confirmed) return;

    if (_fraction >= _trigger) {
      setState(() {
        _confirmed = true;
        _dragging = false;
        _fraction = 1;
      });
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (mounted) widget.onConfirmed();
      });
    } else {
      setState(() {
        _dragging = false;
        _fraction = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: widget.semanticsKey,
      height: _height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxTravel = math.max(0.0, constraints.maxWidth - _thumb - 8);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) =>
                _update(details.delta.dx, maxTravel),
            onHorizontalDragEnd: (_) => _finish(),
            onHorizontalDragCancel: _finish,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF252E3A),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: _dragging
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          width: constraints.maxWidth *
                              math.min(1.0, _fraction + 0.08),
                          decoration: BoxDecoration(
                            color: const Color(0xFF19865C).withOpacity(0.28),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 54),
                    child: Text(
                      _confirmed ? 'Confirmed' : widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.15,
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: _dragging
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    left: 4 + (maxTravel * _fraction),
                    top: 4,
                    child: Container(
                      width: _thumb,
                      height: _thumb,
                      decoration: BoxDecoration(
                        color: _confirmed
                            ? const Color(0xFF74D6A8)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        _confirmed ? Icons.check_rounded : widget.icon,
                        color: const Color(0xFF252E3A),
                        size: 20,
                      ),
                    ),
                  ),
                  if (!_confirmed)
                    const Positioned(
                      right: 12,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF96A0A5),
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


