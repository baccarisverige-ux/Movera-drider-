import 'package:movera/core/location/location_freshness.dart';
import 'package:movera/core/ride/completion_journal.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:movera/core/logging/driver_log.dart';
import 'package:movera/widgets/preview_unavailable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/core/contracts/trip_status.dart';
import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/geo/geo_point_maps.dart';
import 'package:movera/core/routing/route_maps.dart';
import 'package:movera/core/location/driver_location_repository.dart';
import 'package:movera/core/location/driver_location_service.dart';
import 'package:movera/core/navigation/live_vehicle_animator.dart';
import 'package:movera/core/navigation/navigation_controller.dart';
import 'package:movera/core/ride/active_ride_controller.dart';
import 'package:movera/core/ride/active_ride_repository.dart';
import 'package:movera/core/realtime/driver_realtime.dart';
import 'package:movera/core/routing/road_route_service.dart';
import 'package:movera/core/routing/route_repository.dart';
import 'package:movera/core/session/driver_session_controller.dart';
import 'package:movera/core/waybill/waybill.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/presentation/common/chat/chat.dart';
import 'package:movera/presentation/driver/accept%20ride/navigation_instruction_banner.dart';
import 'package:movera/presentation/driver/accept%20ride/waiting_time_sheet.dart';
import 'package:movera/presentation/driver/accept%20ride/compact_trip_dock.dart';
import 'package:movera/presentation/driver/accept%20ride/rider_cancelled_sheet.dart';
import 'package:movera/presentation/driver/overlays/map_overlay_insets.dart';
import 'package:movera/presentation/driver/sheets/movera_snap_sheet_controller.dart';
import 'package:movera/presentation/driver/ride%20completed/ride_completed.dart';
import 'package:movera/presentation/driver/safety%20toolkits/safety_toolkits.dart';
import 'package:movera/presentation/driver/waybill/waybill_sheet.dart';
import 'package:movera/widgets/custom_google_map.dart';
import 'package:movera/widgets/layout_viewport.dart';
import 'package:movera/widgets/movera_modal_sheet.dart';
import 'package:movera/widgets/movera_sheet_metrics.dart';
import 'package:movera/widgets/movera_vehicle_marker.dart';
import 'package:movera/widgets/movera_line_icon.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class AcceptRide extends StatefulWidget {
  const AcceptRide({
    super.key,
    this.offerId = 'demo-radar-offer',
    this.riderName = 'Angelica',
    this.riderRating = 4.9,
    this.riderTrips = 312,
    this.fare = '—',
    this.category = 'Movera',
    this.matchedVia = 'Demo Radar',
    this.pickupAddress = 'Odlarvägen 22',
    this.pickupArea = 'Enhörna',
    this.dropoffAddress = 'T-Centralen, Stockholm',
    this.stopAddresses = const <String>[],
    this.stopPositions = const <LatLng>[],
    this.pickupPosition = const LatLng(59.3279, 18.0615),
    this.dropoffPosition = const LatLng(59.3326, 18.0649),
    this.locationRepository,
    this.routeRepository,
    this.waybillRepository,
    this.sessionController,
    this.activeRideRepository,
    this.realtime,
    this.initialStage = ActiveRideStage.headingToPickup,
    this.initialWaitSeconds = 0,
    this.restoredSnapshot,
    this.destinationModeActive = false,
    this.destinationAddress,
    this.destinationPosition,
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
  final List<String> stopAddresses;
  final List<LatLng> stopPositions;
  final LatLng pickupPosition;
  final LatLng dropoffPosition;
  final DriverLocationRepository? locationRepository;
  final RouteRepository? routeRepository;
  final WaybillRepository? waybillRepository;
  final DriverSessionController? sessionController;
  final ActiveRideRepository? activeRideRepository;
  final DriverRealtime? realtime;
  final ActiveRideStage initialStage;
  final int initialWaitSeconds;
  final PersistedActiveRide? restoredSnapshot;
  final bool destinationModeActive;
  final String? destinationAddress;
  final LatLng? destinationPosition;

  factory AcceptRide.fromQueuedWaybill(
    WaybillRecord record, {
    Key? key,
    DriverLocationRepository? locationRepository,
    RouteRepository? routeRepository,
    WaybillRepository? waybillRepository,
    DriverSessionController? sessionController,
    ActiveRideRepository? activeRideRepository,
  }) {
    final pickup = record.pickup;
    return AcceptRide(
      key: key,
      offerId: record.tripId,
      riderName: record.riderName,
      fare: record.fare,
      category: record.service,
      matchedVia: record.source,
      pickupAddress: pickup,
      pickupArea: pickup.split(',').last.trim(),
      dropoffAddress: record.dropoff,
      locationRepository: locationRepository,
      routeRepository: routeRepository,
      waybillRepository: waybillRepository,
      sessionController: sessionController,
      activeRideRepository: activeRideRepository,
    );
  }

  factory AcceptRide.fromPersisted(
    PersistedActiveRide snapshot, {
    Key? key,
    DriverLocationRepository? locationRepository,
    RouteRepository? routeRepository,
    WaybillRepository? waybillRepository,
    DriverSessionController? sessionController,
    ActiveRideRepository? activeRideRepository,
  }) {
    final pickup = snapshot.pickupAddress ?? 'Stockholm';
    return AcceptRide(
      key: key,
      offerId: snapshot.tripId,
      riderName: snapshot.riderName ?? 'Rider data unavailable',
      riderRating: snapshot.riderRating ?? 4.9,
      riderTrips: snapshot.riderTrips ?? 312,
      fare: snapshot.fare ?? '—',
      category: snapshot.category ?? 'Movera',
      matchedVia: snapshot.matchedVia ?? 'Demo Radar',
      pickupAddress: pickup,
      pickupArea: snapshot.pickupArea ?? pickup.split(',').last.trim(),
      dropoffAddress: snapshot.dropoffAddress ?? 'Stockholm',
      stopAddresses: snapshot.stopAddresses,
      stopPositions: snapshot.stopPoints.map((point) => point.toLatLng()).toList(),
      pickupPosition: LatLng(
        snapshot.pickupLat ?? 59.3279,
        snapshot.pickupLng ?? 18.0615,
      ),
      dropoffPosition: LatLng(
        snapshot.dropoffLat ?? 59.3326,
        snapshot.dropoffLng ?? 18.0649,
      ),
      locationRepository: locationRepository,
      routeRepository: routeRepository,
      waybillRepository: waybillRepository,
      sessionController: sessionController,
      activeRideRepository: activeRideRepository,
      initialStage: snapshot.stage,
      initialWaitSeconds: snapshot.waitSeconds ?? 0,
      restoredSnapshot: snapshot,
    );
  }

  @override
  State<AcceptRide> createState() => _AcceptRideState();
}

enum _OnTripRadarState { off, scanning, offerAvailable, matching, secured, stopped }

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
    required this.pickupPosition,
    required this.dropoffPosition,
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
  final LatLng pickupPosition;
  final LatLng dropoffPosition;
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
  final MoveraMark icon;
}

class _AcceptRideState extends State<AcceptRide>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _ink = Color(0xFF252E3A);
  static const Color _panel = Color(0xFFFFFFFF);
  static const Color _canvas = Color(0xFFF4F6F7);
  static const Color _muted = Color(0xFF7D898F);
  static const Color _green = Color(0xFF19865C);
  static const Color _mint = Color(0xFFE6F5EE);
  static const Color _line = Color(0xFFE5E9EB);
  static const Color _danger = Color(0xFFE75D65);
  static const double _nextTripRadarRadiusMeters = 30000;

  static const List<_TripCancellationReason> _preTripCancellationReasons = [
    _TripCancellationReason(
      code: 'rider_requested_cancel',
      title: 'Rider requested cancellation',
      subtitle: 'The rider asked not to continue with this pickup',
      icon: MoveraMark.user,
    ),
    _TripCancellationReason(
      code: 'rider_not_at_pickup',
      title: 'Rider not at pickup',
      subtitle: 'You arrived but could not find or reach the rider',
      icon: MoveraMark.pin,
    ),
    _TripCancellationReason(
      code: 'unsafe_pickup',
      title: 'Pickup is unsafe or inaccessible',
      subtitle: 'You cannot stop or complete the pickup safely',
      icon: MoveraMark.warning,
    ),
    _TripCancellationReason(
      code: 'vehicle_issue_before_start',
      title: 'Vehicle problem',
      subtitle: 'A vehicle issue prevents the trip from starting',
      icon: MoveraMark.car,
    ),
    _TripCancellationReason(
      code: 'driver_emergency_before_start',
      title: 'Personal emergency',
      subtitle: 'An urgent situation prevents you from continuing',
      icon: MoveraMark.bolt,
    ),
    _TripCancellationReason(
      code: 'other_before_start',
      title: 'Other reason',
      subtitle: 'Another issue prevents this pickup',
      icon: MoveraMark.more,
    ),
  ];

  static const _TripCancellationReason _noShowReason = _TripCancellationReason(
    code: 'rider_no_show',
    title: 'Rider did not arrive',
    subtitle: 'Five minutes have passed and the rider is not here',
    icon: MoveraMark.user,
  );

  static const List<_TripCancellationReason> _onTripCancellationReasons = [
    _TripCancellationReason(
      code: 'rider_requested_early_end',
      title: 'Rider asked to end the trip',
      subtitle: 'The rider wants to leave before the destination',
      icon: MoveraMark.user,
    ),
    _TripCancellationReason(
      code: 'safety_concern_on_trip',
      title: 'Safety concern',
      subtitle: 'Continuing the trip may be unsafe',
      icon: MoveraMark.shield,
    ),
    _TripCancellationReason(
      code: 'vehicle_issue_on_trip',
      title: 'Vehicle problem',
      subtitle: 'A vehicle issue makes it unsafe to continue',
      icon: MoveraMark.car,
    ),
    _TripCancellationReason(
      code: 'accident_or_road_emergency',
      title: 'Accident or road emergency',
      subtitle: 'An incident or emergency prevents continuing',
      icon: MoveraMark.warning,
    ),
    _TripCancellationReason(
      code: 'rider_behavior',
      title: 'Rider behavior',
      subtitle: 'The rider’s behavior requires the trip to end',
      icon: MoveraMark.message,
    ),
    _TripCancellationReason(
      code: 'trip_or_destination_issue',
      title: 'Trip or destination issue',
      subtitle: 'A trip detail or destination problem prevents continuing',
      icon: MoveraMark.route,
    ),
    _TripCancellationReason(
      code: 'other_on_trip',
      title: 'Other reason',
      subtitle: 'Another issue requires the trip to end early',
      icon: MoveraMark.more,
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
    pickupPosition: LatLng(59.3328, 18.0587),
    dropoffPosition: LatLng(59.3142, 18.0735),
  );



  late final DriverLocationRepository _locationService;
  late final RouteRepository _routeService;
  late final WaybillRepository _waybills;
  late final NavigationController _navigation;
  late final LiveVehicleAnimator _vehicle;
  BitmapDescriptor _driverVehicleIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
  final PanelController _ridePanelController = PanelController();
  final ValueNotifier<double> _ridePanelPosition = ValueNotifier<double>(1);
  late final MoveraSnapSheetController _snapSheet;
  double _ridePointerVelocity = 0;
  double _ridePointerLastY = 0;
  int _ridePointerLastMs = 0;
  bool _ridePointerActive = false;
  Timer? _rideSheetPositionGuardTimer;

  GoogleMapController? _mapController;
  StreamSubscription<DriverLocation>? _positionSubscription;
  late final ActiveRideController _rideLifecycle = ActiveRideController(
    tripId: widget.offerId,
    repository: widget.activeRideRepository,
    initialStage: widget.initialStage,
  );
  ActiveRideStage get _stage => _rideLifecycle.stage;
  Timer? _waitTimer;
  StreamSubscription<DriverRealtimeEvent>? _realtimeSubscription;
  late final DriverRealtime _realtime;
  late final bool _ownsRealtime;
  bool _riderOnTheWay = false;
  bool _handlingRiderCancellation = false;
  Timer? _nextTripRadarDemoTimer;
  Timer? _nextTripRadarMatchTimer;
  Timer? _nextTripOfferExpiry;
  static const Duration _onTripOfferLifetime = Duration(milliseconds: 8500);
  DateTime? _lastGpsAppliedAt;
  DateTime? _lastSnapshotAt;
  bool _liveUpdatesPaused = false;
  int _waitSeconds = 0;
  int _stopCursor = 0;
  bool _paidStopWait = false;
  DateTime? _onTripStartedAt;
  _OnTripRadarState _onTripRadarState = _OnTripRadarState.off;
  _NextTripRadarOffer? _nextTripRadarOffer;
  bool _onTripRadarDeclined = false;

  LatLng _driverPosition = _fallbackDriverPosition;
  List<GeoPoint> _roadGeoPoints = <GeoPoint>[];
  List<LatLng> _roadRoutePoints = <LatLng>[];
  List<LatLng> _cachedPolylinePoints = const <LatLng>[];
  Set<Polyline> _cachedPolylines = <Polyline>{};
  double? _routeDistanceMeters;
  double? _routeDurationSeconds;
  bool _hasLiveLocation = false;
  bool _routeLoading = false;
  bool _stageTransitioning = false;
  bool _completionInFlight = false;
  bool _blockMapGestures = false;
  bool _cameraProgrammatic = false;
  DateTime? _lastCameraFollowAt;
  late final AnimationController _radarPulseController;
  late final AnimationController _radarSweepController;
  String? _locationStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locationService =
        widget.locationRepository ?? const DriverLocationService();
    _routeService = widget.routeRepository ?? RoadRouteService();
    _waybills =
        widget.waybillRepository ?? InMemoryWaybillRepository.instance;
    _navigation = NavigationController(routeRepository: _routeService);
    _navigation.addListener(_onNavigationChanged);
    _ownsRealtime = widget.realtime == null;
    _realtime = widget.realtime ?? MemoryDriverRealtime();
    _realtimeSubscription =
        _realtime.subscribe(widget.offerId).listen(_onRealtimeEvent);
    _rideLifecycle.snapshotBuilder = _buildSnapshot;
    _rideLifecycle.addListener(_onPersistenceChanged);
    _rideLifecycle.addListener(_syncNavigationStage);
    _syncNavigationStage();
    _restoreQueuedNextFromSnapshot();
    final restored = widget.restoredSnapshot;
    _stopCursor = math.min(math.max(0, restored?.stopIndex ?? 0), widget.stopAddresses.length);
    _paidStopWait = restored?.paidStopWait == true;
    _onTripStartedAt = restored?.startedAt;
    _waitSeconds = widget.initialWaitSeconds;
    if (restored?.savedAt != null &&
        (widget.initialStage == ActiveRideStage.waitingForRider || _paidStopWait)) {
      final elapsed = DateTime.now().difference(restored!.savedAt!).inSeconds;
      _waitSeconds += math.max(0, elapsed);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _waybills.beginCurrent(_buildCurrentWaybill());
      if (widget.restoredSnapshot?.next != null && _nextTripRadarOffer != null) {
        _waybills.secureNext(_buildNextWaybill(_nextTripRadarOffer!));
      }
      _resumeStageSideEffects();
      _rideLifecycle.persistNow();
    });
    _radarPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _radarSweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _snapSheet = MoveraSnapSheetController(
      panel: _ridePanelController,
      vsync: this,
    );
    _vehicle = LiveVehicleAnimator(
      vsync: this,
      initial: const LiveVehiclePose(
        position: _fallbackDriverPosition,
        headingDegrees: 0,
      ),
    );
    unawaited(_prepareDriverVehicleMarker());
    _startLiveLocation();
  }

  @override
  void dispose() {
    _rideSheetPositionGuardTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _waitTimer?.cancel();
    _realtimeSubscription?.cancel();
    _realtime.unsubscribe();
    if (_ownsRealtime) {
      _realtime.dispose();
    }
    _nextTripRadarDemoTimer?.cancel();
    _nextTripRadarMatchTimer?.cancel();
    _nextTripOfferExpiry?.cancel();
    _radarPulseController.dispose();
    _radarSweepController.dispose();
    _positionSubscription?.cancel();
    _rideLifecycle.removeListener(_syncNavigationStage);
    _rideLifecycle.dispose();
    _navigation.removeListener(_onNavigationChanged);
    _navigation.dispose();
    _vehicle.dispose();
    _snapSheet.dispose();
    _ridePanelPosition.dispose();
    _mapController = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _resumeLiveUpdates();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _rideLifecycle.persistNow();
        _pauseLiveUpdates();
    }
  }

  PersistedActiveRide _buildSnapshot(ActiveRideStage stage) {
    final offer = _nextTripRadarOffer;
    final securedOffer =
        _onTripRadarState == _OnTripRadarState.secured ? offer : null;
    return PersistedActiveRide(
      tripId: widget.offerId,
      stage: stage,
      nextTripId: securedOffer?.id,
      riderName: widget.riderName,
      riderRating: widget.riderRating,
      riderTrips: widget.riderTrips,
      fare: widget.fare,
      category: widget.category,
      matchedVia: widget.matchedVia,
      pickupAddress: widget.pickupAddress,
      pickupArea: widget.pickupArea,
      dropoffAddress: widget.dropoffAddress,
      stopAddresses: widget.stopAddresses,
      stopPoints: widget.stopPositions.map(GeoPointMaps.fromLatLng).toList(),
      pickupLat: widget.pickupPosition.latitude,
      pickupLng: widget.pickupPosition.longitude,
      dropoffLat: widget.dropoffPosition.latitude,
      dropoffLng: widget.dropoffPosition.longitude,
      waitSeconds: _waitSeconds,
      stopIndex: _stopCursor,
      paidStopWait: _paidStopWait,
      startedAt: _onTripStartedAt,
      next: securedOffer == null
          ? null
          : PersistedQueuedTrip(
              tripId: securedOffer.id,
              riderName: securedOffer.riderName,
              fare: securedOffer.fare,
              category: securedOffer.category,
              pickup: securedOffer.pickup,
              dropoff: securedOffer.dropoff,
              pickupLat: securedOffer.pickupPosition.latitude,
              pickupLng: securedOffer.pickupPosition.longitude,
              dropoffLat: securedOffer.dropoffPosition.latitude,
              dropoffLng: securedOffer.dropoffPosition.longitude,
              rating: securedOffer.rating,
              pickupMinutes: securedOffer.pickupMinutes,
              tripMinutes: securedOffer.tripMinutes,
            ),
    );
  }

  void _restoreQueuedNextFromSnapshot() {
    final next = widget.restoredSnapshot?.next;
    if (next == null) return;
    _onTripRadarState = _OnTripRadarState.secured;
    _nextTripRadarOffer = _NextTripRadarOffer(
      id: next.tripId,
      category: next.category,
      fare: next.fare,
      rating: next.rating,
      pickupMinutes: next.pickupMinutes,
      tripMinutes: next.tripMinutes,
      riderName: next.riderName,
      pickup: next.pickup,
      dropoff: next.dropoff,
      pickupPosition: LatLng(next.pickupLat, next.pickupLng),
      dropoffPosition: LatLng(next.dropoffLat, next.dropoffLng),
    );
  }

  void _resumeStageSideEffects() {
    switch (widget.initialStage) {
      case ActiveRideStage.headingToPickup:
        return;
      case ActiveRideStage.waitingForRider:
        _startWaitTimer();
        unawaited(_focusWaitingPickup());
      case ActiveRideStage.onTrip:
        if (_onTripRadarState != _OnTripRadarState.secured) {
          _startOnTripRadar();
        }
        unawaited(_refreshOnTripRoute(fitCamera: true));
    }
  }

  void _pauseLiveUpdates() {
    if (_liveUpdatesPaused) return;
    _liveUpdatesPaused = true;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    if (_radarPulseController.isAnimating) {
      _radarPulseController.stop();
    }
    if (_radarSweepController.isAnimating) {
      _radarSweepController.stop();
    }
  }

  void _resumeLiveUpdates() {
    if (!_liveUpdatesPaused) return;
    _liveUpdatesPaused = false;
    if (!_radarPulseController.isAnimating) {
      _radarPulseController.repeat(reverse: true);
    }
    if (!_radarSweepController.isAnimating) {
      _radarSweepController.repeat();
    }
    unawaited(_startLiveLocation());
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
      source: 'Demo Radar',
      driverName: 'Movera Driver',
      vehicle: 'Movera partner vehicle',
      licensePlate: 'MVR 418',
      passengerCapacity: 4,
    );
  }

  LatLng? get _routeTarget {
    if (_stage == ActiveRideStage.onTrip &&
        _stopCursor < widget.stopAddresses.length) {
      return _stopPoint(_stopCursor);
    }
    if (_stage == ActiveRideStage.onTrip) return widget.dropoffPosition;
    return widget.pickupPosition;
  }

  LatLng? _stopPoint(int index) {
    if (index < 0 || index >= widget.stopPositions.length) return null;
    return widget.stopPositions[index];
  }

  bool get _arrivalDemo {
    final binding = WidgetsBinding.instance.runtimeType.toString();
    return binding.contains('Test');
  }

  LatLng? get _arrivalTarget {
    if (_stage == ActiveRideStage.headingToPickup) return widget.pickupPosition;
    if (_stage == ActiveRideStage.onTrip &&
        !_paidStopWait &&
        _stopCursor < widget.stopAddresses.length) {
      return _stopPoint(_stopCursor);
    }
    return null;
  }

  bool get _nearArrivalTarget {
    final target = _arrivalTarget;
    if (target == null) return false;
    if (_arrivalDemo) return true;
    if (!_hasLiveLocation) return false;
    return GeoPointMaps.fromLatLng(_driverPosition).distanceMetersTo(
          GeoPointMaps.fromLatLng(target),
        ) <=
        100;
  }

  bool get _countingWait =>
      _stage == ActiveRideStage.waitingForRider || _paidStopWait;


  void _syncNavigationStage() {
    _navigation.setStage(_rideLifecycle.stage);
  }

  void _onRealtimeEvent(DriverRealtimeEvent event) {
    if (!mounted || event.tripId != widget.offerId) return;

    switch (event.kind) {
      case DriverRealtimeKind.riderOnTheWay:
        if (_rideLifecycle.terminal) return;
        setState(() => _riderOnTheWay = true);
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(
              event.message?.trim().isNotEmpty == true
                  ? event.message!
                  : '${widget.riderName} is on the way',
            ),
            backgroundColor: _ink,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      case DriverRealtimeKind.riderCancelled:
        unawaited(_handleRiderCancelled());
      case DriverRealtimeKind.tripProjection:
      case DriverRealtimeKind.location:
      case DriverRealtimeKind.driverArrived:
        return;
    }
  }

  Future<void> _handleRiderCancelled() async {
    if (!mounted ||
        _handlingRiderCancellation ||
        _rideLifecycle.terminal) {
      return;
    }

    _handlingRiderCancellation = true;
    final wasOnTrip = _stage == ActiveRideStage.onTrip;

    _waitTimer?.cancel();
    _nextTripRadarDemoTimer?.cancel();
    _nextTripRadarMatchTimer?.cancel();
    _pauseLiveUpdates();

    if (!await _rideLifecycle.cancel(status: TripStatus.cancelledByRider)) {
      _handlingRiderCancellation = false;
      return;
    }
    _waybills.discardCurrent();

    await showRiderCancelledSheet(
      context,
      riderName: widget.riderName,
      wasOnTrip: wasOnTrip,
    );
    if (!mounted) return;

    widget.sessionController?.stayOnlineAfterTrip();
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void _onPersistenceChanged() {
    if (!mounted || _rideLifecycle.persistenceError == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Trip progress could not be saved. Keep this screen open and retry.'),
      action: SnackBarAction(label: 'Retry', onPressed: () { _rideLifecycle.persistNow(); }),
    ));
  }

  void _blockedArrival() {
    if (_arrivalTarget == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('This stop needs a verified map location before arrival.'),
      ));
      return;
    }
    if (!_arrivalDemo && !_hasLiveLocation) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Location unavailable. Enable location to confirm arrival.'),
      ));
      return;
    }
    final where = _stage == ActiveRideStage.onTrip ? 'stop' : 'pickup';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Move within 100 m of the $where to arrive.'),
        backgroundColor: _ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _onArrivedTap() async {
    if (!_nearArrivalTarget) {
      _blockedArrival();
      return;
    }
    if (_stage == ActiveRideStage.headingToPickup) {
      _confirmPickupArrival();
      return;
    }
    if (_stage == ActiveRideStage.onTrip &&
        !_paidStopWait &&
        _stopCursor < widget.stopAddresses.length) {
      _paidStopWait = true;
      _waitSeconds = 0;
      _startWaitTimer();
      await _rideLifecycle.persistNow();
      if (mounted) setState(() {});
    }
  }

  Future<void> _confirmPickupArrival() async {
    if (_stageTransitioning ||
        !mounted ||
        _rideLifecycle.terminal ||
        _stage != ActiveRideStage.headingToPickup) {
      return;
    }

    _stageTransitioning = true;
    if (!await _rideLifecycle.transitionTo(ActiveRideStage.waitingForRider)) {
      _stageTransitioning = false;
      return;
    }

    _waitSeconds = 0;
    _routeLoading = false;
    _startWaitTimer();
    await _rideLifecycle.persistNow();
    unawaited(
      _realtime.sendSignal(
        tripId: widget.offerId,
        kind: DriverRealtimeKind.driverArrived,
        message: 'Your driver has arrived at the pickup point.',
      ),
    );
    if (mounted) setState(() {});
    _unlockStageAfterFrame();
  }

  void _onNavigationChanged() {
    if (!mounted || _stageTransitioning) return;
    final route = _navigation.route;
    final status = _navigation.status;
    final pointsChanged = route != null &&
        route.points.length >= 2 &&
        !identical(_roadGeoPoints, route.points);
    final mappedRoute = route;
    if (!pointsChanged && status == _locationStatus) return;
    setState(() {
      if (pointsChanged && mappedRoute != null) {
        _roadGeoPoints = mappedRoute.points;
        _roadRoutePoints = mappedRoute.latLngPoints;
        _routeDistanceMeters = mappedRoute.distanceMeters;
        _routeDurationSeconds = mappedRoute.durationSeconds;
      }
      _routeLoading = status != null;
      _locationStatus = status;
    });
  }

  Future<void> _prepareDriverVehicleMarker() async {
    final icon = await MoveraVehicleMarker.createIcon();
    if (!mounted) return;
    setState(() => _driverVehicleIcon = icon);
  }

  Set<Polyline> get _polylines {
    if (_roadRoutePoints.length < 2) {
      if (_cachedPolylines.isEmpty) return _cachedPolylines;
      _cachedPolylines = <Polyline>{};
      return _cachedPolylines;
    }
    if (identical(_cachedPolylinePoints, _roadRoutePoints) &&
        _cachedPolylines.isNotEmpty) {
      return _cachedPolylines;
    }
    _cachedPolylinePoints = _roadRoutePoints;
    _cachedPolylines = {
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
    return _cachedPolylines;
  }

  Future<void> _startLiveLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;

      await _applyDriverPosition(position, forceRoute: true);

      _positionSubscription?.cancel();
      _positionSubscription = _locationService
          .watchPosition(distanceFilterMeters: kIsWeb ? 20 : 8)
          .listen(
        (position) {
          _applyDriverPosition(position);
        },
        onError: (Object error) {
          if (!mounted) return;
          _navigation.keepLastKnown(status: 'Location updating…');
          setState(() {
            _locationStatus = 'Location updating…';
          });
        },
      );
    } catch (_) {
      if (!mounted) return;
      _navigation.keepLastKnown(status: 'Location updating…');
      setState(() {
        _hasLiveLocation = false;
        _locationStatus = 'Location updating…';
      });
      unawaited(_refreshRoadRoute(force: true));
    }
  }

  Future<void> _applyDriverPosition(
    DriverLocation location, {
    bool forceRoute = false,
  }) async {
    if(!location.point.latitude.isFinite || !location.point.longitude.isFinite || location.point.latitude.abs()>90 || location.point.longitude.abs()>180) return;
    final next = location.point.toLatLng();
    if (!mounted) return;

    if (!forceRoute &&
        kIsWeb &&
        _lastGpsAppliedAt != null &&
        DateTime.now().difference(_lastGpsAppliedAt!) <
            const Duration(milliseconds: 800)) {
      _vehicle.moveTo(next, _navigation.snapshot.headingDegrees);
      return;
    }
    _lastGpsAppliedAt = DateTime.now();

    _navigation.setVehicle(location);
    _driverPosition = next;
    _hasLiveLocation = true;
    _locationStatus = _navigation.status;
    _vehicle.moveTo(next, _navigation.snapshot.headingDegrees);

    final lastSnap = _lastSnapshotAt;
    if (lastSnap == null ||
        DateTime.now().difference(lastSnap) > const Duration(minutes: 2)) {
      _lastSnapshotAt = DateTime.now();
      _rideLifecycle.persistNow();
    }

    if (_stage != ActiveRideStage.waitingForRider && !_paidStopWait) {
      await _refreshRoadRoute(force: forceRoute);
      await _followVehicle();
    }

    if (_stage == ActiveRideStage.onTrip) {
      _maybeScheduleOnTripRadarDemoOffer();
    }
  }

  bool get _allowExternalRouting {
    return !WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');
  }

  Future<void> _refreshRoadRoute({bool force = false}) async {
    if (_stage == ActiveRideStage.waitingForRider || _paidStopWait) return;
    if (!_allowExternalRouting) return;

    final target = _routeTarget;
    if (target == null) {
      setState(() {
        _roadGeoPoints = [];
        _roadRoutePoints = [];
        _routeDistanceMeters = null;
        _routeDurationSeconds = null;
        _locationStatus = 'Stop location unavailable';
      });
      return;
    }
    await _navigation.ensureRoute(
      origin: GeoPointMaps.fromLatLng(_driverPosition),
      destination: GeoPointMaps.fromLatLng(target),
      force: force,
    );
    if (!mounted) return;

    final route = _navigation.route;
    setState(() {
      if (route != null && route.points.length >= 2) {
        _roadGeoPoints = route.points;
        _roadRoutePoints = route.latLngPoints;
        _routeDistanceMeters = route.distanceMeters;
        _routeDurationSeconds = route.durationSeconds;
      }
      _routeLoading = _navigation.status != null;
      _locationStatus = _navigation.status;
    });
  }

  Future<void> _followVehicle({bool force = false}) async {
    if (!_allowExternalRouting) return;
    if (!force && !_navigation.followCamera) return;
    final controller = _mapController;
    if (controller == null) return;
    final now = DateTime.now();
    if (!force &&
        _lastCameraFollowAt != null &&
        now.difference(_lastCameraFollowAt!) < const Duration(milliseconds: 900)) {
      return;
    }
    _lastCameraFollowAt = now;
    _cameraProgrammatic = true;
    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _vehicle.current.position,
            zoom: 16.8,
            bearing: _vehicle.current.headingDegrees,
            tilt: 30,
          ),
        ),
      );
    } catch (_) {}
    _cameraProgrammatic = false;
  }

  void _onCameraMove(CameraPosition position) {
    if (_cameraProgrammatic) return;
    _navigation.pauseFollow();
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
        : <LatLng>[_driverPosition, if (_routeTarget != null) _routeTarget!];
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

    if ((maxLat - minLat).abs() < 0.0004) {
      minLat -= 0.003;
      maxLat += 0.003;
    }
    if ((maxLng - minLng).abs() < 0.0004) {
      minLng -= 0.003;
      maxLng += 0.003;
    }

    try {
      final insets = MapOverlayInsets.forActiveRide(
        safeTop: MediaQuery.paddingOf(context).top,
        collapsedSheet: MoveraSheetMetrics.activeCollapsedHeight +
            MediaQuery.paddingOf(context).bottom,
      );
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          insets.boundsPadding,
        ),
      );
    } catch (_) {}
  }

  Future<void> _advanceRide() async {
    if (_stageTransitioning || !mounted || _rideLifecycle.terminal) return;

    _stageTransitioning = true;

    switch (_stage) {
      case ActiveRideStage.headingToPickup:
        _stageTransitioning = false;
        return;

      case ActiveRideStage.waitingForRider:
        if (!await _rideLifecycle.transitionTo(ActiveRideStage.onTrip)) {
          _stageTransitioning = false;
          return;
        }
        _waitTimer?.cancel();
        _paidStopWait = false;
        _stopCursor = 0;
        _nextTripRadarDemoTimer?.cancel();
        _nextTripRadarMatchTimer?.cancel();
        _onTripStartedAt = DateTime.now();
        await _rideLifecycle.persistNow();
        _onTripRadarState = _OnTripRadarState.scanning;
        _nextTripRadarOffer = null;
        if (mounted) setState(() {});
        _maybeScheduleOnTripRadarDemoOffer();
        _unlockStageAfterFrame();
        unawaited(_refreshOnTripRoute());
        return;

      case ActiveRideStage.onTrip:
        if (_paidStopWait) {
          _paidStopWait = false;
          _waitTimer?.cancel();
          _stopCursor += 1;
          await _rideLifecycle.persistNow();
          _stageTransitioning = false;
          if (mounted) setState(() {});
          unawaited(_refreshOnTripRoute());
          return;
        }
        if (_stopCursor < widget.stopAddresses.length) {
          _stageTransitioning = false;
          return;
        }
        if (_tripEndedTooQuickly) {
          _stageTransitioning = false;
          unawaited(_askBeforeShortFinish());
          return;
        }
        unawaited(_completeCurrentTrip());
        return;
    }
  }

  bool get _tripEndedTooQuickly {
    final started = _onTripStartedAt;
    if (started == null) return false;
    return DateTime.now().difference(started) < const Duration(seconds: 90);
  }

  Future<void> _askBeforeShortFinish() async {
    final finish = await showMoveraModalSheet<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.32),
      heightFactor: 0.5,
      builder: (sheetContext) {
        return MoveraModalSheet(
          key: const ValueKey<String>('short-trip-finish-sheet'),
          heightFactor: 0.5,
          color: Colors.white,
          radius: 28,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This ride just started',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                const Expanded(
                  child: Text(
                    'Very little time has passed since pickup. Go back if the rider is still with you, or confirm that the trip is finished.',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext, false),
                    style: FilledButton.styleFrom(
                      elevation: 0,
                      backgroundColor: _ink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Go back to the ride',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ink,
                      side: const BorderSide(color: Color(0xFFD5DCDF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Confirm finish',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (finish != true || !mounted || _stage != ActiveRideStage.onTrip) return;
    unawaited(_completeCurrentTrip());
  }

  Future<void> _completeCurrentTrip() async {
    if (_completionInFlight || !mounted || _rideLifecycle.terminal) return;
    _completionInFlight = true;
    _stageTransitioning = true;
    final offer = _nextTripRadarOffer;
    final queuedNext = _onTripRadarState == _OnTripRadarState.secured && offer != null;
    final next = queuedNext ? _snapshotForOffer(offer) : null;
    try {
      await CompletionJournal(active: widget.activeRideRepository ?? MemoryActiveRideRepository()).finish(
        _waybills.current ?? _buildCurrentWaybill(), next: next);
      if (!mounted) return;
      if (!await _rideLifecycle.complete(clearSnapshot: false)) {
        _completionInFlight = false; _stageTransitioning = false; return;
      }
    } catch (error, stack) {
      DriverLog.error('Trip completion journal failed', error, stack);
      _completionInFlight = false; _stageTransitioning = false;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not finish saving this trip. Retry completion; the receipt will not duplicate.')));
      return;
    }
    _waitTimer?.cancel();
    _nextTripRadarDemoTimer?.cancel();
    _nextTripRadarMatchTimer?.cancel();
    _waybills.completeCurrent();
    final nextRide = queuedNext
        ? AcceptRide(
            offerId: offer.id,
            riderName: offer.riderName,
            riderRating: offer.rating,
            fare: offer.fare,
            category: offer.category,
            matchedVia: 'Demo Radar',
            pickupAddress: offer.pickup,
            pickupArea: offer.pickup.split(',').last.trim(),
            dropoffAddress: offer.dropoff,
            pickupPosition: offer.pickupPosition,
            dropoffPosition: offer.dropoffPosition,
            locationRepository: widget.locationRepository,
            routeRepository: widget.routeRepository,
            waybillRepository: _waybills,
            sessionController: widget.sessionController,
            activeRideRepository: widget.activeRideRepository,
            destinationModeActive: widget.destinationModeActive,
            destinationAddress: widget.destinationAddress,
            destinationPosition: widget.destinationPosition,
          )
        : null;
    Navigator.of(context).pushReplacement(
      BottomToTopTransition(
        DriverRideCompleted(
          waybillRepository: _waybills,
          sessionController: widget.sessionController,
          activeRideRepository: widget.activeRideRepository,
          nextRide: nextRide,
        ),
      ),
    );
  }

  PersistedActiveRide _snapshotForOffer(_NextTripRadarOffer offer) => PersistedActiveRide(
    tripId: offer.id, stage: ActiveRideStage.headingToPickup, riderName: offer.riderName,
    riderRating: offer.rating, fare: offer.fare, category: offer.category, matchedVia: 'Demo Radar',
    pickupAddress: offer.pickup, dropoffAddress: offer.dropoff,
    pickupLat: offer.pickupPosition.latitude, pickupLng: offer.pickupPosition.longitude,
    dropoffLat: offer.dropoffPosition.latitude, dropoffLng: offer.dropoffPosition.longitude);

  void _unlockStageAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _stageTransitioning = false;
    });
  }

  void _setMapGesturesBlocked(bool value) {
    if (!mounted || _blockMapGestures == value) return;
    setState(() {
      _blockMapGestures = value;
    });
  }

  Widget _mapOverlay({required Widget child}) {
    return PointerInterceptor(
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _setMapGesturesBlocked(true),
        onPointerUp: (_) => _setMapGesturesBlocked(false),
        onPointerCancel: (_) => _setMapGesturesBlocked(false),
        child: child,
      ),
    );
  }

  void _onRideSheetPointerDown(PointerDownEvent event) {
    _ridePointerActive = true;
    _ridePointerLastY = event.position.dy;
    _ridePointerLastMs = DateTime.now().millisecondsSinceEpoch;
    _ridePointerVelocity = 0;
    _snapSheet.stopSpring();
    _setMapGesturesBlocked(true);
  }

  void _onRideSheetPointerMove(PointerEvent event) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_ridePointerLastMs != 0) {
      final dt = math.max(1, now - _ridePointerLastMs);
      _ridePointerVelocity =
          (event.position.dy - _ridePointerLastY) / dt * 1000;
    }
    _ridePointerLastY = event.position.dy;
    _ridePointerLastMs = now;
  }

  void _onRideSheetPointerEnd(PointerEvent event) {
    _onRideSheetPointerMove(event);
    _ridePointerActive = false;
    _scheduleRideSheetPositionGuard(
      delay: const Duration(milliseconds: 460),
    );
  }

  void _scheduleRideSheetPositionGuard({
    Duration delay = const Duration(milliseconds: 180),
  }) {
    _rideSheetPositionGuardTimer?.cancel();
    _rideSheetPositionGuardTimer = Timer(delay, () {
      if (!mounted ||
          _ridePointerActive ||
          !_ridePanelController.isAttached) {
        return;
      }

      final viewport = MediaQuery.sizeOf(context).height;
      final collapsed = MoveraSheetMetrics.activeCollapsedHeight +
          MediaQuery.paddingOf(context).bottom;
      final snap = MoveraSheetMetrics.snapPoint(
        viewportHeight: viewport,
        collapsed: collapsed,
      );
      final position = _ridePanelController.panelPosition.clamp(0.0, 1.0);
      final nearestDistance = math.min(
        position.abs(),
        math.min((position - snap).abs(), (1 - position).abs()),
      );
      if (nearestDistance <= 0.025) return;
      unawaited(_snapRideSheet(velocity: 0));
    });
  }

  double _rideExpandedHeight(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context).height;
    final collapsed = MoveraSheetMetrics.activeCollapsedHeight +
        MediaQuery.paddingOf(context).bottom;
    final bannerReserve = MediaQuery.paddingOf(context).top + 130;
    return math.min(
      MoveraSheetMetrics.expandedHeight(viewport),
      math.max(collapsed + 160, viewport - bannerReserve),
    );
  }

  Future<void> _snapRideSheet({double? velocity}) async {
    if (!_ridePanelController.isAttached) return;
    final viewport = MediaQuery.sizeOf(context).height;
    final collapsed = MoveraSheetMetrics.activeCollapsedHeight +
        MediaQuery.paddingOf(context).bottom;
    _snapSheet.rangePx = _rideExpandedHeight(context) - collapsed;
    await _snapSheet.snapToNearest(
      snapPoint: MoveraSheetMetrics.snapPoint(
        viewportHeight: viewport,
        collapsed: collapsed,
      ),
      velocityPxPerSec: velocity ?? _ridePointerVelocity,
    );
  }

  Future<void> _refreshOnTripRoute({bool fitCamera = false}) async {
    await _refreshRoadRoute(force: true);
    if (!mounted || _stage != ActiveRideStage.onTrip) return;
    if (fitCamera) {
      await _fitRoute();
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
    if (_onTripRadarState == _OnTripRadarState.stopped) return;
    _nextTripRadarDemoTimer?.cancel();
    _nextTripRadarMatchTimer?.cancel();

    if (!mounted || _stage != ActiveRideStage.onTrip) return;

    setState(() {
      _onTripRadarState = _OnTripRadarState.scanning;
      _nextTripRadarOffer = null;
    });

    _maybeScheduleOnTripRadarDemoOffer();
  }

  void _toggleOnTripRadar() {
    if (_stage != ActiveRideStage.onTrip) return;
    if (_onTripRadarState == _OnTripRadarState.secured) return;
    if (_onTripRadarOn) {
      _stopOnTripRadar();
      return;
    }
    _onTripRadarDeclined = false;
    setState(() => _onTripRadarState = _OnTripRadarState.off);
    _startOnTripRadar();
  }

  bool get _onTripRadarOn =>
      _onTripRadarState == _OnTripRadarState.scanning ||
      _onTripRadarState == _OnTripRadarState.offerAvailable ||
      _onTripRadarState == _OnTripRadarState.matching ||
      _onTripRadarState == _OnTripRadarState.secured;

  bool _dropoffFollowsDestination(LatLng dropoff) {
    if (!widget.destinationModeActive) return true;
    final destination = widget.destinationPosition;
    if (destination == null) return true;

    final latitudeRadians = _driverPosition.latitude * math.pi / 180;
    final longitudeScale = math.cos(latitudeRadians);
    final destinationX =
        (destination.longitude - _driverPosition.longitude) * longitudeScale;
    final destinationY = destination.latitude - _driverPosition.latitude;
    final offerX = (dropoff.longitude - _driverPosition.longitude) * longitudeScale;
    final offerY = dropoff.latitude - _driverPosition.latitude;
    final destinationLength = math.sqrt(
      destinationX * destinationX + destinationY * destinationY,
    );
    final offerLength = math.sqrt(offerX * offerX + offerY * offerY);
    if (destinationLength == 0 || offerLength == 0) return true;
    final cosine = (destinationX * offerX + destinationY * offerY) /
        (destinationLength * offerLength);
    return cosine >= 0.45;
  }

  _NextTripRadarOffer _onTripRadarOfferForDestination() {
    if (!widget.destinationModeActive) return _demoNextTripOffer;
    final destination = widget.destinationPosition;
    if (destination == null) return _demoNextTripOffer;
    final address = widget.destinationAddress?.trim();
    return _NextTripRadarOffer(
      id: 'on-trip-radar-on-your-way',
      category: _demoNextTripOffer.category,
      fare: _demoNextTripOffer.fare,
      rating: _demoNextTripOffer.rating,
      pickupMinutes: _demoNextTripOffer.pickupMinutes,
      tripMinutes: _demoNextTripOffer.tripMinutes,
      riderName: _demoNextTripOffer.riderName,
      pickup: _demoNextTripOffer.pickup,
      dropoff: address == null || address.isEmpty
          ? 'Along your destination'
          : address,
      pickupPosition: _demoNextTripOffer.pickupPosition,
      dropoffPosition: destination,
    );
  }

  void _stopOnTripRadar() {
    _nextTripRadarDemoTimer?.cancel();
    _nextTripRadarMatchTimer?.cancel();
    _nextTripOfferExpiry?.cancel();
    if (!mounted || _stage != ActiveRideStage.onTrip) return;
    if (_onTripRadarState == _OnTripRadarState.secured) return;
    setState(() {
      _onTripRadarState = _OnTripRadarState.stopped;
      _nextTripRadarOffer = null;
    });
  }

  void _maybeScheduleOnTripRadarDemoOffer() {
    if (!mounted ||
        _stage != ActiveRideStage.onTrip ||
        _onTripRadarState != _OnTripRadarState.scanning ||
        _onTripRadarDeclined ||
        (_nextTripRadarDemoTimer?.isActive ?? false)) {
      return;
    }

    // Offers are explicitly simulated. A future live adapter must pass the freshness gate.
    if (_hasLiveLocation) {
      final metersToDropoff =
          GeoPointMaps.fromLatLng(_driverPosition).distanceMetersTo(
        GeoPointMaps.fromLatLng(widget.dropoffPosition),
      );
      if (metersToDropoff > _nextTripRadarRadiusMeters) return;
    }

    _nextTripRadarDemoTimer = Timer(
      const Duration(milliseconds: 2200),
      () {
        if (!mounted ||
            _stage != ActiveRideStage.onTrip ||
            _onTripRadarState != _OnTripRadarState.scanning) {
          return;
        }

        setState(() {
          final offer = _onTripRadarOfferForDestination();
          if (!_dropoffFollowsDestination(offer.dropoffPosition)) return;
          _nextTripRadarOffer = offer;
          _onTripRadarState = _OnTripRadarState.offerAvailable;
        });
        _armOnTripOfferExpiry();
        _hideRideSheetForOffer();
      },
    );
  }

  void _armOnTripOfferExpiry() {
    _nextTripOfferExpiry?.cancel();
    if (_onTripRadarState != _OnTripRadarState.offerAvailable) return;
    _nextTripOfferExpiry = Timer(_onTripOfferLifetime, () {
      if (!mounted || _onTripRadarState != _OnTripRadarState.offerAvailable) {
        return;
      }
      _denyNextTripRadar();
    });
  }

  void _hideRideSheetForOffer() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_ridePanelController.isAttached) return;
      if (_onTripRadarState == _OnTripRadarState.offerAvailable) {
        _ridePanelController.close();
      }
    });
  }

  void _restoreRideSheet() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_ridePanelController.isAttached) return;
      _ridePanelController.open();
    });
  }

  bool get _incomingOfferOpen =>
      _stage == ActiveRideStage.onTrip &&
      _onTripRadarState == _OnTripRadarState.offerAvailable &&
      _nextTripRadarOffer != null;

  void _acceptNextTripRadar() {
    final offer = _nextTripRadarOffer;
    if (offer == null || _stage != ActiveRideStage.onTrip) return;
    if (_onTripRadarState == _OnTripRadarState.secured ||
        _onTripRadarState == _OnTripRadarState.matching) {
      return;
    }
    setState(() => _onTripRadarState = _OnTripRadarState.matching);
    _nextTripOfferExpiry?.cancel();
    _restoreRideSheet();
    _nextTripRadarMatchTimer?.cancel();
    _nextTripRadarMatchTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted || _stage != ActiveRideStage.onTrip) return;
      setState(() => _onTripRadarState = _OnTripRadarState.secured);
      _waybills.secureNext(_buildNextWaybill(offer));
      _rideLifecycle.persistNow();
    });
  }

  void _denyNextTripRadar() {
    if (_stage != ActiveRideStage.onTrip) return;
    if (_onTripRadarState == _OnTripRadarState.secured ||
        _onTripRadarState == _OnTripRadarState.matching) {
      return;
    }
    _nextTripRadarDemoTimer?.cancel();
    _nextTripRadarMatchTimer?.cancel();
    _nextTripOfferExpiry?.cancel();
    setState(() {
      _onTripRadarDeclined = true;
      _nextTripRadarOffer = null;
      _onTripRadarState = _OnTripRadarState.scanning;
    });
    _restoreRideSheet();
  }

  Widget _buildIncomingRideCard() {
    final offer = _nextTripRadarOffer;
    if (offer == null) return const SizedBox.shrink();
    const alertCoral = Color(0xFFFF765C);

    return Material(
      key: const ValueKey<String>('on-trip-radar-offer-button'),
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: alertCoral.withOpacity(0.55), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: alertCoral.withOpacity(0.12),
              blurRadius: 22,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: const Color(0xFF11181C).withOpacity(0.14),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9EEF1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    offer.category,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (widget.destinationModeActive) ...[
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: _ink,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Text(
                      'On your way',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 7),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(
                      color: alertCoral.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Text(
                      'After this drop-off',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFB84F3D),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    offer.fare,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 30,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.9,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const MoveraLineIcon(
                  mark: MoveraMark.star,
                  color: Color(0xFFD7A02C),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  offer.rating.toStringAsFixed(2),
                  style: const TextStyle(
                    color: Color(0xFF6F7B82),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              'Available after your current drop-off',
              style: TextStyle(
                color: _muted,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              key: ValueKey<String>('on-trip-offer-${offer.id}'),
              tween: Tween<double>(begin: 1, end: 0),
              duration: _onTripOfferLifetime,
              builder: (context, remaining, _) {
                final seconds =
                    (remaining * (_onTripOfferLifetime.inMilliseconds / 1000))
                        .ceil();
                return Column(
                  children: [
                    Row(
                      children: [
                        const MoveraLineIcon(
                          mark: MoveraMark.timer,
                          color: _ink,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Exclusive offer · ${seconds}s',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'On this ride',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF8A9499),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        value: remaining,
                        backgroundColor: const Color(0xFFF0E8E5),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(alertCoral),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE4E8EA)),
            const SizedBox(height: 11),
            _offerLocationRow(
              color: const Color(0xFF215277),
              title: '${offer.pickupMinutes} min away',
              subtitle: offer.pickup,
            ),
            const SizedBox(height: 9),
            _offerLocationRow(
              color: _ink,
              title: '${offer.tripMinutes} min trip',
              subtitle: offer.dropoff,
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey<String>('on-trip-radar-deny'),
                    onPressed: _denyNextTripRadar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ink,
                      side: const BorderSide(color: Color(0xFFD5DCDF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      minimumSize: const Size(0, 42),
                    ),
                    child: const Text(
                      'Deny',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey<String>('on-trip-radar-match-next'),
                    onPressed: _acceptNextTripRadar,
                    style: FilledButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF252E3A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      minimumSize: const Size(0, 42),
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _offerLocationRow({
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2.5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecuredNextTripDetails() {
    final offer = _nextTripRadarOffer;
    if (_stage != ActiveRideStage.onTrip ||
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
                  final record = _waybills.next;
                  if (record != null) {
                    showMoveraWaybillSheet(
                      context,
                      record,
                      title: 'Next trip waybill',
                    );
                  }
                },
                icon: const MoveraLineIcon(
                  mark: MoveraMark.receipt,
                  size: 15,
                  color: Color(0xFF1C242C),
                ),
                label: const Text('Waybill'),
                style: TextButton.styleFrom(
                  foregroundColor: _ink,
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

  void _startWaitTimer() {
    _waitTimer?.cancel();
    _waitTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_countingWait) return;
      setState(() => _waitSeconds++);
    });
  }

  String get _waitLabel {
    final minutes = _waitSeconds ~/ 60;
    final seconds = (_waitSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _stopWord(int number) {
    return switch (number) {
      1 => 'first',
      2 => 'second',
      3 => 'third',
      4 => 'fourth',
      5 => 'fifth',
      _ => '$number',
    };
  }

  String get _slideLabel {
    if (_paidStopWait) {
      final next = _stopCursor + 2;
      if (next <= widget.stopAddresses.length) {
        return 'Slide to ${_stopWord(next)} stop';
      }
      return 'Slide to drop-off';
    }
    return switch (_stage) {
      ActiveRideStage.headingToPickup => 'Slide to arrive at pickup',
      ActiveRideStage.waitingForRider => widget.stopAddresses.isEmpty
          ? 'Slide to start trip'
          : 'Slide to start first stop',
      ActiveRideStage.onTrip => _stopCursor < widget.stopAddresses.length
          ? 'Slide to arrive at the stop'
          : 'Slide to complete trip',
    };
  }

  String get _slideConfirmedLabel {
    if (_paidStopWait) {
      return _stopCursor + 1 < widget.stopAddresses.length
          ? 'Next stop'
          : 'To drop-off';
    }
    return switch (_stage) {
      ActiveRideStage.headingToPickup => 'Waiting',
      ActiveRideStage.waitingForRider => 'Trip started',
      ActiveRideStage.onTrip => 'Trip completed',
    };
  }

  void _openWaitingTime() {
    if (!_countingWait) return;
    showWaitingTimeSheet(
      context,
      readSeconds: () => _waitSeconds,
      fullyPaid: _paidStopWait,
      onNoShow: _paidStopWait
          ? null
          : () {
              if (_waitSeconds < 300 || !mounted) return;
              _confirmCancellationReason(_noShowReason);
            },
    );
  }

  String get _title {
    switch (_stage) {
      case ActiveRideStage.headingToPickup:
        return 'Heading to pickup';
      case ActiveRideStage.waitingForRider:
        return 'Waiting for rider';
      case ActiveRideStage.onTrip:
        return 'Dropping off ${widget.riderName}';
    }
  }

  String get _subtitle {
    switch (_stage) {
      case ActiveRideStage.headingToPickup:
        return '${widget.riderName} is waiting at ${widget.pickupAddress}';
      case ActiveRideStage.waitingForRider:
        return _riderOnTheWay
            ? '${widget.riderName} says: I’m on the way'
            : '${widget.riderName} has been notified and will be out shortly';
      case ActiveRideStage.onTrip:
        return 'On the way to ${widget.dropoffAddress}';
    }
  }

  String get _compactDockDetail =>
      _stage == ActiveRideStage.onTrip
          ? widget.dropoffAddress
          : widget.pickupAddress;

  String get _onwardAddress {
    if (_stopCursor < widget.stopAddresses.length &&
        (_stage == ActiveRideStage.onTrip ||
            _stage == ActiveRideStage.waitingForRider)) {
      return widget.stopAddresses[_stopCursor];
    }
    return widget.dropoffAddress;
  }

  String get _nextStopEyebrow {
    switch (_stage) {
      case ActiveRideStage.headingToPickup:
        return 'NEXT STOP';
      case ActiveRideStage.waitingForRider:
        return 'UP NEXT';
      case ActiveRideStage.onTrip:
        return widget.stopAddresses.isEmpty ? 'DROP-OFF' : 'NEXT STOP';
    }
  }

  String get _nextStopAddress {
    switch (_stage) {
      case ActiveRideStage.headingToPickup:
        return widget.pickupAddress;
      case ActiveRideStage.waitingForRider:
      case ActiveRideStage.onTrip:
        return _onwardAddress;
    }
  }

  String get _nextStopDetail {
    switch (_stage) {
      case ActiveRideStage.headingToPickup:
        return 'Pick up ${widget.riderName}';
      case ActiveRideStage.waitingForRider:
        return _riderOnTheWay
            ? '${widget.riderName} is on the way'
            : 'Hold for ${widget.riderName}';
      case ActiveRideStage.onTrip:
        if (widget.stopAddresses.isEmpty) return widget.riderName;
        if (widget.stopAddresses.length == 1) return 'Then drop-off';
        return 'Stop 1 of ${widget.stopAddresses.length}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutViewport(
      child: PopScope(
        canPop: false,
        child: Scaffold(
      backgroundColor: _canvas,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = constraints.maxHeight;
          final collapsed = MoveraSheetMetrics.activeCollapsedHeight +
              MediaQuery.paddingOf(context).bottom;
          final safeTop = MediaQuery.paddingOf(context).top;
          final bannerReserve = safeTop + 130;
          final expanded = math.min(
            MoveraSheetMetrics.expandedHeight(viewport),
            math.max(collapsed + 160, viewport - bannerReserve),
          );
          final snap = MoveraSheetMetrics.snapPoint(
            viewportHeight: viewport,
            collapsed: collapsed,
          );

          final offerOpen = _incomingOfferOpen;
          return Stack(
            children: [
              SlidingUpPanel(
            controller: _ridePanelController,
            minHeight: offerOpen ? 0 : collapsed,
            maxHeight: offerOpen ? 1 : expanded,
            snapPoint: snap,
            panelSnapping: false,
            defaultPanelState: PanelState.OPEN,
            isDraggable: !offerOpen,
            color: Colors.transparent,
            boxShadow: const [],
            backdropEnabled: false,
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            onPanelSlide: (pos) {
              _ridePanelPosition.value = pos;
              if (!_ridePointerActive) {
                _scheduleRideSheetPositionGuard();
              }
            },
            onPanelOpened: () {
              _rideSheetPositionGuardTimer?.cancel();
              _ridePanelPosition.value = 1;
            },
            onPanelClosed: () {
              _rideSheetPositionGuardTimer?.cancel();
              _ridePanelPosition.value = 0;
            },
            panel: offerOpen
                ? const SizedBox.shrink()
                : _mapOverlay(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: _onRideSheetPointerDown,
                onPointerMove: _onRideSheetPointerMove,
                onPointerUp: _onRideSheetPointerEnd,
                onPointerCancel: _onRideSheetPointerEnd,
                child: _buildRidePanel(),
              ),
            ),
            body: Stack(
              fit: StackFit.expand,
              children: [
                AbsorbPointer(
                  absorbing: _blockMapGestures,
                  child: _ThrottledVehicleMap(
                    key: const ValueKey<String>('active-ride-throttled-map'),
                    vehicle: _vehicle,
                    vehicleIcon: _driverVehicleIcon,
                    stage: _stage,
                    pickupPosition: widget.pickupPosition,
                    dropoffPosition: widget.dropoffPosition,
                    pickupAddress: widget.pickupAddress,
                    dropoffAddress: widget.dropoffAddress,
                    polylines: _polylines,
                    padding: MapOverlayInsets.forActiveRide(
                      safeTop: safeTop,
                      collapsedSheet: collapsed,
                    ).edgeInsets,
                    blockGestures: _blockMapGestures,
                    initialTarget: _driverPosition,
                    onCameraMove: _onCameraMove,
                    onMapCreated: (controller) {
                      final firstCreate = _mapController == null;
                      _mapController = controller;
                      if (!firstCreate) return;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) unawaited(_fitRoute());
                      });
                    },
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: _mapOverlay(
                    child: ListenableBuilder(
                      listenable: _navigation,
                      builder: (context, _) {
                        final banner = _navigation.snapshot.banner;
                        if (banner == null) {
                          return _buildNavigationCard();
                        }
                        return NavigationInstructionBanner(
                          banner: banner,
                          etaLabel: _stage == ActiveRideStage.waitingForRider
                              ? _waitLabel
                              : _routeEtaText,
                          eyebrow: _nextStopEyebrow,
                          detail: _nextStopDetail,
                          address: _nextStopAddress,
                          radarSwitch: _stage == ActiveRideStage.onTrip,
                          radarOn: _onTripRadarOn,
                          onRadarToggle: _toggleOnTripRadar,
                          waitSeconds: _stage == ActiveRideStage.waitingForRider
                              ? _waitSeconds
                              : null,
                          onWaitTap: _openWaitingTime,
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  key: const ValueKey<String>('active-ride-map-controls'),
                  right: 14,
                  bottom: collapsed + 16,
                  child: _mapOverlay(child: _buildMapControls()),
                ),
              ],
            ),
              ),
              if (offerOpen)
                Positioned(
                  key: const ValueKey<String>('on-trip-radar-layer'),
                  left: 12,
                  right: 12,
                  bottom: MediaQuery.paddingOf(context).bottom + 12,
                  child: _buildIncomingRideCard(),
                ),
            ],
          );
        },
      ),
    ),
    ),
    );
  }

  Widget _buildNavigationCard() {
    final onTrip = _stage == ActiveRideStage.onTrip;
    final waiting = _stage == ActiveRideStage.waitingForRider;
    final title = waiting
        ? 'Pickup'
        : onTrip
            ? 'Drop-off'
            : 'Heading to pickup';

    return NavigationInstructionBanner(
      etaLabel: waiting ? _waitLabel : _routeEtaText,
      eyebrow: _nextStopEyebrow,
      title: title,
      detail: _nextStopDetail,
      address: _nextStopAddress,
      icon: waiting
          ? Icons.location_on_outlined
          : onTrip
              ? Icons.flag_outlined
              : Icons.near_me_outlined,
      radarSwitch: onTrip,
      radarOn: _onTripRadarOn,
      onRadarToggle: _toggleOnTripRadar,
      waitSeconds: waiting ? _waitSeconds : null,
      onWaitTap: _openWaitingTime,
    );
  }

  bool get _freshRadarLocation => _hasLiveLocation && hasFreshLocation(
    GeoPointMaps.fromLatLng(_driverPosition), _lastGpsAppliedAt, DateTime.now());

  Widget _buildMapControls() {
    return Column(
      children: [
        Text(_freshRadarLocation ? 'Demo Radar' : 'Demo Radar — live location unavailable/stale', style: const TextStyle(fontSize: 10)),
        _mapCircleButton(
          icon: Icons.my_location_rounded,
          onTap: () {
            _navigation.resumeFollow();
            unawaited(_followVehicle(force: true));
          },
        ),
        const SizedBox(height: 9),
        _mapCircleButton(
          icon: Icons.shield_outlined,
          accent: _green,
          onTap: () => showSafetyToolKitSheet(context),
        ),
        const SizedBox(height: 9),
        const PreviewUnavailable(label: 'Map layers', child: Icon(Icons.layers_outlined, color: Colors.grey)),
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
    return ValueListenableBuilder<double>(
      valueListenable: _ridePanelPosition,
      builder: (context, pos, _) {
        final compact = pos < 0.14;
        return Container(
          key: const ValueKey<String>('active-ride-panel'),
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8DEDF),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
                KeyedSubtree(
                  key: ValueKey<String>('active-ride-panel-${_stage.name}'),
                  child: const SizedBox.shrink(),
                ),
                if (compact)
                  CompactTripDock(
                    key: const ValueKey<String>('active-ride-compact-dock'),
                    pickupAddress: widget.pickupAddress,
                    dropoffAddress: widget.dropoffAddress,
                    stopAddresses: widget.stopAddresses,
                    etaLabel: _countingWait ? _waitLabel : _routeEtaText,
                    stageLabel: switch (_stage) {
                      ActiveRideStage.headingToPickup => 'PICKUP',
                      ActiveRideStage.waitingForRider => 'WAITING',
                      ActiveRideStage.onTrip =>
                        _paidStopWait ? 'STOP WAIT' : 'ON TRIP',
                    },
                    onArrived: _arrivalTarget != null ? _onArrivedTap : null,
                    arrivedEnabled: _nearArrivalTarget,
                    onArrivedBlocked: _blockedArrival,
                    riderReply: _riderOnTheWay ? 'RIDER ON THE WAY' : null,
                    onWaitTap: _countingWait ? _openWaitingTime : null,
                    riderName: widget.riderName,
                    onCall: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Phone integration will call the rider.',
                          ),
                          backgroundColor: _ink,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      );
                    },
                    onMessage: () {
                      Navigator.push(
                        context,
                        BottomToTopTransition(const Chat()),
                      );
                    },
                  )
                else
                  Expanded(
                    child: SingleChildScrollView(
                      key: const PageStorageKey<String>('active-ride-scroll'),
                      padding: const EdgeInsets.fromLTRB(16, 13, 16, 10),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
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
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildJourneyDetailsCard(),
                          const SizedBox(height: 12),
                          _buildRiderRow(),
                          const SizedBox(height: 10),
                          _buildCurrentWaybillShortcut(),
                          if (_stage == ActiveRideStage.onTrip)
                            _buildSecuredNextTripDetails(),
                        ],
                      ),
                    ),
                  ),
                if (compact) const Spacer(),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Color(0xFFF0F2F3)),
                    ),
                  ),
                  child: _buildPrimaryAction(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildJourneyDetailsCard() {
    return Container(
      key: const ValueKey<String>('active-ride-journey-card'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E8EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Pickup to drop-off',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.stopAddresses.isEmpty
                    ? 'Direct'
                    : '${widget.stopAddresses.length} stop${widget.stopAddresses.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _journeyPoint(
            asset: 'assets/icons/movera_pin.svg',
            label: 'Pickup',
            address: widget.pickupAddress,
            isLast: false,
          ),
          for (var i = 0; i < widget.stopAddresses.length; i++)
            _journeyPoint(
              asset: 'assets/icons/movera_stop.svg',
              label: 'Stop ${i + 1}',
              address: widget.stopAddresses[i],
              isLast: false,
            ),
          _journeyPoint(
            asset: 'assets/icons/movera_flag.svg',
            label: 'Drop-off',
            address: widget.dropoffAddress,
            isLast: true,
          ),
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 10),
            child: Divider(height: 1, color: Color(0xFFEEF0F1)),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.fare == '—'
                      ? widget.category
                      : '${widget.category} · ${widget.fare}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _journeyPoint({
    required String asset,
    required String label,
    required String address,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F5F6),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    asset,
                    width: 16,
                    height: 16,
                    colorFilter: const ColorFilter.mode(
                      _ink,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: const Color(0xFFD5D8DB),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.35,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 15,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stagePill() {
    final label = switch (_stage) {
      ActiveRideStage.headingToPickup => 'PICKUP',
      ActiveRideStage.waitingForRider => 'WAITING',
      ActiveRideStage.onTrip => 'ON TRIP',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E6E8)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _ink,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
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

  Widget _buildRiderRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE6E8EA)),
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
              border: Border.all(color: const Color(0xFFE6E8EA)),
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
        ],
      ),
    );
  }

  Widget _buildCurrentWaybillShortcut() {
    return ValueListenableBuilder<WaybillRecord?>(
      valueListenable: _waybills.currentListenable,
      builder: (context, record, _) {
        if (record == null) return const SizedBox.shrink();

        return Material(
          key: const ValueKey<String>('current-waybill-shortcut'),
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              showMoveraWaybillSheet(
                context,
                record,
                title: 'Current trip waybill',
              );
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE6E8EA)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F5F6),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: _ink,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current waybill',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${record.service} · ${record.fare} · ${record.tripId}',
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
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF98A3A8),
                    size: 19,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrimaryAction() {
    final accent = switch (_stage) {
      ActiveRideStage.headingToPickup => const Color(0xFF1C242C),
      ActiveRideStage.waitingForRider => const Color(0xFF146B45),
      ActiveRideStage.onTrip => const Color(0xFF1B3F6F),
    };

    return Column(
      children: [
        if (_arrivalTarget != null) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: const ValueKey<String>('active-ride-arrived-button'),
              onPressed: _nearArrivalTarget ? _onArrivedTap : _blockedArrival,
              style: FilledButton.styleFrom(
                elevation: 0,
                backgroundColor:
                    _nearArrivalTarget ? _ink : const Color(0xFFE6E8EA),
                foregroundColor:
                    _nearArrivalTarget ? Colors.white : const Color(0xFF98A1A6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "I've arrived",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
      children: [
        Material(
          key: const ValueKey<String>('active-ride-trip-options'),
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(19),
          child: InkWell(
            onTap: _showTripOptions,
            borderRadius: BorderRadius.circular(19),
            child: Container(
              height: 62,
              width: 62,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF8FAF9),
                    Color(0xFFEEF3F1),
                  ],
                ),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: const Color(0xFFE1E8E5)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF18392E).withOpacity(0.07),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                'assets/icons/movera_route.svg',
                width: 22,
                height: 22,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF33423C),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SlideRideAction(
            key: const ValueKey<String>('active-ride-slide-action'),
            semanticsKey:
                const ValueKey<String>('active-ride-primary-action'),
            label: _slideLabel,
            confirmedLabel: _slideConfirmedLabel,
            iconAsset: switch (_stage) {
              ActiveRideStage.headingToPickup =>
                'assets/icons/movera_pin.svg',
              ActiveRideStage.waitingForRider =>
                'assets/icons/movera_navigation.svg',
              ActiveRideStage.onTrip =>
                'assets/icons/movera_flag.svg',
            },
            accent: accent,
            onConfirmed: () {
              _setMapGesturesBlocked(false);
              if (_stage == ActiveRideStage.headingToPickup ||
                  (_stage == ActiveRideStage.onTrip &&
                   !_paidStopWait &&
                   _stopCursor < widget.stopAddresses.length)) {
                _onArrivedTap();
              } else {
                _advanceRide();
              }
            },
          ),
        ),
      ],
        ),
      ],
    );
  }

  Future<void> _showRiderProfile() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          decoration: const BoxDecoration(
            color: Color(0xFFF7F9F8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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
                    '${widget.riderRating.toStringAsFixed(1)} ★ · '
                    '${widget.riderTrips} rides',
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
          ),
        );
      },
    );
  }

  Future<void> _showTripOptions() async {
    await showMoveraModalSheet<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      heightFactor: 0.78,
      builder: (sheetContext) {
        return MoveraModalSheet(
          heightFactor: 0.78,
          color: const Color(0xFFF7F9F9),
          child: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
              physics: const BouncingScrollPhysics(),
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
                    icon: MoveraMark.receipt,
                    title: 'Current waybill',
                    subtitle:
                        '${widget.pickupAddress} → ${widget.dropoffAddress}',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      final record = _waybills.current;
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
                      _waybills.next != null)
                    _optionTile(
                      key: const ValueKey<String>('next-trip-waybill-option'),
                      icon: MoveraMark.route,
                      title: 'Next trip waybill',
                      subtitle: _waybills.next!.dropoff,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        showMoveraWaybillSheet(
                          context,
                          _waybills.next!,
                          title: 'Next trip waybill',
                        );
                      },
                    ),
                  _optionTile(
                    icon: MoveraMark.shield,
                    title: 'Safety toolkit',
                    subtitle: 'Share trip, record audio or get help',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      showSafetyToolKitSheet(context);
                    },
                  ),
                  _optionTile(
                    key: const ValueKey<String>('active-ride-cancel-option'),
                    icon: _stage == ActiveRideStage.onTrip
                        ? MoveraMark.warning
                        : MoveraMark.close,
                    title: _stage == ActiveRideStage.onTrip
                        ? 'End trip early'
                        : 'Cancel trip',
                    subtitle: _stage == ActiveRideStage.onTrip
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
    required MoveraMark icon,
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
                      : const Color(0xFFF4F5F6),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: MoveraLineIcon(
                  mark: icon,
                  color: danger ? _danger : _ink,
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
    final isOnTrip = _stage == ActiveRideStage.onTrip;
    final reasons = isOnTrip
        ? _onTripCancellationReasons
        : _stage == ActiveRideStage.waitingForRider &&
                !_paidStopWait &&
                _waitSeconds >= 300
            ? <_TripCancellationReason>[_noShowReason, ..._preTripCancellationReasons]
            : _preTripCancellationReasons;

    final reason = await showMoveraModalSheet<_TripCancellationReason>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.32),
      heightFactor: isOnTrip ? 0.72 : 0.66,
      builder: (sheetContext) {
        return MoveraModalSheet(
          key: const ValueKey<String>('trip-cancellation-reasons-sheet'),
          heightFactor: isOnTrip ? 0.72 : 0.66,
          color: const Color(0xFFF8FAF9),
          radius: 28,
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
                    padding: const EdgeInsets.fromLTRB(14, 2, 14, 20),
                    itemCount: reasons.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 7),
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
                          onTap: () => Navigator.pop(sheetContext, reason),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
                            child: Row(
                              children: [
                                Container(
                                  width: 39,
                                  height: 39,
                                  decoration: BoxDecoration(
                                    color: isOnTrip
                                        ? const Color(0xFFFFEEF0)
                                        : const Color(0xFFF0F3F2),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: MoveraLineIcon(
                                    mark: reason.icon,
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

    if (!mounted || reason == null) return;
    await _confirmCancellationReason(reason);
  }

  Future<void> _confirmCancellationReason(
    _TripCancellationReason reason,
  ) async {
    final isOnTrip = _stage == ActiveRideStage.onTrip;

    final confirmed = await showMoveraModalSheet<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.34),
      heightFactor: 0.56,
      builder: (sheetContext) {
        return MoveraModalSheet(
          key: const ValueKey<String>('trip-cancellation-confirmation'),
          heightFactor: 0.56,
          color: const Color(0xFFF8FAF9),
          radius: 28,
          child: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              children: [
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

  Future<void> _submitTripCancellation(_TripCancellationReason reason) async {
    _waitTimer?.cancel();
    _nextTripRadarDemoTimer?.cancel();
    _nextTripRadarMatchTimer?.cancel();
    try {
      final secured = _onTripRadarState == _OnTripRadarState.secured ? _nextTripRadarOffer : null;
      await CompletionJournal(active: widget.activeRideRepository ?? MemoryActiveRideRepository()).finish(
        _waybills.current ?? _buildCurrentWaybill(), status: TripStatus.cancelledByDriver,
        next: secured == null ? null : _snapshotForOffer(secured));
    } catch (_) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save cancellation. Retry.')));
      return;
    }
    // The journal has already applied terminal cleanup and queued handoff.
    if (!await _rideLifecycle.cancel(clearSnapshot: false)) return;
    if (!mounted) return;
    _waybills.discardCurrent();

    final offer = _nextTripRadarOffer;
    final queuedNext =
        _onTripRadarState == _OnTripRadarState.secured && offer != null;
    final nextRide = queuedNext
        ? AcceptRide(
            offerId: offer.id,
            riderName: offer.riderName,
            riderRating: offer.rating,
            fare: offer.fare,
            category: offer.category,
            matchedVia: 'Demo Radar',
            pickupAddress: offer.pickup,
            pickupArea: offer.pickup.split(',').last.trim(),
            dropoffAddress: offer.dropoff,
            pickupPosition: offer.pickupPosition,
            dropoffPosition: offer.dropoffPosition,
            locationRepository: widget.locationRepository,
            routeRepository: widget.routeRepository,
            waybillRepository: _waybills,
            sessionController: widget.sessionController,
            activeRideRepository: widget.activeRideRepository,
          )
        : null;
    if (nextRide != null) {
      _waybills.promoteNextToCurrent();
    } else {
      _waybills.clearNext();
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          queuedNext
              ? 'First trip ended · starting the next one'
              : _stage == ActiveRideStage.onTrip
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

    final navigator = Navigator.of(context);
    if (nextRide != null) {
      navigator.pushReplacement(BottomToTopTransition(nextRide));
      return;
    }
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

}

class _ThrottledVehicleMap extends StatefulWidget {
  const _ThrottledVehicleMap({
    super.key,
    required this.vehicle,
    required this.vehicleIcon,
    required this.stage,
    required this.pickupPosition,
    required this.dropoffPosition,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.polylines,
    required this.padding,
    required this.blockGestures,
    required this.initialTarget,
    required this.onMapCreated,
    required this.onCameraMove,
  });

  final LiveVehicleAnimator vehicle;
  final BitmapDescriptor vehicleIcon;
  final ActiveRideStage stage;
  final LatLng pickupPosition;
  final LatLng dropoffPosition;
  final String pickupAddress;
  final String dropoffAddress;
  final Set<Polyline> polylines;
  final EdgeInsets padding;
  final bool blockGestures;
  final LatLng initialTarget;
  final void Function(GoogleMapController) onMapCreated;
  final void Function(CameraPosition) onCameraMove;

  @override
  State<_ThrottledVehicleMap> createState() => _ThrottledVehicleMapState();
}

class _ThrottledVehicleMapState extends State<_ThrottledVehicleMap> {
  Timer? _ticker;
  late LiveVehiclePose _pose;

  @override
  void initState() {
    super.initState();
    _pose = widget.vehicle.current;
    final inTests = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');
    if (inTests) return;
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      final next = widget.vehicle.current;
      if (next.position.latitude == _pose.position.latitude &&
          next.position.longitude == _pose.position.longitude &&
          next.headingDegrees == _pose.headingDegrees) {
        return;
      }
      setState(() => _pose = next);
    });
  }

  @override
  void didUpdateWidget(covariant _ThrottledVehicleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.vehicle, widget.vehicle)) {
      _pose = widget.vehicle.current;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Set<Marker> get _markers {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('driver'),
        position: _pose.position,
        rotation: _pose.headingDegrees,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        zIndexInt: 12,
        icon: widget.vehicleIcon,
        infoWindow: const InfoWindow(title: 'You'),
      ),
    };

    if (widget.stage != ActiveRideStage.onTrip) {
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

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomGoogleMap(
        key: const ValueKey<String>('active-ride-map'),
        initialPosition: CameraPosition(
          target: widget.initialTarget,
          zoom: 15.8,
        ),
        markers: _markers,
        polylines: widget.polylines,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: false,
        trafficEnabled: false,
        buildingsEnabled: true,
        indoorViewEnabled: false,
        scrollGesturesEnabled: !widget.blockGestures,
        zoomGesturesEnabled: !widget.blockGestures,
        rotateGesturesEnabled: !widget.blockGestures,
        tiltGesturesEnabled: !widget.blockGestures,
        mapType: MapType.normal,
        padding: widget.padding,
        onCameraMove: widget.onCameraMove,
        onMapCreated: widget.onMapCreated,
      ),
    );
  }
}

class _SlideRideAction extends StatefulWidget {
  const _SlideRideAction({
    super.key,
    required this.semanticsKey,
    required this.label,
    required this.confirmedLabel,
    required this.iconAsset,
    required this.accent,
    required this.onConfirmed,
  });

  final Key semanticsKey;
  final String label;
  final String confirmedLabel;
  final String iconAsset;
  final Color accent;
  final VoidCallback onConfirmed;

  @override
  State<_SlideRideAction> createState() => _SlideRideActionState();
}

class _SlideRideActionState extends State<_SlideRideAction> {
  static const double _height = 62;
  static const double _thumb = 54;
  static const double _trigger = 0.78;

  double _fraction = 0;
  bool _dragging = false;
  bool _confirmed = false;

  @override
  void didUpdateWidget(covariant _SlideRideAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.label == widget.label &&
        oldWidget.iconAsset == widget.iconAsset &&
        oldWidget.accent == widget.accent) {
      return;
    }
    _fraction = 0;
    _dragging = true;
    _confirmed = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _confirmed || _fraction != 0) return;
      setState(() => _dragging = false);
    });
  }

  void _update(double delta, double maxTravel) {
    if (_confirmed || maxTravel <= 0) return;
    final next = (_fraction + (delta / maxTravel)).clamp(0.0, 1.0);
    setState(() {
      _dragging = true;
      _fraction = next >= _trigger ? 1 : next;
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
      HapticFeedback.mediumImpact();
      widget.onConfirmed();
    } else {
      setState(() {
        _dragging = false;
        _fraction = 0;
      });
      HapticFeedback.selectionClick();
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
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    widget.accent,
                    Color.lerp(widget.accent, Colors.white, 0.16)!,
                  ],
                ),
                borderRadius: BorderRadius.circular(21),
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF172027).withOpacity(0.17),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(21),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: _dragging
                              ? Duration.zero
                              : const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          width: constraints.maxWidth *
                              math.min(1.0, _fraction + 0.10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                widget.accent.withOpacity(0.44),
                                widget.accent.withOpacity(0.14),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 64,
                    right: 58,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        _confirmed ? widget.confirmedLabel : widget.label,
                        key: ValueKey<String>(
                          _confirmed ? widget.confirmedLabel : widget.label,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.18,
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: _dragging
                        ? Duration.zero
                        : const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    left: 4 + (maxTravel * _fraction),
                    top: 4,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: _thumb,
                      height: _thumb,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _confirmed
                              ? [
                                  widget.accent,
                                  widget.accent.withOpacity(0.82),
                                ]
                              : const [
                                  Color(0xFFFFFFFF),
                                  Color(0xFFF0F6F3),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _confirmed
                              ? Colors.white.withOpacity(0.12)
                              : const Color(0xFFE0E7E4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0C1814).withOpacity(0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: _confirmed
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 23,
                            )
                          : SvgPicture.asset(
                              widget.iconAsset,
                              width: 22,
                              height: 22,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF26333A),
                                BlendMode.srcIn,
                              ),
                            ),
                    ),
                  ),
                  if (!_confirmed)
                    Positioned(
                      right: 12,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white.withOpacity(0.72),
                            size: 16,
                          ),
                          Transform.translate(
                            offset: const Offset(-5, 0),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white.withOpacity(0.4),
                              size: 16,
                            ),
                          ),
                        ],
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
