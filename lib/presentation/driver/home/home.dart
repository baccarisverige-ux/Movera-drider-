import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/core/admin/driver_home_admin_content.dart';
import 'package:movera/core/admin/driver_home_config_repository.dart';
import 'package:movera/core/dispatch/dispatch_repository.dart';
import 'package:movera/core/dispatch/demo_dispatch_repository.dart';
import 'package:movera/core/geo/geo_point_maps.dart';
import 'package:movera/core/routing/route_maps.dart';
import 'package:movera/core/location/driver_location_repository.dart';
import 'package:movera/core/location/driver_location_service.dart';
import 'package:movera/core/logging/driver_log.dart';
import 'package:movera/core/ride/active_ride_repository.dart';
import 'package:movera/core/routing/road_route_service.dart';
import 'package:movera/core/routing/route_repository.dart';
import 'package:movera/core/session/driver_session_controller.dart';
import 'package:movera/core/waybill/waybill.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/accept%20ride/accept_ride.dart';
import 'package:movera/presentation/driver/destination%20mode/destination_picker.dart';
import 'package:movera/presentation/driver/home/components/account_activation_diaglog.dart';
import 'package:movera/presentation/driver/home/components/destination_set_panel.dart';
import 'package:movera/presentation/driver/home/components/driver_sheet_nav.dart';
import 'package:movera/presentation/driver/home/components/driver_suspended_sheet.dart';
import 'package:movera/presentation/driver/my%20queue%20position/components/in_airport_queue.dart';
import 'package:movera/presentation/driver/ride%20history/ride_history.dart';
import 'package:movera/presentation/driver/ride%20requests/ride_requests.dart';
import 'package:movera/presentation/driver/scheduled%20rides/scheduled_rides.dart';
import 'package:movera/presentation/driver/safety%20toolkits/safety_toolkits.dart';
import 'package:movera/presentation/driver/side%20menu/side_menu.dart';
import 'package:movera/presentation/driver/waybill/waybill_sheet.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';
import 'package:movera/widgets/layout_viewport.dart';
import 'package:movera/widgets/custom_google_map.dart';
import 'package:movera/widgets/movera_radar_orb.dart';
import 'package:movera/widgets/movera_sheet_metrics.dart';
import 'package:movera/widgets/movera_vehicle_marker.dart';
import 'package:movera/presentation/driver/sheets/movera_snap_sheet_controller.dart';
import 'package:movera/presentation/driver/overlays/map_overlay_insets.dart';
import 'package:movera/presentation/driver/overlays/trip_status_banner.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({
    super.key,
    this.initialOnline = false,
    this.locationRepository,
    this.routeRepository,
    this.waybillRepository,
    this.sessionController,
    this.dispatchRepository,
    this.homeConfigRepository,
    this.activeRideRepository,
  });

  final bool initialOnline;
  final DriverLocationRepository? locationRepository;
  final RouteRepository? routeRepository;
  final WaybillRepository? waybillRepository;
  final DriverSessionController? sessionController;
  final DispatchRepository? dispatchRepository;
  final DriverHomeConfigRepository? homeConfigRepository;
  final ActiveRideRepository? activeRideRepository;

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PanelController _panelController = PanelController();
  final PanelController _destinationPanelController = PanelController();
  late final AnimationController _goOnlinePulseController;
  late final AnimationController _radarSweepController;
  Timer? _onlineTransitionTimer;
  Timer? _homeSheetPositionGuardTimer;
  Timer? _offerSimulationTimer;
  Timer? _directOfferTimer;
  Timer? _outsideOfferTimeoutTimer;
  Timer? _expandedDirectOfferTimer;
  Timer? _radarOfferTwoTimer;
  Timer? _radarOfferThreeTimer;
  Timer? _homeRadarMatchResolutionTimer;
  Timer? _homeRadarNoticeTimer;
  Timer? _homeRadarExternalClaimTimer;
  Timer? _homeRadarExternalClaimCleanupTimer;
  Timer? _homeRadarLostMatchTimer;
  final Map<String, Timer> _radarOfferTimeoutTimers = <String, Timer>{};
  final Map<String, _HomeRadarMatchState> _homeRadarMatchStates =
      <String, _HomeRadarMatchState>{};
  String? _homeRadarMatchingOfferId;
  _HomeRadarMatchNotice? _homeRadarMatchNotice;
  late final DriverLocationRepository _driverLocationService;
  late final RouteRepository _roadRouteService;
  late final WaybillRepository _waybills;
  late final DispatchRepository _dispatch;
  late final bool _ownsDispatch;
  late final DriverHomeAdminConfig _adminHomeConfig;
  static const String _currentAppVersion = '1.0.0';
  bool _updatePromptShown = false;

  GoogleMapController? _mapController;
  StreamSubscription<DriverLocation>? _driverLocationSubscription;
  bool _hasLiveDriverLocation = false;
  bool _didCenterOnLiveLocation = false;
  BitmapDescriptor _driverVehicleIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  double _driverHeading = 0;
  bool isPanelOpen = false;
  bool _blockMapGestures = false;
  bool _sheetPointerActive = false;
  double _mainPanelPosition = 0;
  final ValueNotifier<double> _panelSlidePosition = ValueNotifier<double>(0);

  static const double _homeExpandedFraction = 0.86;
  static const Duration _outsideOfferLifetime = Duration(milliseconds: 8500);
  static const Duration _radarOfferLifetime = Duration(milliseconds: 30000);
  static const int _maxHomeRadarOffers = 4;
  double _sheetPointerVelocity = 0;
  double _sheetPointerLastY = 0;
  int _sheetPointerLastMs = 0;
  double _lastSnapHapticAt = -1;
  late final MoveraSnapSheetController _snapSheet;
  bool showRideRequests = false;
  bool isAccountActivated = true;
  late final DriverSessionController _driverSession;
  late final bool _ownsDriverSession;
  bool get _isOnline => _driverSession.isOnline;
  bool get _isGoingOnline => _driverSession.isGoingOnline;
  bool _hasRideOffers = false;
  bool _hasScheduledRideOffers = true;
  bool _showTodaySummaryPopup = false;
  _HomeDirectOffer? _outsideRadarOffer;
  final List<_HomeDirectOffer> _radarHomeOffers = <_HomeDirectOffer>[];
  final List<_HomeDirectOffer> _pendingRadarHomeOffers = <_HomeDirectOffer>[];
  bool _destinationModeActive = false;
  String? _destinationAddress;
  LatLng? _destinationPosition;

  // ignore: prefer_final_fields
  Set<Marker> _markers = {};
  Set<Marker> _directOfferRouteMarkers = {};
  Set<Polyline> _directOfferRoutePolylines = {};
  Set<Marker> _destinationRouteMarkers = {};
  Set<Polyline> _destinationRoutePolylines = {};
  bool _isDirectOfferRoutePreview = false;

  static const LatLng _fallbackDriverPosition = LatLng(59.3293, 18.0686);
  LatLng _driverPosition = _fallbackDriverPosition;
  static const CameraPosition _initialPosition = CameraPosition(
    target: _fallbackDriverPosition,
    zoom: 14.0,
  );

  static const _HomeDirectOffer _veryCloseDirectOffer = _HomeDirectOffer(
    id: 'home-direct-close',
    category: 'Comfort',
    reason: 'Exclusive nearby offer',
    detail: 'Exclusive Radar priority match',
    fare: '104,80 kr',
    rating: '4.96',
    pickupMinutes: 3,
    pickupKm: 0.9,
    tripMinutes: 14,
    tripKm: 7.6,
    pickup: 'Kungsgatan 42, Stockholm',
    dropoff: 'Hornstull, Stockholm',
    pickupPosition: LatLng(59.3343, 18.0615),
    dropoffPosition: LatLng(59.3157, 18.0335),
  );

  static const _HomeDirectOffer _expandedDirectOffer = _HomeDirectOffer(
    id: 'home-direct-expanded',
    category: 'Premium',
    reason: 'Extended coverage offer',
    detail: 'Exclusive Radar extended match',
    fare: '176,20 kr',
    rating: '4.98',
    pickupMinutes: 8,
    pickupKm: 3.3,
    tripMinutes: 21,
    tripKm: 13.8,
    pickup: 'Odengatan 63, Stockholm',
    dropoff: 'Solna centrum, Solna',
    pickupPosition: LatLng(59.3449, 18.0472),
    dropoffPosition: LatLng(59.3603, 18.0009),
  );

  static const _HomeDirectOffer _radarHomeOffer = _HomeDirectOffer(
    id: 'home-radar-match',
    category: 'Comfort',
    reason: 'Trip Radar match',
    detail: 'Detected in your live radar coverage',
    fare: '156,80 kr',
    rating: '4.77',
    pickupMinutes: 6,
    pickupKm: 1.8,
    tripMinutes: 18,
    tripKm: 16.4,
    pickup: 'Kungsgatan 44, Stockholm',
    dropoff: 'Modulvägen 6B, Kungens Kurva',
    pickupPosition: LatLng(59.3347, 18.0621),
    dropoffPosition: LatLng(59.2697, 17.9258),
  );

  static const _HomeDirectOffer _radarHomeOffer2 = _HomeDirectOffer(
    id: 'home-radar-match-2',
    category: 'Premium',
    reason: 'Trip Radar match',
    detail: 'Live request inside your radar area',
    fare: '198,40 kr',
    rating: '4.91',
    pickupMinutes: 4,
    pickupKm: 1.1,
    tripMinutes: 23,
    tripKm: 14.2,
    pickup: 'Sveavägen 86, Stockholm',
    dropoff: 'Mall of Scandinavia, Solna',
    pickupPosition: LatLng(59.3426, 18.0594),
    dropoffPosition: LatLng(59.3703, 18.0031),
  );

  static const _HomeDirectOffer _radarHomeOffer3 = _HomeDirectOffer(
    id: 'home-radar-match-3',
    category: 'Comfort',
    reason: 'Trip Radar match',
    detail: 'Live request inside your radar area',
    fare: '132,60 kr',
    rating: '4.85',
    pickupMinutes: 7,
    pickupKm: 2.4,
    tripMinutes: 16,
    tripKm: 9.8,
    pickup: 'Sankt Eriksgatan 52, Stockholm',
    dropoff: 'Liljeholmen, Stockholm',
    pickupPosition: LatLng(59.3356, 18.0378),
    dropoffPosition: LatLng(59.3108, 18.0222),
  );

  @override
  void initState() {
    super.initState();
    _ownsDriverSession = widget.sessionController == null;
    _driverSession = widget.sessionController ??
        DriverSessionController(initialOnline: widget.initialOnline);
    _driverSession.addListener(_onDriverSessionChanged);
    _driverLocationService =
        widget.locationRepository ?? const DriverLocationService();
    _roadRouteService = widget.routeRepository ?? RoadRouteService();
    _waybills =
        widget.waybillRepository ?? InMemoryWaybillRepository.instance;
    _ownsDispatch = widget.dispatchRepository == null;
    _dispatch = widget.dispatchRepository ?? DemoDispatchRepository();
    if (widget.sessionController != null && widget.initialOnline) {
      _driverSession.setOnline(true);
    }
    _adminHomeConfig = (widget.homeConfigRepository ??
            const LocalDriverHomeConfigRepository())
        .load();
    _hasScheduledRideOffers =
        _adminHomeConfig.scheduledRides.hasOpenRequests;
    _goOnlinePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _radarSweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _snapSheet = MoveraSnapSheetController(panel: _panelController, vsync: this);
    _loadMarkers();
    _prepareDriverVehicleMarker();
    _startDriverLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_restoreActiveRideIfNeeded());
      _maybeShowAppUpdatePrompt();
    });
  }

  bool _didAttemptActiveRideRestore = false;

  Future<void> _restoreActiveRideIfNeeded() async {
    if (_didAttemptActiveRideRestore) return;
    _didAttemptActiveRideRestore = true;
    final repo = widget.activeRideRepository;
    if (repo == null) return;
    final snapshot = await repo.read();
    if (!mounted || snapshot == null) return;

    DriverLog.info(
      'Restoring active ride ${snapshot.tripId} at ${snapshot.stage.name}',
    );
    _waybills.beginCurrent(_waybillFromSnapshot(snapshot));
    final next = snapshot.next;
    if (next != null) {
      _waybills.secureNext(_waybillFromQueued(next));
    }

    if (!mounted) return;
    Navigator.of(context).push(
      BottomToTopTransition(
        AcceptRide.fromPersisted(
          snapshot,
          waybillRepository: _waybills,
          sessionController: _driverSession,
          locationRepository: _driverLocationService,
          routeRepository: _roadRouteService,
          activeRideRepository: repo,
        ),
      ),
    );
  }

  WaybillRecord _waybillFromSnapshot(PersistedActiveRide snapshot) {
    return WaybillRecord(
      tripId: snapshot.tripId,
      statusLabel: 'Current trip',
      issuedAt: snapshot.savedAt ?? DateTime.now(),
      fare: snapshot.fare ?? '—',
      service: snapshot.category ?? 'Movera',
      riderName: snapshot.riderName ?? 'Angelica',
      pickup: snapshot.pickupAddress ?? '',
      dropoff: snapshot.dropoffAddress ?? '',
      source: snapshot.matchedVia ?? 'Movera Radar',
      driverName: 'Movera Driver',
      vehicle: 'Movera partner vehicle',
      licensePlate: 'MVR 418',
      passengerCapacity: 4,
    );
  }

  WaybillRecord _waybillFromQueued(PersistedQueuedTrip next) {
    return WaybillRecord(
      tripId: next.tripId,
      statusLabel: 'Next trip secured',
      issuedAt: DateTime.now(),
      fare: next.fare,
      service: next.category,
      riderName: next.riderName,
      pickup: next.pickup,
      dropoff: next.dropoff,
      source: 'Movera Radar',
      driverName: 'Movera Driver',
      vehicle: 'Movera partner vehicle',
      licensePlate: 'MVR 418',
      passengerCapacity: 4,
    );
  }

  void _onDriverSessionChanged() {
    if (!mounted) return;
    if (_driverSession.consumeResumeHomeAfterTrip()) {
      setState(() {
        showRideRequests = false;
      });
      return;
    }
    setState(() {});
  }

  Future<void> _startDriverLocation({bool moveCamera = false}) async {
    try {
      final position = await _driverLocationService.getCurrentPosition();
      if (!mounted) return;
      _applyDriverLocation(position);
      _listenToDriverLocation();
      if (moveCamera || !_didCenterOnLiveLocation) {
        _didCenterOnLiveLocation = true;
        await _animateToDriverLocation();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasLiveDriverLocation = false);
    }
  }

  void _listenToDriverLocation() {
    _driverLocationSubscription?.cancel();
    _driverLocationSubscription = _driverLocationService
        .watchPosition(distanceFilterMeters: 8)
        .listen(
      (location) {
        _applyDriverLocation(location);
        if (!_didCenterOnLiveLocation) {
          _didCenterOnLiveLocation = true;
          unawaited(_animateToDriverLocation());
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _hasLiveDriverLocation = false);
      },
    );
  }

  void _applyDriverLocation(DriverLocation location) {
    if (!mounted) return;

    final next = location.point.toLatLng();
    final heading =
        location.headingDegrees.isFinite && location.headingDegrees >= 0
            ? location.headingDegrees
            : _driverHeading;
    setState(() {
      _driverPosition = next;
      _driverHeading = heading;
      _hasLiveDriverLocation = true;
      _markers = {
        Marker(
          markerId: const MarkerId('driver_location'),
          position: next,
          infoWindow: const InfoWindow(title: 'Your live location'),
          icon: _driverVehicleIcon,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          rotation: _driverHeading,
          zIndex: 12,
        ),
      };
    });

    if (_destinationModeActive) {
      _refreshDestinationRoadRoute();
    }
  }

  Future<void> _prepareDriverVehicleMarker() async {
    final icon = await MoveraVehicleMarker.createIcon();
    if (!mounted) return;
    setState(() {
      _driverVehicleIcon = icon;
      _markers = {
        Marker(
          markerId: const MarkerId('driver_location'),
          position: _driverPosition,
          infoWindow: const InfoWindow(title: 'Your live location'),
          icon: _driverVehicleIcon,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          rotation: _driverHeading,
          zIndex: 12,
        ),
      };
    });
  }

  Future<void> _animateToDriverLocation() async {
    final controller = _mapController;
    if (controller == null) return;

    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _driverPosition,
            zoom: 16.8,
            bearing: _driverHeading,
            tilt: 35,
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> _zoomToDriverLocation() async {
    await _startDriverLocation(moveCamera: true);
    if (!mounted) return;
    await _animateToDriverLocation();
  }

  Widget _buildDriverLocationButton() {
    return PointerInterceptor(
      child: Material(
        key: const ValueKey<String>('driver-location-zoom'),
        color: Colors.white,
        elevation: 4,
        shadowColor: const Color(0xFF172027).withOpacity(0.16),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: _zoomToDriverLocation,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.my_location_rounded,
                  color: _hasLiveDriverLocation
                      ? const Color(0xFF19865C)
                      : const Color(0xFF66737A),
                  size: 22,
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _hasLiveDriverLocation
                          ? const Color(0xFF55B38A)
                          : const Color(0xFFAAB2B6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _loadMarkers() {
    _markers.add(
      Marker(
        markerId: const MarkerId('driver_location'),
        position: _driverPosition,
        infoWindow: const InfoWindow(title: 'Your location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
  }

  double _homeMapObscuredBottom(BuildContext context) {
    if (_outsideRadarOffer != null) {
      final height = MediaQuery.sizeOf(context).height;
      return math.max(320.0, height * 0.48);
    }
    if (_isDirectOfferRoutePreview || _radarHomeOffers.isNotEmpty) {
      return 188;
    }
    return MoveraSheetMetrics.collapsedHeight;
  }

  Future<void> _previewDirectOfferRoute(
    LatLng pickup,
    LatLng dropoff,
  ) async {
    if (!mounted) return;

    setState(() {
      _isDirectOfferRoutePreview = true;
      _directOfferRouteMarkers = {
        Marker(
          markerId: const MarkerId('radar_pickup'),
          position: pickup,
          infoWindow: const InfoWindow(title: 'Pickup'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
        Marker(
          markerId: const MarkerId('radar_dropoff'),
          position: dropoff,
          infoWindow: const InfoWindow(title: 'Drop-off'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      };
      _directOfferRoutePolylines = <Polyline>{};
    });

    final roadPoints = <LatLng>[];

    if (_hasLiveDriverLocation) {
      try {
        final approach = await _roadRouteService.drivingRoute(
          origin: GeoPointMaps.fromLatLng(_driverPosition),
          destination: GeoPointMaps.fromLatLng(pickup),
        );
        roadPoints.addAll(approach.latLngPoints);
      } catch (_) {}
    }

    try {
      final trip = await _roadRouteService.drivingRoute(
        origin: GeoPointMaps.fromLatLng(pickup),
        destination: GeoPointMaps.fromLatLng(dropoff),
      );
      if (roadPoints.isNotEmpty &&
          trip.latLngPoints.isNotEmpty &&
          roadPoints.last == trip.latLngPoints.first) {
        roadPoints.addAll(trip.latLngPoints.skip(1));
      } else {
        roadPoints.addAll(trip.latLngPoints);
      }
    } catch (_) {}

    if (!mounted) return;

    final media = MediaQuery.of(context);
    final insets = MapOverlayInsets.forHome(
      safeTop: media.padding.top,
      obscuredBottom: _homeMapObscuredBottom(context),
      hasTopBanner: _homeRadarMatchNotice != null,
    );

    if (roadPoints.length >= 2) {
      setState(() {
        _directOfferRoutePolylines = {
          Polyline(
            polylineId: const PolylineId('direct_offer_road_route'),
            points: roadPoints,
            color: AppColor.primary,
            width: 6,
            geodesic: false,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        };
      });
    }

    await _fitPoints(
      roadPoints.isNotEmpty ? roadPoints : <LatLng>[pickup, dropoff],
      padding: insets.boundsPadding,
    );
  }

  Future<void> _fitPoints(
    List<LatLng> points, {
    double padding = 80,
  }) async {
    if (points.isEmpty || _mapController == null) return;

    var south = points.first.latitude;
    var north = points.first.latitude;
    var west = points.first.longitude;
    var east = points.first.longitude;

    for (final point in points.skip(1)) {
      south = math.min(south, point.latitude);
      north = math.max(north, point.latitude);
      west = math.min(west, point.longitude);
      east = math.max(east, point.longitude);
    }

    if ((north - south).abs() < 0.00001 &&
        (east - west).abs() < 0.00001) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 16),
      );
      return;
    }

    try {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(south, west),
            northeast: LatLng(north, east),
          ),
          padding,
        ),
      );
    } catch (_) {}
  }

  void _openDestinationModePicker() {
    _closeHomeFloatingPopupsForSheet();
    if (_mainPanelPosition > 0.001 || isPanelOpen) {
      _panelController.close();
    }
    if (!mounted) return;

    Navigator.of(context)
        .push<DriverDestinationResult>(
          MaterialPageRoute(
            builder: (_) => const DriverDestinationPicker(),
          ),
        )
        .then((result) {
          if (!mounted || result == null) return;
          _activateDestinationMode(result);
        });
  }

  Future<void> _activateDestinationMode(
    DriverDestinationResult result,
  ) async {
    final destination = result.position;
    setState(() {
      _destinationModeActive = true;
      _destinationAddress = result.address;
      _destinationPosition = destination;
      _destinationRouteMarkers = {
        Marker(
          markerId: const MarkerId('destination_mode_target'),
          position: destination,
          infoWindow: InfoWindow(title: result.address),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      };
      _destinationRoutePolylines = <Polyline>{};
    });

    await _refreshDestinationRoadRoute();
    await _fitDestinationRoute();

    if (!_isOnline && !_isGoingOnline) {
      _goOnline();
    }
  }

  Future<void> _refreshDestinationRoadRoute() async {
    final destination = _destinationPosition;
    if (destination == null || !_hasLiveDriverLocation) {
      if (mounted) {
        setState(() => _destinationRoutePolylines = <Polyline>{});
      }
      return;
    }

    try {
      final route = await _roadRouteService.drivingRoute(
        origin: GeoPointMaps.fromLatLng(_driverPosition),
        destination: GeoPointMaps.fromLatLng(destination),
      );
      if (!mounted || _destinationPosition != destination) return;

      setState(() {
        _destinationRoutePolylines = {
          Polyline(
            polylineId: const PolylineId('destination_mode_road_route'),
            points: route.latLngPoints,
            color: AppColor.primary,
            width: 6,
            geodesic: false,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        };
      });
    } catch (_) {
      if (!mounted || _destinationPosition != destination) return;
      setState(() => _destinationRoutePolylines = <Polyline>{});
    }
  }

  Future<void> _fitDestinationRoute() async {
    final destination = _destinationPosition;
    if (destination == null || _mapController == null) return;

    final routePoints = _destinationRoutePolylines.isEmpty
        ? <LatLng>[_driverPosition, destination]
        : _destinationRoutePolylines.first.points;

    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted || _mapController == null) return;

    await _fitPoints(routePoints, padding: 74);
  }

  void _endDestinationMode() {
    if (!_destinationModeActive) return;
    setState(() {
      _destinationModeActive = false;
      _destinationAddress = null;
      _destinationPosition = null;
      _destinationRouteMarkers = {};
      _destinationRoutePolylines = {};
    });
  }

  String get _destinationShortLabel {
    final address = _destinationAddress?.trim();
    if (address == null || address.isEmpty) return 'Destination';
    final firstPart = address.split(',').first.trim();
    if (firstPart.length <= 24) return firstPart;
    return '${firstPart.substring(0, 21)}…';
  }

  bool _directOfferFollowsDestination(_HomeDirectOffer offer) {
    if (!_destinationModeActive) return true;
    final destination = _destinationPosition;
    if (destination == null) return true;

    final latitudeRadians = _driverPosition.latitude * math.pi / 180;
    final longitudeScale = math.cos(latitudeRadians);

    final destinationX =
        (destination.longitude - _driverPosition.longitude) * longitudeScale;
    final destinationY = destination.latitude - _driverPosition.latitude;
    final offerX =
        (offer.dropoffPosition.longitude - _driverPosition.longitude) *
        longitudeScale;
    final offerY =
        offer.dropoffPosition.latitude - _driverPosition.latitude;

    final destinationLength = math.sqrt(
      destinationX * destinationX + destinationY * destinationY,
    );
    final offerLength = math.sqrt(offerX * offerX + offerY * offerY);
    if (destinationLength == 0 || offerLength == 0) return true;

    final cosine =
        (destinationX * offerX + destinationY * offerY) /
        (destinationLength * offerLength);
    return cosine >= 0.45;
  }

  void _clearDirectOfferRoute() {
    if (!mounted) return;
    setState(() {
      _isDirectOfferRoutePreview = false;
      _directOfferRouteMarkers = {};
      _directOfferRoutePolylines = {};
    });
  }

  Future<void> _showOutsideRadarOffer(
    _HomeDirectOffer offer,
  ) async {
    if (!mounted ||
        !_isOnline ||
        showRideRequests ||
        _radarHomeOffers.isNotEmpty ||
        _pendingRadarHomeOffers.isNotEmpty ||
        _hasRideOffers ||
        !_directOfferFollowsDestination(offer) ||
        _mainPanelPosition > 0.04 ||
        isPanelOpen) {
      return;
    }

    _outsideOfferTimeoutTimer?.cancel();
    setState(() {
      _outsideRadarOffer = offer;
    });

    _outsideOfferTimeoutTimer = Timer(
      _outsideOfferLifetime,
      () {
        if (!mounted || _outsideRadarOffer?.id != offer.id) return;
        _dismissOutsideRadarOffer();
      },
    );

    await _previewDirectOfferRoute(
      offer.pickupPosition,
      offer.dropoffPosition,
    );
  }

  void _dismissOutsideRadarOffer() {
    _outsideOfferTimeoutTimer?.cancel();
    _outsideOfferTimeoutTimer = null;
    if (!mounted) return;

    setState(() {
      _outsideRadarOffer = null;
    });
    _clearDirectOfferRoute();
    _releasePendingRadarOffers();
  }

  void _showRadarHomeOffer(_HomeDirectOffer offer) {
    if (!mounted ||
        !_isOnline ||
        !_directOfferFollowsDestination(offer) ||
        _radarHomeOffers.any((item) => item.id == offer.id) ||
        _pendingRadarHomeOffers.any((item) => item.id == offer.id) ||
        _radarHomeOffers.length + _pendingRadarHomeOffers.length >=
            _maxHomeRadarOffers) {
      return;
    }

    _scheduleRadarOfferExpiry(offer);

    if (_outsideRadarOffer != null) {
      setState(() {
        _hasRideOffers = true;
        _pendingRadarHomeOffers.add(offer);
      });
      return;
    }

    // Keep the visible Home Radar list stable. The first detected trip creates
    // the snapshot; later detections wait for an explicit driver refresh.
    if (_radarHomeOffers.isEmpty) {
      _activateRadarHomeOffer(offer);
      return;
    }

    setState(() {
      _hasRideOffers = true;
      _pendingRadarHomeOffers.add(offer);
    });
  }

  void _scheduleRadarOfferExpiry(_HomeDirectOffer offer) {
    _radarOfferTimeoutTimers.remove(offer.id)?.cancel();
    _radarOfferTimeoutTimers[offer.id] = Timer(
      _radarOfferLifetime,
      () {
        if (!mounted) return;
        _dismissRadarHomeOffer(offer);
      },
    );
  }

  void _activateRadarHomeOffer(_HomeDirectOffer offer) {
    if (!mounted ||
        !_isOnline ||
        _radarHomeOffers.length >= _maxHomeRadarOffers ||
        _radarHomeOffers.any((item) => item.id == offer.id)) {
      return;
    }

    setState(() {
      _hasRideOffers = true;
      _radarHomeOffers.add(offer);
      _pendingRadarHomeOffers.removeWhere((item) => item.id == offer.id);
    });
  }

  void _refreshRadarHomeOffers() {
    if (!mounted ||
        !_isOnline ||
        _outsideRadarOffer != null ||
        _pendingRadarHomeOffers.isEmpty) {
      return;
    }

    final refreshed = <_HomeDirectOffer>[
      ..._radarHomeOffers,
      ..._pendingRadarHomeOffers,
    ];

    final seen = <String>{};
    final next = <_HomeDirectOffer>[];
    for (final offer in refreshed) {
      if (seen.add(offer.id)) {
        next.add(offer);
      }
      if (next.length >= _maxHomeRadarOffers) break;
    }

    setState(() {
      _radarHomeOffers
        ..clear()
        ..addAll(next);
      _pendingRadarHomeOffers.clear();
      _hasRideOffers = _radarHomeOffers.isNotEmpty;
    });

    _scheduleHomeRadarExternalClaimDemo();
  }

  void _releasePendingRadarOffers() {
    if (!mounted ||
        !_isOnline ||
        _outsideRadarOffer != null ||
        _pendingRadarHomeOffers.isEmpty) {
      return;
    }

    // Keep detected trips pending until the driver explicitly refreshes.
    setState(() {
      _hasRideOffers = true;
    });
  }

  void _dismissRadarHomeOffer(_HomeDirectOffer offer) {
    _radarOfferTimeoutTimers.remove(offer.id)?.cancel();
    if (!mounted) return;

    setState(() {
      _radarHomeOffers.removeWhere((item) => item.id == offer.id);
      _pendingRadarHomeOffers.removeWhere((item) => item.id == offer.id);
      _homeRadarMatchStates.remove(offer.id);
      _hasRideOffers =
          _radarHomeOffers.isNotEmpty || _pendingRadarHomeOffers.isNotEmpty;
    });

    if (_radarHomeOffers.isEmpty && _pendingRadarHomeOffers.isNotEmpty) {
      _releasePendingRadarOffers();
    }
  }

  _HomeRadarMatchState _homeRadarStateFor(String id) =>
      _homeRadarMatchStates[id] ?? _HomeRadarMatchState.available;

  void _startHomeRadarMatch(_HomeDirectOffer offer) {
    if (!_radarHomeOffers.any((item) => item.id == offer.id) ||
        _homeRadarStateFor(offer.id) != _HomeRadarMatchState.available ||
        _homeRadarMatchingOfferId != null) {
      return;
    }

    setState(() {
      _homeRadarMatchingOfferId = offer.id;
      _homeRadarMatchStates[offer.id] = _HomeRadarMatchState.resolving;
      _homeRadarMatchNotice = const _HomeRadarMatchNotice(
        type: _HomeRadarMatchNoticeType.matching,
        title: 'Matching trip',
        message: 'Confirming this request in real time…',
      );
    });

    _homeRadarMatchResolutionTimer?.cancel();
    _homeRadarMatchResolutionTimer = Timer(
      const Duration(milliseconds: 1450),
      () {
        if (!mounted || _homeRadarMatchingOfferId != offer.id) return;

        if (offer.id == 'home-radar-match-2') {
          _resolveHomeRadarMatchLost(offer);
        } else {
          _resolveHomeRadarMatchWon(offer);
        }
      },
    );
  }

  void _resolveHomeRadarMatchWon(_HomeDirectOffer offer) {
    _homeRadarNoticeTimer?.cancel();

    setState(() {
      _homeRadarMatchingOfferId = null;
      _homeRadarMatchStates.remove(offer.id);
      _homeRadarMatchNotice = const _HomeRadarMatchNotice(
        type: _HomeRadarMatchNoticeType.success,
        title: 'Trip matched',
        message: 'You’re assigned to this request. Opening trip…',
      );
    });

    _homeRadarNoticeTimer = Timer(
      const Duration(milliseconds: 850),
      () {
        if (!mounted) return;
        _acceptRadarHomeOffer(offer);
      },
    );
  }

  void _resolveHomeRadarMatchLost(_HomeDirectOffer offer) {
    setState(() {
      _homeRadarMatchingOfferId = null;
      _homeRadarMatchStates[offer.id] =
          _HomeRadarMatchState.claimedElsewhere;
      _homeRadarMatchNotice = const _HomeRadarMatchNotice(
        type: _HomeRadarMatchNoticeType.taken,
        title: 'Request taken',
        message: 'Another driver was matched first. Choose another trip.',
      );
    });

    _homeRadarNoticeTimer?.cancel();
    _homeRadarNoticeTimer = Timer(
      const Duration(milliseconds: 2600),
      () {
        if (!mounted) return;
        setState(() => _homeRadarMatchNotice = null);
      },
    );

    _homeRadarLostMatchTimer?.cancel();
    _homeRadarLostMatchTimer = Timer(
      const Duration(milliseconds: 2800),
      () {
        if (!mounted ||
            _homeRadarStateFor(offer.id) !=
                _HomeRadarMatchState.claimedElsewhere) {
          return;
        }
        _dismissRadarHomeOffer(offer);
      },
    );
  }

  void _scheduleHomeRadarExternalClaimDemo() {
    _homeRadarExternalClaimTimer?.cancel();

    _HomeDirectOffer? offer;
    for (final item in _radarHomeOffers) {
      if (item.id == 'home-radar-match-3') {
        offer = item;
        break;
      }
    }
    if (offer == null ||
        _homeRadarStateFor(offer.id) != _HomeRadarMatchState.available) {
      return;
    }

    final matchedOffer = offer;
    _homeRadarExternalClaimTimer = Timer(
      const Duration(milliseconds: 4200),
      () {
        if (!mounted ||
            !_radarHomeOffers.any((item) => item.id == matchedOffer.id) ||
            _homeRadarStateFor(matchedOffer.id) !=
                _HomeRadarMatchState.available) {
          return;
        }

        setState(() {
          _homeRadarMatchStates[matchedOffer.id] =
              _HomeRadarMatchState.claimedElsewhere;
        });

        _homeRadarExternalClaimCleanupTimer?.cancel();
        _homeRadarExternalClaimCleanupTimer = Timer(
          const Duration(milliseconds: 2800),
          () {
            if (!mounted ||
                _homeRadarStateFor(matchedOffer.id) !=
                    _HomeRadarMatchState.claimedElsewhere) {
              return;
            }
            _dismissRadarHomeOffer(matchedOffer);
          },
        );
      },
    );
  }

  void _cancelAllOfferTimers() {
    _outsideOfferTimeoutTimer?.cancel();
    _outsideOfferTimeoutTimer = null;
    _homeRadarMatchResolutionTimer?.cancel();
    _homeRadarNoticeTimer?.cancel();
    _homeRadarExternalClaimTimer?.cancel();
    _homeRadarExternalClaimCleanupTimer?.cancel();
    _homeRadarLostMatchTimer?.cancel();
    _homeRadarMatchingOfferId = null;
    _homeRadarMatchStates.clear();
    _homeRadarMatchNotice = null;
    for (final timer in _radarOfferTimeoutTimers.values) {
      timer.cancel();
    }
    _radarOfferTimeoutTimers.clear();
  }

  void _acceptOutsideRadarOffer() {
    final offer = _outsideRadarOffer;
    if (offer == null) return;

    _cancelAllOfferTimers();
    _expandedDirectOfferTimer?.cancel();
    _offerSimulationTimer?.cancel();
    _radarOfferTwoTimer?.cancel();
    _radarOfferThreeTimer?.cancel();

    Navigator.push(
      context,
      ActiveRideTransition(
        AcceptRide(
          offerId: offer.id,
          fare: offer.fare,
          category: offer.category,
          matchedVia: 'Exclusive Radar',
          waybillRepository: _waybills,
          sessionController: _driverSession,
          locationRepository: _driverLocationService,
          routeRepository: _roadRouteService,
          activeRideRepository: widget.activeRideRepository,
          pickupAddress: offer.pickup,
          pickupArea: offer.pickup.split(',').last.trim(),
          dropoffAddress: offer.dropoff,
          pickupPosition: offer.pickupPosition,
          dropoffPosition: offer.dropoffPosition,
        ),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _outsideRadarOffer = null;
        _radarHomeOffers.clear();
        _pendingRadarHomeOffers.clear();
        _hasRideOffers = false;
        _isDirectOfferRoutePreview = false;
        _directOfferRouteMarkers = {};
        _directOfferRoutePolylines = {};
      });
    });
  }

  void _acceptRadarHomeOffer(_HomeDirectOffer offer) {
    if (!_radarHomeOffers.any((item) => item.id == offer.id)) return;

    _cancelAllOfferTimers();
    _expandedDirectOfferTimer?.cancel();
    _offerSimulationTimer?.cancel();
    _radarOfferTwoTimer?.cancel();
    _radarOfferThreeTimer?.cancel();

    Navigator.push(
      context,
      ActiveRideTransition(
        AcceptRide(
          offerId: offer.id,
          fare: offer.fare,
          category: offer.category,
          matchedVia: 'Movera Radar',
          waybillRepository: _waybills,
          sessionController: _driverSession,
          locationRepository: _driverLocationService,
          routeRepository: _roadRouteService,
          activeRideRepository: widget.activeRideRepository,
          pickupAddress: offer.pickup,
          pickupArea: offer.pickup.split(',').last.trim(),
          dropoffAddress: offer.dropoff,
          pickupPosition: offer.pickupPosition,
          dropoffPosition: offer.dropoffPosition,
        ),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _outsideRadarOffer = null;
        _radarHomeOffers.clear();
        _pendingRadarHomeOffers.clear();
        _hasRideOffers = false;
        _isDirectOfferRoutePreview = false;
        _directOfferRouteMarkers = {};
        _directOfferRoutePolylines = {};
      });
    });
  }

  void _showAccountActivationDialog() {
    AccountActivationDialog.show(
      context,
      onAccountActivated: () {
        setState(() {
          isAccountActivated = true;
        });
        _showSuccessSnackbar();
      },
      onCancel: () {
        // Handle cancel if needed
      },
    );
  }

  bool hideMainPanel = false;
  // Add this method to open destination panel
  void openDestinationPanel() {
    // First close the main panel completely
    setState(() {
      hideMainPanel = true;
    });
    // Wait for main panel to close, then open destination panel
    Future.delayed(Duration(milliseconds: 100), () {
      _destinationPanelController.open();
    });
  }

  void _setMapGesturesBlocked(bool value) {
    if (!mounted || _blockMapGestures == value) return;
    setState(() {
      _blockMapGestures = value;
    });
  }

  void _onSheetPointerDown(PointerDownEvent event) {
    _sheetPointerActive = true;
    _sheetPointerLastY = event.position.dy;
    _sheetPointerLastMs = DateTime.now().millisecondsSinceEpoch;
    _sheetPointerVelocity = 0;
    _snapSheet.stopSpring();
    _setMapGesturesBlocked(true);
  }

  void _onSheetPointerMove(PointerEvent event) {
    _trackSheetPointer(event);
  }

  void _onSheetPointerEnd(PointerEvent event) {
    _trackSheetPointer(event);
    _sheetPointerActive = false;
    if (_mainPanelPosition <= 0.001) {
      _setMapGesturesBlocked(false);
    }
    // Let SlidingUpPanel finish its native release animation first. iOS web
    // can occasionally interrupt that settle and leave the sheet between
    // collapsed / middle / open, so a delayed guard normalizes the position.
    _scheduleHomeSheetPositionGuard(
      delay: const Duration(milliseconds: 460),
    );
  }

  void _scheduleHomeSheetPositionGuard({
    Duration delay = const Duration(milliseconds: 180),
  }) {
    _homeSheetPositionGuardTimer?.cancel();
    _homeSheetPositionGuardTimer = Timer(delay, () {
      if (!mounted ||
          _outsideRadarOffer != null ||
          _sheetPointerActive ||
          !_panelController.isAttached) {
        return;
      }

      final position = _panelController.panelPosition.clamp(0.0, 1.0);
      final snap = _homeSnapPoint(context);
      final nearestDistance = math.min(
        position.abs(),
        math.min((position - snap).abs(), (1 - position).abs()),
      );

      if (nearestDistance <= 0.025) return;
      unawaited(_snapHomeSheet(velocity: 0));
    });
  }

  Future<void> _openDriverSheet() async {
    _setMapGesturesBlocked(true);
    await _springPanelTo(1);
  }

  Future<void> _closeDriverSheet() async {
    await _springPanelTo(0);
  }

  double _homeSnapPoint(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final maxHeight = _homeExpandedHeight(context);
    final middleHeight = MoveraSheetMetrics.middleHeight(viewportHeight);
    final span = maxHeight - MoveraSheetMetrics.collapsedHeight;
    if (span <= 0) return 0.5;
    return ((middleHeight - MoveraSheetMetrics.collapsedHeight) / span)
        .clamp(0.08, 0.92);
  }

  double _homeExpandedHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height * _homeExpandedFraction;
  }

  void _trackSheetPointer(PointerEvent event) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_sheetPointerLastMs != 0) {
      final dt = math.max(1, now - _sheetPointerLastMs);
      _sheetPointerVelocity = (event.position.dy - _sheetPointerLastY) / dt * 1000;
    }
    _sheetPointerLastY = event.position.dy;
    _sheetPointerLastMs = now;
  }

  Future<void> _snapHomeSheet({double? velocity}) async {
    if (!_panelController.isAttached) return;
    _snapSheet.rangePx =
        _homeExpandedHeight(context) - MoveraSheetMetrics.collapsedHeight;
    final snap = _homeSnapPoint(context);
    final target = MoveraSheetMetrics.targetPosition(
      position: _panelController.panelPosition,
      velocityPxPerSec: velocity ?? _sheetPointerVelocity,
      snap: snap,
    );
    if ((target - _lastSnapHapticAt).abs() > 0.04) {
      unawaited(HapticFeedback.lightImpact());
      _lastSnapHapticAt = target;
    }
    await _snapSheet.springTo(
      target,
      velocityPxPerSec: velocity ?? _sheetPointerVelocity,
    );
  }

  void _settleHomeSheet({double? velocity}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_snapHomeSheet(velocity: velocity));
    });
  }

  Future<void> _springPanelTo(
    double target, {
    double velocityPxPerSec = 0,
  }) {
    _snapSheet.rangePx =
        _homeExpandedHeight(context) - MoveraSheetMetrics.collapsedHeight;
    return _snapSheet.springTo(target, velocityPxPerSec: velocityPxPerSec);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutViewport(
      child: Scaffold(
      key: _scaffoldKey,
      drawer: DriverSideMenu(
        isOnline: _isOnline,
        accountActive: isAccountActivated,
      ),
      body: showRideRequests
          ? Stack(
              fit: StackFit.expand,
              children: [
                AbsorbPointer(
                  child: _buildRadarMapBackdrop(),
                ),
                ClipRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 9.5, sigmaY: 9.5),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF172027).withOpacity(0.46),
                            const Color(0xFF6F7D80).withOpacity(0.16),
                            const Color(0xFFF4F7F8).withOpacity(0.24),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                PointerInterceptor(
                  child: const SizedBox.expand(),
                ),
                RideRequests(
                  destinationModeActive: _destinationModeActive,
                  destinationAddress: _destinationAddress,
                  sessionController: _driverSession,
                  waybillRepository: _waybills,
                  locationRepository: _driverLocationService,
                  routeRepository: _roadRouteService,
                  dispatchRepository: _dispatch,
                  activeRideRepository: widget.activeRideRepository,
                  onCloseRides: (hasOffers) {
                    setState(() {
                      showRideRequests = false;
                      _hasRideOffers =
                          hasOffers || _radarHomeOffers.isNotEmpty;
                    });
                  },
                ),
              ],
            )
          : hideMainPanel
          ? DestinationSetPanel(
              controller: _destinationPanelController,
              onClose: () {
                setState(() {
                  hideMainPanel = false;
                });
              },
              body: body(isDestinationPanel: true),
            )
          : SlidingUpPanel(
              color: Colors.transparent,
              backdropColor: Colors.transparent,
              backdropOpacity: 0,
              backdropEnabled: false,
              backdropTapClosesPanel: false,
              controller: _panelController,
              margin: EdgeInsets.all(0),
              minHeight: _outsideRadarOffer != null
                  ? 0
                  : MoveraSheetMetrics.collapsedHeight,
              padding: EdgeInsets.zero,
              boxShadow: [],
              isDraggable: _outsideRadarOffer == null,
              panelSnapping: _outsideRadarOffer == null,
              snapPoint: _homeSnapPoint(context),
              defaultPanelState: PanelState.CLOSED,
              maxHeight: _homeExpandedHeight(context),
              parallaxEnabled: false,
              onPanelSlide: (double pos) {
                _mainPanelPosition = pos;
                _panelSlidePosition.value = pos;
                if (!_sheetPointerActive) {
                  _scheduleHomeSheetPositionGuard();
                }
                if (pos > 0.04) {
                  _closeHomeFloatingPopupsForSheet();
                }
                final nextPanelOpen = pos > 0.3;
                final nextBlockMap = _sheetPointerActive || pos > 0.001;
                if (isPanelOpen != nextPanelOpen ||
                    _blockMapGestures != nextBlockMap) {
                  setState(() {
                    isPanelOpen = nextPanelOpen;
                    _blockMapGestures = nextBlockMap;
                  });
                }
              },
              onPanelOpened: () {
                _homeSheetPositionGuardTimer?.cancel();
                _mainPanelPosition = 1;
                _panelSlidePosition.value = 1;
                _closeHomeFloatingPopupsForSheet();
                _setMapGesturesBlocked(true);
              },
              onPanelClosed: () {
                _homeSheetPositionGuardTimer?.cancel();
                _mainPanelPosition = 0;
                _panelSlidePosition.value = 0;
                _sheetPointerActive = false;
                if (isPanelOpen) {
                  setState(() {
                    isPanelOpen = false;
                  });
                }
                _setMapGesturesBlocked(false);
              },
              collapsed: _outsideRadarOffer != null
                  ? const SizedBox.shrink()
                  : PointerInterceptor(
                      child: Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: _onSheetPointerDown,
                        onPointerMove: _onSheetPointerMove,
                        onPointerUp: _onSheetPointerEnd,
                        onPointerCancel: _onSheetPointerEnd,
                        child: DriverSheetNav.collapsedDock(
                          context: context,
                          scaffoldKey: _scaffoldKey,
                          isOnline: _isOnline,
                          hasRideOffers:
                              _hasRideOffers || _radarHomeOffers.isNotEmpty,
                          hasScheduledRideOffers: _hasScheduledRideOffers,
                          goOnlinePulseController: _goOnlinePulseController,
                          onOpenScheduledRides: _openScheduledRides,
                        ),
                      ),
                    ),

              panelBuilder: (ScrollController sc) => _outsideRadarOffer != null
                  ? const SizedBox.shrink()
                  : PointerInterceptor(
                      child: Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: _onSheetPointerDown,
                        onPointerMove: _onSheetPointerMove,
                        onPointerUp: _onSheetPointerEnd,
                        onPointerCancel: _onSheetPointerEnd,
                        child: panelColumn(sc),
                      ),
                    ),
              body: AbsorbPointer(
                absorbing: _blockMapGestures,
                child: body(),
              ),
            ),
      ),
    );
  }

  Widget _buildRadarMapBackdrop() {
    return SizedBox.expand(
      child: CustomGoogleMap(
        initialPosition: _initialPosition,
        markers: _markers,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: false,
        trafficEnabled: false,
        buildingsEnabled: true,
        indoorViewEnabled: false,
        scrollGesturesEnabled: false,
        zoomGesturesEnabled: false,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
        mapType: MapType.normal,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        onTap: (LatLng position) {},
      ),
    );
  }

  Widget body({bool isDestinationPanel = false}) {
    final viewport = MediaQuery.sizeOf(context);
    final viewportWidth = viewport.width;

    return SizedBox(
      height: viewport.height,
      width: viewportWidth,
      child: Stack(
        children: [
          CustomGoogleMap(
            initialPosition: _initialPosition,
            markers: {
              ..._markers,
              ..._destinationRouteMarkers,
              ..._directOfferRouteMarkers,
            },
            polylines: {
              ..._destinationRoutePolylines,
              ..._directOfferRoutePolylines,
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            trafficEnabled: false,
            buildingsEnabled: true,
            indoorViewEnabled: false,
            mapType: MapType.normal,
            padding: MapOverlayInsets.forHome(
              safeTop: MediaQuery.paddingOf(context).top,
              obscuredBottom: _homeMapObscuredBottom(context),
              hasTopBanner: _homeRadarMatchNotice != null,
            ).edgeInsets,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (_hasLiveDriverLocation) {
                unawaited(_animateToDriverLocation());
              }
            },
            onTap: (LatLng position) {},
          ),
          isDestinationPanel
              ? Align(
                  alignment: Alignment.center,
                  child: Image.asset(
                    AppAssets.destinationSelected,
                    height: ResSize.h * 241,
                  ),
                )
              : SizedBox(),
          isDestinationPanel
              ? Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 140, right: 30),
                    child: InkWell(
                      onTap: () {
                        showSafetyToolKitSheet(context);
                      },
                      child: Image.asset(
                        AppAssets.direction,
                        height: ResSize.h * 90,
                      ),
                    ),
                  ),
                )
              : SizedBox(),

          Visibility(
            visible: true,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: ResSize.h * 55,
                horizontal: screenHorizPadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: PointerInterceptor(
                      child: Container(
                        height: ResSize.h * 38.5,
                        width: ResSize.w * 83,
                        decoration: BoxDecoration(
                          color: AppColor.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFFF0F2F3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFF172027).withOpacity(0.11),
                              blurRadius: 18,
                              spreadRadius: 0,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Row(
                          children: [
                            Expanded(
                              child: Builder(
                                builder: (context) => InkWell(
                                  onTap: () {
                                    Scaffold.of(context).openDrawer();
                                  },
                                  child: Center(
                                    child: Icon(
                                      Icons.menu_open_rounded,
                                      size: ResSize.h * 17,
                                      color: AppColor.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _mapControlDivider(),
                            Expanded(
                              child: InkWell(
                                key: const ValueKey<String>(
                                  'destination-mode-open',
                                ),
                                onTap: _openDestinationModePicker,
                                child: Center(
                                  child: Image.asset(
                                    AppAssets.search,
                                    height: ResSize.h * 13,
                                    color: AppColor.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_destinationModeActive && !isDestinationPanel)
                    Padding(
                      padding: EdgeInsets.only(top: ResSize.h * 10),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: PointerInterceptor(
                          child: Material(
                            color: Colors.white,
                            elevation: 3,
                            shadowColor:
                                const Color(0xFF172027).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              key: const ValueKey<String>(
                                'destination-mode-home-tab',
                              ),
                              onTap: _fitDestinationRoute,
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: ResSize.w * 252,
                                ),
                                padding: EdgeInsets.fromLTRB(
                                  ResSize.w * 11,
                                  ResSize.h * 8,
                                  ResSize.w * 8,
                                  ResSize.h * 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      height: ResSize.h * 30,
                                      width: ResSize.h * 30,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0F5F2),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.near_me_rounded,
                                        size: 16,
                                        color: Color(0xFF315E4D),
                                      ),
                                    ),
                                    SizedBox(width: ResSize.w * 8),
                                    Flexible(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Destination',
                                            style: TextStyle(
                                              color: Color(0xFF7D898F),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            _destinationShortLabel,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF252E3A),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: ResSize.w * 6),
                                    InkWell(
                                      key: const ValueKey<String>(
                                        'destination-mode-end',
                                      ),
                                      onTap: _endDestinationMode,
                                      borderRadius: BorderRadius.circular(15),
                                      child: const SizedBox(
                                        height: 28,
                                        width: 28,
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 17,
                                          color: Color(0xFF7D898F),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (isDestinationPanel)
                    Padding(
                      padding: EdgeInsets.only(top: ResSize.h * 12),
                      child: InAirportQueue(),
                    ),
                ],
              ),
            ),
          ),

          if (!isDestinationPanel && _outsideRadarOffer == null)
            ValueListenableBuilder<double>(
              valueListenable: _panelSlidePosition,
              builder: (context, panelPosition, child) {
                final maxPanelHeight = _homeExpandedHeight(context);
                const minPanelHeight = MoveraSheetMetrics.collapsedHeight;
                final currentPanelHeight =
                    minPanelHeight +
                    ((maxPanelHeight - minPanelHeight) * panelPosition);

                // The 104px radar remains locked into the sheet's centre notch.
                // At the collapsed position this resolves to the existing
                // offline position (bottom: 58), and it follows the sheet
                // continuously while the driver drags it.
                final radarBottom = currentPanelHeight - 50;

                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: radarBottom,
                  child: Center(
                    child: _radarDragToSheet(
                      child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 480),
                      reverseDuration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final scale = Tween<double>(
                          begin: 0.97,
                          end: 1.0,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        );
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: scale,
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<String>(
                          _isOnline
                              ? 'radar-online'
                              : _isGoingOnline
                              ? 'radar-connecting'
                              : 'radar-offline',
                        ),
                        child: _isOnline
                            ? _buildTripRadarButton()
                            : _isGoingOnline
                            ? _buildGoingOnlineButton()
                            : _buildGoOnlineButton(),
                      ),
                    ),
                    ),
                  ),
                );
              },
            ),
          if (!isDestinationPanel &&
              _mainPanelPosition <= 0.04 &&
              _outsideRadarOffer != null &&
              _radarHomeOffers.isEmpty)
            Positioned(
              left: 14,
              right: 14,
              bottom: MediaQuery.paddingOf(context).bottom + 24,
              child: _buildOutsideRadarOfferCard(_outsideRadarOffer!),
            ),
          if (!isDestinationPanel &&
              _mainPanelPosition <= 0.04 &&
              _outsideRadarOffer == null &&
              _radarHomeOffers.isEmpty &&
              _pendingRadarHomeOffers.isNotEmpty)
            Positioned(
              left: 14,
              width: math.max(0, viewportWidth - 28),
              bottom: 178,
              child: _buildRadarRefreshPrompt(),
            ),
          if (!isDestinationPanel &&
              _mainPanelPosition <= 0.04 &&
              _outsideRadarOffer == null &&
              _radarHomeOffers.isNotEmpty)
            Positioned(
              left: 14,
              width: math.max(0, viewportWidth - 28),
              bottom: 178,
              child: _buildRadarOffersTray(),
            ),
          if (!isDestinationPanel) ...[
            if (_showTodaySummaryPopup)
              Positioned.fill(
                child: GestureDetector(
                  key: const ValueKey<String>('today-summary-scrim'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _hideTodaySummary,
                  child: ColoredBox(
                    color: const Color(0xFF172027).withOpacity(0.22),
                  ),
                ),
              ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 420),
              curve: _showTodaySummaryPopup
                  ? Curves.easeInCubic
                  : Curves.easeOutBack,
              left: _showTodaySummaryPopup ? -48 : -10,
              top: ResSize.h * 55,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _showTodaySummaryPopup ? 0 : 1,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const ValueKey<String>('last-trip-launcher'),
                    onTap: _showTodaySummary,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(22),
                    ),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0xFFF4F7F6),
                          ],
                        ),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(22),
                        ),
                        border: Border.all(
                          color: const Color(0xFFD9E2DE),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF172027).withOpacity(0.09),
                            blurRadius: 14,
                            offset: const Offset(3, 5),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.72),
                            blurRadius: 4,
                            offset: const Offset(-1, -1),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.history_rounded,
                              color: Color(0xFF344A41),
                              size: 18,
                            ),
                          ),
                          Positioned(
                            right: 7,
                            top: 8,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF58E5A6),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 460),
              curve: _showTodaySummaryPopup
                  ? Curves.easeOutCubic
                  : Curves.easeInCubic,
              left: _showTodaySummaryPopup ? 14 : -310,
              top: ResSize.h * 106,
              child: IgnorePointer(
                key: const ValueKey<String>('today-summary-pointer'),
                ignoring: !_showTodaySummaryPopup,
                child: AnimatedScale(
                  scale: _showTodaySummaryPopup ? 1 : 0.94,
                  duration: const Duration(milliseconds: 300),
                  curve: _showTodaySummaryPopup
                      ? Curves.easeOutBack
                      : Curves.easeInCubic,
                  alignment: Alignment.topLeft,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: _showTodaySummaryPopup ? 1 : 0,
                    child: _buildTodaySummaryPopup(),
                  ),
                ),
              ),
            ),
          ],
          if (!isDestinationPanel)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              left: 16,
              bottom: 138,
              child: _buildDriverLocationButton(),
            ),
          if (!isDestinationPanel)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              right: 16,
              bottom: 138,
              child: Material(
                color: AppColor.white,
                elevation: 4,
                shadowColor: const Color(0xFF1D2730).withOpacity(0.16),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () => showSafetyToolKitSheet(context),
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    height: 42,
                    width: 42,
                    child: Icon(
                      Icons.shield_outlined,
                      color: Color(0xFF3F4A50),
                      size: 17,
                    ),
                  ),
                ),
              ),
            ),
          if (!isDestinationPanel && _homeRadarMatchNotice != null)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: _buildHomeRadarMatchNotice(_homeRadarMatchNotice!),
            ),

        ],
      ),
    );
  }

  Widget _buildHomeRadarMatchNotice(_HomeRadarMatchNotice notice) {
    final isMatching =
        notice.type == _HomeRadarMatchNoticeType.matching;
    final isSuccess =
        notice.type == _HomeRadarMatchNoticeType.success;
    final accent = isSuccess
        ? const Color(0xFF2FBE7B)
        : isMatching
            ? const Color(0xFFD99B24)
            : const Color(0xFFC75B62);

    return TripStatusBanner(
      key: const ValueKey<String>('home-radar-match-notice'),
      title: notice.title,
      subtitle: notice.message,
      accent: accent,
      busy: isMatching,
      leading: isMatching
          ? null
          : Icon(
              isSuccess
                  ? Icons.check_rounded
                  : Icons.person_off_outlined,
              color: accent,
              size: 22,
            ),
    );
  }

  Widget _buildRadarRefreshPrompt() {
    final count = _pendingRadarHomeOffers.length;

    return RepaintBoundary(
      child: Material(
        color: const Color(0xFFF7F9F9).withOpacity(0.98),
        elevation: 8,
        shadowColor: const Color(0x3311181C),
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3DE),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.radar_rounded,
                  color: Color(0xFFD28A19),
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'New Radar trips',
                      style: TextStyle(
                        color: Color(0xFF252E3A),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      count.toString() +
                          (count == 1
                              ? ' new offer ready'
                              : ' new offers ready'),
                      style: const TextStyle(
                        color: Color(0xFF7C888E),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                key: const ValueKey<String>('radar-home-refresh-empty'),
                onPressed: _refreshRadarHomeOffers,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF9A650F),
                  backgroundColor: const Color(0xFFFFF3DE),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: const Text(
                  'Refresh',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadarTrayHeader(List<_HomeDirectOffer> offers) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;

        final title = Row(
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3DE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.radar_rounded,
                color: Color(0xFFD28A19),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trip Radar offers',
                    style: TextStyle(
                      color: Color(0xFF252E3A),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Stable list · refresh when new trips arrive',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF7C888E),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (_pendingRadarHomeOffers.isEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF26343A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${offers.length} live',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        );

        final refresh = TextButton.icon(
          key: const ValueKey<String>('radar-home-refresh'),
          onPressed: _refreshRadarHomeOffers,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF9A650F),
            backgroundColor: const Color(0xFFFFF3DE),
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 7,
            ),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          icon: const Icon(Icons.refresh_rounded, size: 15),
          label: Text(
            'Refresh · ${_pendingRadarHomeOffers.length} new',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(15, 13, 12, 10),
          child: _pendingRadarHomeOffers.isEmpty
              ? title
              : compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        title,
                        const SizedBox(height: 9),
                        Align(
                          alignment: Alignment.centerRight,
                          child: refresh,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: title),
                        const SizedBox(width: 8),
                        refresh,
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildRadarOffersTray() {
    final offers = List<_HomeDirectOffer>.unmodifiable(_radarHomeOffers);
    final trayHeight = math.min(
      390.0,
      MediaQuery.of(context).size.height * 0.45,
    );

    return RepaintBoundary(
      child: SizedBox(
        height: trayHeight,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9F9).withOpacity(0.98),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFDDE5E2)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF11181C).withOpacity(0.12),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildRadarTrayHeader(offers),
              const Divider(height: 1, color: Color(0xFFE3E8E6)),
              Expanded(
                child: ListView.separated(
                  key: const PageStorageKey<String>('radar-home-offers-list'),
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                  itemCount: offers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final offer = offers[index];
                    return RepaintBoundary(
                      key: ValueKey<String>('radar-offer-' + offer.id),
                      child: _buildRadarOpportunityCard(offer),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadarOpportunityCard(_HomeDirectOffer offer) {
    final matchState = _homeRadarStateFor(offer.id);
    final claimed = matchState == _HomeRadarMatchState.claimedElsewhere;
    final resolving = matchState == _HomeRadarMatchState.resolving;
    final blockOtherOffers =
        _homeRadarMatchingOfferId != null &&
        _homeRadarMatchingOfferId != offer.id;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: claimed ? 0.68 : 1,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: claimed || resolving
              ? null
              : () => _previewDirectOfferRoute(
                    offer.pickupPosition,
                    offer.dropoffPosition,
                  ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3DE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'RADAR',
                        style: TextStyle(
                          color: Color(0xFFB87512),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      offer.category,
                      style: const TextStyle(
                        color: Color(0xFF657178),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (!resolving)
                      InkWell(
                        onTap: () => _dismissRadarHomeOffer(offer),
                        borderRadius: BorderRadius.circular(16),
                        child: const SizedBox(
                          width: 30,
                          height: 30,
                          child: Icon(
                            Icons.close_rounded,
                            color: Color(0xFF89949A),
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        offer.fare,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF252E3A),
                          fontSize: 25,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.7,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFD7A02C),
                      size: 15,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      offer.rating,
                      style: const TextStyle(
                        color: Color(0xFF69757B),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _homeDirectLocationRow(
                  color: const Color(0xFF2FBE7B),
                  title:
                      '${offer.pickupMinutes} min · ${offer.pickupKm.toStringAsFixed(1)} km away',
                  subtitle: offer.pickup,
                ),
                const SizedBox(height: 8),
                _homeDirectLocationRow(
                  color: const Color(0xFF252E3A),
                  title:
                      '${offer.tripMinutes} min · ${offer.tripKm.toStringAsFixed(1)} km trip',
                  subtitle: offer.dropoff,
                ),
                const SizedBox(height: 12),
                if (claimed || resolving) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: claimed
                          ? const Color(0xFFF0F2F3)
                          : const Color(0xFFFFF3DE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          claimed
                              ? Icons.lock_outline_rounded
                              : Icons.sync_rounded,
                          size: 15,
                          color: claimed
                              ? const Color(0xFF7D898F)
                              : const Color(0xFFB87512),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            claimed
                                ? 'Matched by another driver'
                                : 'Confirming availability',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: claimed
                                  ? const Color(0xFF68747A)
                                  : const Color(0xFF9A650F),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: claimed || resolving
                          ? null
                          : () => _previewDirectOfferRoute(
                                offer.pickupPosition,
                                offer.dropoffPosition,
                              ),
                      icon: const Icon(Icons.alt_route_rounded, size: 16),
                      label: const Text('Route'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF315E4D),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 40,
                      child: FilledButton(
                        onPressed: claimed || resolving || blockOtherOffers
                            ? null
                            : () => _startHomeRadarMatch(offer),
                        style: FilledButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF252E3A),
                          disabledBackgroundColor: const Color(0xFFD9DEDF),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: const Color(0xFF727E83),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: resolving
                            ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 13,
                                    height: 13,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF727E83),
                                    ),
                                  ),
                                  SizedBox(width: 7),
                                  Text(
                                    'Matching…',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                claimed ? 'Matched' : 'Match',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutsideRadarOfferCard(_HomeDirectOffer offer) {
    const alertCoral = Color(0xFFFF765C);

    return AnimatedBuilder(
      animation: _goOnlinePulseController,
      builder: (context, child) {
        final pulse = _goOnlinePulseController.value;

        return Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: alertCoral.withOpacity(0.38 + (pulse * 0.28)),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: alertCoral.withOpacity(0.08 + (pulse * 0.07)),
                  blurRadius: 20 + (pulse * 8),
                  spreadRadius: pulse * 1.8,
                  offset: const Offset(0, 5),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9EEF1),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        offer.category,
                        style: const TextStyle(
                          color: Color(0xFF252E3A),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: alertCoral.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          offer.reason,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFB84F3D),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: _dismissOutsideRadarOffer,
                      borderRadius: BorderRadius.circular(20),
                      child: const SizedBox(
                        width: 34,
                        height: 34,
                        child: Icon(
                          Icons.close_rounded,
                          color: Color(0xFF7D898F),
                          size: 20,
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
                          color: Color(0xFF252E3A),
                          fontSize: 30,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.9,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFD7A02C),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      offer.rating,
                      style: const TextStyle(
                        color: Color(0xFF6F7B82),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  offer.detail,
                  style: const TextStyle(
                    color: Color(0xFF7D898F),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                TweenAnimationBuilder<double>(
                  key: ValueKey<String>('direct-offer-countdown-${offer.id}'),
                  tween: Tween<double>(begin: 1, end: 0),
                  duration: _outsideOfferLifetime,
                  builder: (context, remaining, child) {
                    final seconds = (remaining *
                            (_outsideOfferLifetime.inMilliseconds / 1000))
                        .ceil();

                    return Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: alertCoral,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Exclusive offer · ${seconds}s',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFB84F3D),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Flexible(
                              child: Text(
                                'Exclusive Radar',
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
                _homeDirectLocationRow(
                  color: AppColor.primary,
                  title:
                      '${offer.pickupMinutes} min · ${offer.pickupKm.toStringAsFixed(1)} km away',
                  subtitle: offer.pickup,
                ),
                const SizedBox(height: 9),
                _homeDirectLocationRow(
                  color: const Color(0xFF252E3A),
                  title:
                      '${offer.tripMinutes} min · ${offer.tripKm.toStringAsFixed(1)} km trip',
                  subtitle: offer.dropoff,
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _previewDirectOfferRoute(
                        offer.pickupPosition,
                        offer.dropoffPosition,
                      ),
                      icon: const Icon(Icons.alt_route_rounded, size: 17),
                      label: const Text('Route'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColor.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 42,
                      child: FilledButton(
                        onPressed: _acceptOutsideRadarOffer,
                        style: FilledButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF252E3A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Accept',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _homeDirectLocationRow({
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
                  color: Color(0xFF252E3A),
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
                  color: Color(0xFF7D898F),
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

  Widget _mapControlDivider() {
    return Container(
      height: ResSize.h * 22,
      width: 1,
      color: const Color(0xFFE2E5E7),
    );
  }

  void _onRadarSheetDragUpdate(DragUpdateDetails details) {
    if (!_panelController.isAttached) return;
    _snapSheet.stopSpring();
    final range = _homeExpandedHeight(context) - MoveraSheetMetrics.collapsedHeight;
    if (range <= 0) return;
    final next = (_panelController.panelPosition - details.delta.dy / range)
        .clamp(0.0, 1.0);
    _panelController.panelPosition = next;
  }

  void _onRadarSheetDragEnd(DragEndDetails details) {
    _settleHomeSheet(velocity: details.primaryVelocity ?? 0);
  }

  Widget _radarDragToSheet({required Widget child}) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: _onRadarSheetDragUpdate,
      onVerticalDragEnd: _onRadarSheetDragEnd,
      child: child,
    );
  }

  void _showTodaySummary() {
    if (_showTodaySummaryPopup) return;
    setState(() {
      _showTodaySummaryPopup = true;
    });
  }

  void _hideTodaySummary() {
    if (!_showTodaySummaryPopup) return;
    setState(() {
      _showTodaySummaryPopup = false;
    });
  }

  void _closeHomeFloatingPopupsForSheet() {
    if (!_showTodaySummaryPopup &&
        !showRideRequests &&
        !_isDirectOfferRoutePreview) {
      return;
    }

    setState(() {
      _showTodaySummaryPopup = false;
      showRideRequests = false;
      _isDirectOfferRoutePreview = false;
      _directOfferRouteMarkers = {};
      _directOfferRoutePolylines = {};
    });
  }

  Widget _buildTodaySummaryPopup() {
    return Material(
      color: Colors.transparent,
      child: Container(
        key: const ValueKey<String>('today-summary-card'),
        width: 278,
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFD7EBE1),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF19865C).withOpacity(0.10),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: const Color(0xFF172027).withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F5EE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: Color(0xFF19865C),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Today",
                    style: TextStyle(
                      color: Color(0xFF252E3A),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                InkWell(
                  key: const ValueKey<String>('today-history-button'),
                  onTap: () {
                    _hideTodaySummary();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DriverRideHistory(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'History',
                          style: TextStyle(
                            color: Color(0xFF19865C),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xFF19865C),
                          size: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: _hideTodaySummary,
                  borderRadius: BorderRadius.circular(16),
                  child: const SizedBox(
                    height: 28,
                    width: 28,
                    child: Icon(
                      Icons.close_rounded,
                      color: Color(0xFF7A858B),
                      size: 17,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFEAF6F0),
                    Color(0xFFF7FBF9),
                  ],
                ),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: const Color(0xFFD7EBE1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD7EBE1),
                      ),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Color(0xFF19865C),
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "183.25 kr",
                          style: TextStyle(
                            color: Color(0xFF19865C),
                            fontSize: 22,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Earnings today",
                          style: TextStyle(
                            color: Color(0xFF7B878E),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 7,
                    width: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2FBE7B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            _premiumActivityRow(
              icon: Icons.local_taxi_outlined,
              title: "3 rides",
              subtitle: "Completed today",
            ),
            const Divider(height: 1, color: Color(0xFFE6F5EE)),
            _premiumActivityRow(
              icon: Icons.route_outlined,
              title: "Central Station → Södermalm",
              subtitle: "Last trip • Comfort • 21:42",
              trailing: "126 kr",
            ),
          ],
        ),
      ),
    );
  }

  Widget _premiumActivityRow({
    required IconData icon,
    required String title,
    required String subtitle,
    String? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          SizedBox(
            height: 28,
            width: 28,
            child: Icon(
              icon,
              color: const Color(0xFF69757B),
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF252E3A),
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
                    color: Color(0xFF8A959B),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Text(
              trailing,
              style: const TextStyle(
                color: Color(0xFF252E3A),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _goOnline() {
    if (_driverSession.isSuspended) {
      unawaited(showDriverSuspendedSheet(context));
      return;
    }
    if (!isAccountActivated) {
      _showAccountActivationDialog();
      return;
    }

    _onlineTransitionTimer?.cancel();
    _offerSimulationTimer?.cancel();
    _directOfferTimer?.cancel();
    _cancelAllOfferTimers();
    _expandedDirectOfferTimer?.cancel();
    _radarOfferTwoTimer?.cancel();
    _radarOfferThreeTimer?.cancel();

    setState(() {
      _driverSession.beginGoingOnline();
      _hasRideOffers = false;
      _showTodaySummaryPopup = false;
      _outsideRadarOffer = null;
      _radarHomeOffers.clear();
      _pendingRadarHomeOffers.clear();
    });
    _clearDirectOfferRoute();
    unawaited(_startDriverLocation(moveCamera: true));

    _onlineTransitionTimer = Timer(
      const Duration(milliseconds: 1400),
      () {
        if (!mounted) return;
        setState(() {
          _driverSession.completeGoingOnline();
        });

        // Frontend demo only. Outside-Radar offers remain exclusive and
        // never enter the Trip Radar list.
        _directOfferTimer = Timer(
          const Duration(milliseconds: 2200),
          () {
            if (!mounted || !_isOnline) return;
            _showOutsideRadarOffer(_veryCloseDirectOffer);
          },
        );

        // Radar offers start only after the exclusive outside-Radar offer
        // has had its own presentation window.
        _offerSimulationTimer = Timer(
          const Duration(milliseconds: 11500),
          () {
            if (!mounted || !_isOnline) return;
            _showRadarHomeOffer(_radarHomeOffer);
          },
        );

        _radarOfferTwoTimer = Timer(
          const Duration(milliseconds: 14500),
          () {
            if (!mounted || !_isOnline) return;
            _showRadarHomeOffer(_radarHomeOffer2);
          },
        );

        _radarOfferThreeTimer = Timer(
          const Duration(milliseconds: 17500),
          () {
            if (!mounted || !_isOnline) return;
            _showRadarHomeOffer(_radarHomeOffer3);
          },
        );

        // Keep a second outside-Radar example available later, but never
        // show it while Radar offers are active.
        _expandedDirectOfferTimer = Timer(
          const Duration(milliseconds: 50000),
          () {
            if (!mounted ||
                !_isOnline ||
                _radarHomeOffers.isNotEmpty ||
                _hasRideOffers) {
              return;
            }
            _showOutsideRadarOffer(_expandedDirectOffer);
          },
        );
      },
    );
  }

  Future<void> _goOffline() async {
    _onlineTransitionTimer?.cancel();
    _offerSimulationTimer?.cancel();
    _directOfferTimer?.cancel();
    _cancelAllOfferTimers();
    _expandedDirectOfferTimer?.cancel();
    _radarOfferTwoTimer?.cancel();
    _radarOfferThreeTimer?.cancel();

    setState(() {
      _driverSession.setOnline(false);
      _hasRideOffers = false;
      _outsideRadarOffer = null;
      _radarHomeOffers.clear();
      _pendingRadarHomeOffers.clear();
      _destinationModeActive = false;
      _destinationAddress = null;
      _destinationPosition = null;
      _destinationRouteMarkers = {};
      _destinationRoutePolylines = {};
    });
    _clearDirectOfferRoute();
    await _closeDriverSheet();
  }

  void _openRideOffers() {
    if (_mainPanelPosition > 0.04 || isPanelOpen) {
      return;
    }
    setState(() {
      showRideRequests = true;
      _hasRideOffers = _radarHomeOffers.isNotEmpty;
    });
  }

  void _openScheduledRides() {
    setState(() {
      _hasScheduledRideOffers = false;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ScheduledRidesScreen(),
      ),
    );
  }

  Widget _buildGoOnlineButton() {
    return AnimatedBuilder(
      animation: _goOnlinePulseController,
      builder: (context, child) {
        final suspended = _driverSession.isSuspended;
        return _buildRadarOrb(
          title: suspended
              ? "Account"
              : isAccountActivated
              ? "Radar"
              : "Pending",
          status: suspended
              ? "PAUSED"
              : isAccountActivated
              ? "OFF"
              : "LOCKED",
          subtitle: suspended
              ? "Tap for details"
              : isAccountActivated
              ? "Tap to scan"
              : "Activation required",
          onTap: _goOnline,
          pulse: suspended ? 0 : _goOnlinePulseController.value,
        );
      },
    );
  }

  Widget _buildGoingOnlineButton() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _goOnlinePulseController,
        _radarSweepController,
      ]),
      builder: (context, child) {
        return _buildRadarOrb(
          title: "Radar",
          status: "STARTING",
          subtitle: "Connecting",
          active: true,
          loading: true,
          pulse: _goOnlinePulseController.value,
          sweep: _radarSweepController.value,
        );
      },
    );
  }

  Widget _buildTripRadarButton() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _goOnlinePulseController,
        _radarSweepController,
      ]),
      builder: (context, child) {
        final radarOfferCount = _radarHomeOffers.length;
        final pendingRadarCount = _pendingRadarHomeOffers.length;
        final hasRadarOffer =
            _hasRideOffers || radarOfferCount > 0 || pendingRadarCount > 0;

        return _buildRadarOrb(
          title: pendingRadarCount > 0
              ? pendingRadarCount.toString() + " new"
              : radarOfferCount > 1
              ? radarOfferCount.toString() + " offers"
              : hasRadarOffer
              ? "Trip found"
              : "Radar",
          status: hasRadarOffer ? "NEW" : "LIVE",
          subtitle: hasRadarOffer ? "Tap for Radar" : "Scanning",
          active: true,
          offer: hasRadarOffer,
          pulse: _goOnlinePulseController.value,
          sweep: _radarSweepController.value,
          onTap: hasRadarOffer ? _openRideOffers : null,
        );
      },
    );
  }

  Widget _buildRadarOrb({
    required String title,
    required String status,
    required String subtitle,
    VoidCallback? onTap,
    bool active = false,
    bool loading = false,
    bool offer = false,
    double pulse = 0,
    double sweep = 0,
  }) {
    return MoveraRadarOrb(
      title: title,
      status: status,
      subtitle: subtitle,
      onTap: onTap,
      active: active,
      loading: loading,
      offer: offer,
      pulse: pulse,
      sweep: sweep,
    );
  }

  bool _isVersionNewer(String candidate, String current) {
    List<int> parse(String value) {
      return value
          .split('.')
          .map((part) => int.tryParse(part) ?? 0)
          .toList(growable: true);
    }

    final a = parse(candidate);
    final b = parse(current);
    final length = math.max(a.length, b.length);

    while (a.length < length) {
      a.add(0);
    }
    while (b.length < length) {
      b.add(0);
    }

    for (var index = 0; index < length; index++) {
      if (a[index] > b[index]) return true;
      if (a[index] < b[index]) return false;
    }

    return false;
  }

  Future<void> _maybeShowAppUpdatePrompt() async {
    if (_updatePromptShown || !mounted) return;

    final update = _adminHomeConfig.update;
    if (!update.enabled ||
        !_isVersionNewer(update.latestVersion, _currentAppVersion)) {
      return;
    }

    _updatePromptShown = true;

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: !update.mandatory,
      enableDrag: !update.mandatory,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: const BoxDecoration(
            color: Color(0xFFF9FBFA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
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
              const SizedBox(height: 16),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F5EE),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.system_update_alt_rounded,
                  color: Color(0xFF19865C),
                  size: 27,
                ),
              ),
              const SizedBox(height: 13),
              Text(
                update.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF252E3A),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.35,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                update.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF7D898F),
                  fontSize: 11.5,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version ${update.latestVersion}',
                style: const TextStyle(
                  color: Color(0xFF19865C),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () async {
                    final rawUrl = update.updateUrl;
                    if (rawUrl == null || rawUrl.isEmpty) {
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Update link is unavailable right now. Try again later.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    final uri = Uri.tryParse(rawUrl);
                    if (uri != null) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF252E3A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    update.actionLabel,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              if (!update.mandatory) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text(
                    update.dismissLabel,
                    style: const TextStyle(
                      color: Color(0xFF66737A),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _openDriverEvent(DriverEventConfig event) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.28),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.76,
          minChildSize: 0.52,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF9FBFA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ListView(
                controller: controller,
                padding: EdgeInsets.zero,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        child: AspectRatio(
                          aspectRatio: 1.72,
                          child: Image.network(
                            event.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFE8EFEC),
                              child: const Icon(
                                Icons.event_outlined,
                                color: Color(0xFF19865C),
                                size: 34,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        top: 14,
                        child: _eventChip(event.category),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            color: Color(0xFF252E3A),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _eventDetailRow(
                          icon: Icons.calendar_today_outlined,
                          title: event.dateLabel,
                          subtitle: event.timeLabel,
                        ),
                        const SizedBox(height: 10),
                        _eventDetailRow(
                          icon: Icons.place_outlined,
                          title: event.location,
                          subtitle: 'Area',
                        ),
                        const SizedBox(height: 18),
                        Text(
                          event.description,
                          style: const TextStyle(
                            color: Color(0xFF58656C),
                            fontSize: 12,
                            height: 1.55,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF252E3A),
                            borderRadius: BorderRadius.circular(19),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.bolt_rounded,
                                    color: Color(0xFF74D6A8),
                                    size: 19,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Best time to be online',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                event.recommendedWindow,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                event.demandLabel,
                                style: const TextStyle(
                                  color: Color(0xFF9ED9BD),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                event.driverNote,
                                style: const TextStyle(
                                  color: Color(0xFFD5DDDA),
                                  fontSize: 10.5,
                                  height: 1.42,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Photo · ${event.imageCredit}',
                          style: const TextStyle(
                            color: Color(0xFF9AA4A9),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _eventDetailRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 37,
          height: 37,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5EF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF19865C),
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF252E3A),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF7D898F),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _eventChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5EF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF19865C),
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _driverEventCard(DriverEventConfig event) {
    return SizedBox(
      width: 252,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openDriverEvent(event),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 104,
                    width: double.infinity,
                    child: Image.network(
                      event.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFE8EFEC),
                        child: const Icon(
                          Icons.event_outlined,
                          color: Color(0xFF19865C),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: _eventChip(event.category),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF252E3A),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: Color(0xFF19865C),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${event.dateLabel} · ${event.timeLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF66737A),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 13,
                          color: Color(0xFF8D989D),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            event.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF8D989D),
                              fontSize: 9.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _performanceSummaryCard() {
    final performance = _adminHomeConfig.performance;
    final metrics = <({String label, String value, IconData icon})>[
      if (performance.showRating)
        (
          label: 'Rating',
          value: performance.rating.toStringAsFixed(2),
          icon: Icons.star_rounded,
        ),
      if (performance.showAcceptanceRate)
        (
          label: 'Acceptance',
          value: '${performance.acceptanceRate.toStringAsFixed(0)}%',
          icon: Icons.check_rounded,
        ),
      if (performance.showCancellationRate)
        (
          label: 'Cancellation',
          value: '${performance.cancellationRate.toStringAsFixed(1)}%',
          icon: Icons.close_rounded,
        ),
    ];

    if (metrics.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFF0F2F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance',
            style: TextStyle(
              color: Color(0xFF252E3A),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Your recent activity',
            style: TextStyle(
              color: Color(0xFF8A959A),
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              for (var index = 0; index < metrics.length; index++) ...[
                Expanded(
                  child: _performanceCell(
                    label: metrics[index].label,
                    value: metrics[index].value,
                    icon: metrics[index].icon,
                  ),
                ),
                if (index != metrics.length - 1)
                  Container(
                    width: 1,
                    height: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: const Color(0xFFEBEFF0),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _stockholmWorkStats() {
    final stats = _adminHomeConfig.stockholmWork;
    final strongest = stats.innerAreas.reduce(
      (current, next) =>
          next.demandPercent > current.demandPercent ? next : current,
    );
    return Container(
      key: const ValueKey<String>('stockholm-work-stats'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFD),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE0E9E5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF18392E).withOpacity(0.055),
            blurRadius: 28,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 43,
                width: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFF163D31),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF163D31).withOpacity(0.16),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_city_rounded,
                  color: Color(0xFFE8F6EF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.title,
                      style: const TextStyle(
                        color: Color(0xFF1E2932),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.35,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stats.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF84908E),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF173F32),
                  Color(0xFF245845),
                ],
              ),
              borderRadius: BorderRadius.circular(19),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF173F32).withOpacity(0.13),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: Color(0xFFBCE7D2),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Strongest area',
                        style: TextStyle(
                          color: Color(0xFFBFD5CC),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        strongest.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.15,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF7F1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    '${strongest.demandPercent}%',
                    style: const TextStyle(
                      color: Color(0xFF176F52),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < stats.innerAreas.length; i++) ...[
            _stockholmAreaRow(stats.innerAreas[i]),
            if (i != stats.innerAreas.length - 1)
              const SizedBox(height: 8),
          ],
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F8F6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE1EBE6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 28,
                      width: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDFE9E4)),
                      ),
                      child: const Icon(
                        Icons.explore_outlined,
                        size: 15,
                        color: Color(0xFF1B7D5C),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      stats.surroundingTitle,
                      style: const TextStyle(
                        color: Color(0xFF22312D),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.05,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final area in stats.surroundingAreas)
                      _stockholmSurroundingChip(area),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockholmSurroundingChip(StockholmAreaConfig area) {
    final status = area.demandLabel.toLowerCase();
    final isBusy = status == 'busy';
    final isQuiet = status == 'quiet';

    final background = isBusy
        ? const Color(0xFFE8F5EF)
        : isQuiet
            ? const Color(0xFFF3F5F4)
            : const Color(0xFFF0F7F3);
    final border = isBusy
        ? const Color(0xFFCFE7DC)
        : isQuiet
            ? const Color(0xFFE2E7E4)
            : const Color(0xFFDCE9E3);
    final accent = isBusy
        ? const Color(0xFF167653)
        : isQuiet
            ? const Color(0xFF98A49F)
            : const Color(0xFF65A98B);
    final textColor = isBusy
        ? const Color(0xFF155F47)
        : isQuiet
            ? const Color(0xFF737F7A)
            : const Color(0xFF526F64);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              boxShadow: isBusy
                  ? [
                      BoxShadow(
                        color: accent.withOpacity(0.20),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            area.name,
            style: TextStyle(
              color: textColor,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '${area.demandPercent}%',
            style: TextStyle(
              color: accent,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockholmAreaRow(StockholmAreaConfig area) {
    final busy = area.demandPercent >= 75;
    final accent =
        busy ? const Color(0xFF1C7D5B) : const Color(0xFF67A98C);
    final percent =
        (area.demandPercent / 100).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECE9)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 7,
                width: 7,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.18),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  area.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF26323A),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: busy
                      ? const Color(0xFFE9F5EF)
                      : const Color(0xFFF0F4F2),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  area.demandLabel,
                  style: TextStyle(
                    color: busy
                        ? const Color(0xFF177454)
                        : const Color(0xFF66756F),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 34,
                child: Text(
                  '${area.demandPercent}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: busy
                        ? const Color(0xFF166E50)
                        : const Color(0xFF5D6B66),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE9EEEC),
              borderRadius: BorderRadius.circular(99),
            ),
            clipBehavior: Clip.antiAlias,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: percent,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: busy
                          ? const [
                              Color(0xFF1A7958),
                              Color(0xFF4BA17F),
                            ]
                          : const [
                              Color(0xFF6DAE92),
                              Color(0xFF91C9AF),
                            ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _performanceCell({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 15,
          color: const Color(0xFF6B777C),
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF252E3A),
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.35,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF7D898F),
            fontSize: 9.2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _lastWaybillCard(WaybillRecord last) {
    return _sheetAlertCard(
      key: const ValueKey<String>('home-sheet-last-waybill'),
      icon: Icons.receipt_long_outlined,
      iconColor: const Color(0xFF315E4D),
      title: 'Last waybill',
      subtitle: '${last.service} · ${last.fare} · ${last.dropoff}',
      onTap: () {
        showMoveraWaybillSheet(
          context,
          last,
          title: 'Last waybill',
        );
      },
    );
  }

  Widget panelColumn(ScrollController sc) {
    const ink = Color(0xFF252E3A);
    const muted = Color(0xFF7B878E);

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        PhysicalShape(
          clipper: const RadarSheetClipper(
            notchWidth: 126,
            notchDepth: 58,
            cornerRadius: 24,
          ),
          color: const Color(0xFFFCFDFD),
          elevation: 8,
          shadowColor: const Color(0x3311181C),
          clipBehavior: Clip.antiAlias,
          child: Container(
            color: const Color(0xFFFCFDFD),
            child: Column(
              children: [
                const SizedBox(height: 88),
                Expanded(
                  child: ListView(
                    key: const PageStorageKey<String>('driver-overview-list'),
                    controller: sc,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(2, 2, 2, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Driver overview",
                                    style: TextStyle(
                                      color: ink,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.35,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Your shift at a glance",
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 4,
                                  backgroundColor: Color(0xFF2FBE7B),
                                ),
                                SizedBox(width: 7),
                                Text(
                                  "Ready",
                                  style: TextStyle(
                                    color: Color(0xFF19865C),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ValueListenableBuilder<WaybillRecord?>(
                        valueListenable: _waybills.lastListenable,
                        builder: (context, lastWaybill, _) {
                          if (lastWaybill == null) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _lastWaybillCard(lastWaybill),
                          );
                        },
                      ),
                      _performanceSummaryCard(),
                      if (_adminHomeConfig.scheduledRides.enabled) ...[
                        const SizedBox(height: 10),
                        _sheetAlertCard(
                          icon: Icons.event_available_outlined,
                          iconColor: const Color(0xFF7E8A93),
                          title: _adminHomeConfig.scheduledRides.title,
                          subtitle: _adminHomeConfig.scheduledRides.subtitle,
                          onTap: _openScheduledRides,
                        ),
                      ],
                      if (_adminHomeConfig.events
                          .where((event) => event.enabled)
                          .isNotEmpty) ...[
                        const SizedBox(height: 22),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _adminHomeConfig.eventsSectionTitle,
                                style: const TextStyle(
                                  color: ink,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.25,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _adminHomeConfig.eventsSectionSubtitle,
                                style: const TextStyle(
                                  color: Color(0xFF8A959A),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 208,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _adminHomeConfig.events
                                .where((event) => event.enabled)
                                .length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final events = _adminHomeConfig.events
                                  .where((event) => event.enabled)
                                  .toList(growable: false);
                              return _driverEventCard(events[index]);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _stockholmWorkStats(),
                      ],
                    ],
                  ),
                ),
                if (_isOnline)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _goOffline,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3F454A),
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                            color: Color(0xFFD5DCDF),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: TextWidget(
                          text: "Go offline",
                          color: const Color(0xFF3F454A),
                          fontSize: 14,
                          fontWeight: fwSemiBold,
                        ),
                      ),
                    ),
                  ),
                DriverSheetNav.sheetQuickActionsBar(
                  context: context,
                  scaffoldKey: _scaffoldKey,
                  hasScheduledRideOffers: _hasScheduledRideOffers,
                  goOnlinePulseController: _goOnlinePulseController,
                  onOpenScheduledRides: _openScheduledRides,
                ),
              ],
            ),
          ),
        ),
        DriverSheetNav.onlineEdgeDashOverlay(
          isOnline: _isOnline,
          hasRideOffers: _hasRideOffers || _radarHomeOffers.isNotEmpty,
        ),
      ],
    );
  }

  Widget _sheetAlertCard({
    Key? key,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      key: key,
      color: AppColor.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColor.white, size: 24),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: title,
                      color: const Color(0xFF252E3A),
                      fontSize: 15,
                      fontWeight: fwSemiBold,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      TextWidget(
                        text: subtitle,
                        color: const Color(0xFF667483),
                        fontSize: 11,
                        fontWeight: fwNormal,
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
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
  }

  Widget _driverStatCard({
    required String title,
    required String mainText,
    required Color mainColor,
    IconData? icon,
    Color? iconColor,
    String? badge,
    Color? badgeColor,
    String? footer,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 142),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextWidget(
                  text: title,
                  color: const Color(0xFF8A97A8),
                  fontSize: 12,
                  fontWeight: fwNormal,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9DA9B8),
                size: 19,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: TextWidget(
                  text: mainText,
                  color: mainColor,
                  fontSize: 19,
                  fontWeight: fwSemiBold,
                ),
              ),
            ],
          ),
          if (badge != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(5),
              ),
              child: TextWidget(
                text: badge,
                color: AppColor.white,
                fontSize: 11,
                fontWeight: fwSemiBold,
              ),
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: 10),
            TextWidget(
              text: footer,
              color: const Color(0xFF8A97A8),
              fontSize: 10,
              fontWeight: fwNormal,
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _homeSheetPositionGuardTimer?.cancel();
    _goOnlinePulseController.dispose();
    _onlineTransitionTimer?.cancel();
    _offerSimulationTimer?.cancel();
    _directOfferTimer?.cancel();
    _cancelAllOfferTimers();
    _expandedDirectOfferTimer?.cancel();
    _radarOfferTwoTimer?.cancel();
    _radarOfferThreeTimer?.cancel();
    _homeRadarMatchResolutionTimer?.cancel();
    _homeRadarNoticeTimer?.cancel();
    _homeRadarExternalClaimTimer?.cancel();
    _homeRadarExternalClaimCleanupTimer?.cancel();
    _homeRadarLostMatchTimer?.cancel();
    _driverLocationSubscription?.cancel();
    _radarSweepController.dispose();
    _panelSlidePosition.dispose();
    _snapSheet.dispose();
    _mapController = null;
    _driverSession.removeListener(_onDriverSessionChanged);
    if (_ownsDriverSession) {
      _driverSession.dispose();
    }
    final dispatch = _dispatch;
    if (_ownsDispatch && dispatch is DemoDispatchRepository) {
      dispatch.dispose();
    }
    super.dispose();
  }

  void _showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        clipBehavior: Clip.none,
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        content: Container(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColor.white,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              16.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextWidget(
                      text: "Account Approved!",
                      fontSize: 16,
                      fontWeight: fwBold,
                      color: AppColor.white,
                    ),
                    4.height,
                    TextWidget(
                      text:
                          "Your account has been approved. You can now go online and start accepting rides.",
                      fontSize: 12,
                      fontWeight: fwNormal,
                      color: AppColor.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }
}


enum _HomeRadarMatchState { available, resolving, claimedElsewhere }

enum _HomeRadarMatchNoticeType { matching, success, taken }

class _HomeRadarMatchNotice {
  const _HomeRadarMatchNotice({
    required this.type,
    required this.title,
    required this.message,
  });

  final _HomeRadarMatchNoticeType type;
  final String title;
  final String message;
}

class _HomeDirectOffer {
  final String id;
  final String category;
  final String reason;
  final String detail;
  final String fare;
  final String rating;
  final int pickupMinutes;
  final double pickupKm;
  final int tripMinutes;
  final double tripKm;
  final String pickup;
  final String dropoff;
  final LatLng pickupPosition;
  final LatLng dropoffPosition;

  const _HomeDirectOffer({
    required this.id,
    required this.category,
    required this.reason,
    required this.detail,
    required this.fare,
    required this.rating,
    required this.pickupMinutes,
    required this.pickupKm,
    required this.tripMinutes,
    required this.tripKm,
    required this.pickup,
    required this.dropoff,
    required this.pickupPosition,
    required this.dropoffPosition,
  });
}
