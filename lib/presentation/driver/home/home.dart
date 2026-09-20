import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/accept%20ride/accept_ride.dart';
import 'package:movera/presentation/driver/destination%20mode/destination_picker.dart';
import 'package:movera/presentation/driver/home/components/account_activation_diaglog.dart';
import 'package:movera/presentation/driver/home/components/destination_set_panel.dart';
import 'package:movera/presentation/driver/home/components/driver_sheet_nav.dart';
import 'package:movera/presentation/driver/my%20queue%20position/components/in_airport_queue.dart';
import 'package:movera/presentation/driver/ride%20requests/ride_requests.dart';
import 'package:movera/presentation/driver/scheduled%20rides/scheduled_rides.dart';
import 'package:movera/presentation/driver/safety%20toolkits/safety_toolkits.dart';
import 'package:movera/presentation/driver/side%20menu/side_menu.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';
import 'package:movera/widgets/custom_google_map.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

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
  Timer? _offerSimulationTimer;
  Timer? _directOfferTimer;
  Timer? _directOfferTimeoutTimer;
  Timer? _expandedDirectOfferTimer;
  GoogleMapController? _mapController;
  bool isPanelOpen = false;
  bool _blockMapGestures = false;
  bool _sheetPointerActive = false;
  double _mainPanelPosition = 0;
  final ValueNotifier<double> _panelSlidePosition = ValueNotifier<double>(0);

  static const Duration _sheetMotionDuration = Duration(milliseconds: 420);
  static const Duration _directOfferLifetime = Duration(milliseconds: 8500);
  static const Curve _sheetMotionCurve = Curves.easeOutCubic;
  bool showRideRequests = false;
  bool isAccountActivated = true;
  bool _isGoingOnline = false;
  bool _isOnline = false;
  bool _hasRideOffers = false;
  bool _hasScheduledRideOffers = true;
  bool _showTodaySummaryPopup = false;
  _HomeDirectOffer? _homeDirectOffer;
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

  static const LatLng _driverPosition = LatLng(59.3293, 18.0686);
  static const CameraPosition _initialPosition = CameraPosition(
    target: _driverPosition,
    zoom: 14.0,
  );

  static const _HomeDirectOffer _veryCloseDirectOffer = _HomeDirectOffer(
    id: 'home-direct-close',
    category: 'Comfort',
    reason: 'Very close to you',
    detail: 'Direct request outside radar',
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
    reason: 'Expanded request',
    detail: 'No nearby radar driver matched',
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

  @override
  void initState() {
    super.initState();
    _goOnlinePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _radarSweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _loadMarkers();
  }

  void _loadMarkers() {
    _markers.add(
      Marker(
        markerId: MarkerId('driver_location'),
        position: _driverPosition,
        infoWindow: InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
  }

  Future<void> _previewDirectOfferRoute(
    LatLng pickup,
    LatLng dropoff,
  ) async {
    final south = pickup.latitude < dropoff.latitude
        ? pickup.latitude
        : dropoff.latitude;
    final north = pickup.latitude > dropoff.latitude
        ? pickup.latitude
        : dropoff.latitude;
    final west = pickup.longitude < dropoff.longitude
        ? pickup.longitude
        : dropoff.longitude;
    final east = pickup.longitude > dropoff.longitude
        ? pickup.longitude
        : dropoff.longitude;

    setState(() {
      _isDirectOfferRoutePreview = true;
      _directOfferRouteMarkers = {
        Marker(
          markerId: const MarkerId('radar_pickup'),
          position: pickup,
          infoWindow: const InfoWindow(title: 'Pickup'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
        Marker(
          markerId: const MarkerId('radar_dropoff'),
          position: dropoff,
          infoWindow: const InfoWindow(title: 'Drop-off'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
        ),
      };
      _directOfferRoutePolylines = {
        Polyline(
          polylineId: const PolylineId('direct_offer_route'),
          points: [pickup, dropoff],
          color: AppColor.primary,
          width: 6,
          geodesic: true,
        ),
      };
    });

    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted || _mapController == null) return;

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(south, west),
          northeast: LatLng(north, east),
        ),
        82,
      ),
    );
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
      _destinationRoutePolylines = {
        Polyline(
          polylineId: const PolylineId('destination_mode_route'),
          points: [_driverPosition, destination],
          color: AppColor.primary,
          width: 6,
          geodesic: true,
        ),
      };
    });

    await _fitDestinationRoute();

    if (!_isOnline && !_isGoingOnline) {
      _goOnline();
    }
  }

  Future<void> _fitDestinationRoute() async {
    final destination = _destinationPosition;
    if (destination == null || _mapController == null) return;

    final south = _driverPosition.latitude < destination.latitude
        ? _driverPosition.latitude
        : destination.latitude;
    final north = _driverPosition.latitude > destination.latitude
        ? _driverPosition.latitude
        : destination.latitude;
    final west = _driverPosition.longitude < destination.longitude
        ? _driverPosition.longitude
        : destination.longitude;
    final east = _driverPosition.longitude > destination.longitude
        ? _driverPosition.longitude
        : destination.longitude;

    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted || _mapController == null) return;

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(south, west),
          northeast: LatLng(north, east),
        ),
        74,
      ),
    );
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

  Future<void> _showHomeDirectOffer(
    _HomeDirectOffer offer,
  ) async {
    if (!mounted ||
        !_isOnline ||
        showRideRequests ||
        !_directOfferFollowsDestination(offer) ||
        _mainPanelPosition > 0.04 ||
        isPanelOpen) {
      return;
    }

    setState(() {
      _homeDirectOffer = offer;
    });

    _directOfferTimeoutTimer?.cancel();
    _directOfferTimeoutTimer = Timer(
      _directOfferLifetime,
      () {
        if (!mounted || _homeDirectOffer?.id != offer.id) return;
        _dismissHomeDirectOffer();
      },
    );

    await _previewDirectOfferRoute(
      offer.pickupPosition,
      offer.dropoffPosition,
    );
  }

  void _dismissHomeDirectOffer() {
    _directOfferTimeoutTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _homeDirectOffer = null;
    });
    _clearDirectOfferRoute();
  }

  void _acceptHomeDirectOffer() {
    if (_homeDirectOffer == null) return;

    _directOfferTimeoutTimer?.cancel();
    _expandedDirectOfferTimer?.cancel();
    _offerSimulationTimer?.cancel();

    setState(() {
      _homeDirectOffer = null;
    });
    _clearDirectOfferRoute();

    Navigator.push(
      context,
      BottomToTopTransition(const AcceptRide()),
    );
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
    _setMapGesturesBlocked(true);
  }

  void _onSheetPointerEnd(PointerEvent event) {
    _sheetPointerActive = false;
    if (_mainPanelPosition <= 0.001) {
      _setMapGesturesBlocked(false);
    }
  }

  Future<void> _openDriverSheet() async {
    _setMapGesturesBlocked(true);
    await _panelController.animatePanelToPosition(
      1,
      duration: _sheetMotionDuration,
      curve: _sheetMotionCurve,
    );
  }

  Future<void> _closeDriverSheet() async {
    await _panelController.animatePanelToPosition(
      0,
      duration: _sheetMotionDuration,
      curve: _sheetMotionCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const DriverSideMenu(),
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
                  onCloseRides: (hasOffers) {
                    setState(() {
                      showRideRequests = false;
                      _hasRideOffers = hasOffers;
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
                  // Any state updates when panel closes
                });
              },
              body: body(isDestinationPanel: true),
            )
          : SlidingUpPanel(
              color: Colors.transparent,
              backdropColor: Colors.transparent,
              backdropOpacity: 0,
              backdropEnabled: false, // Changed to false
              backdropTapClosesPanel: false,
              controller: _panelController,
              margin: EdgeInsets.all(0),
              minHeight: 108,
              padding: EdgeInsets.zero,
              boxShadow: [],
              isDraggable: true,
              defaultPanelState: PanelState.CLOSED,
              maxHeight: MediaQuery.of(context).size.height * 0.86,
              parallaxEnabled: false,
              onPanelSlide: (double pos) {
                _mainPanelPosition = pos;
                _panelSlidePosition.value = pos;
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
                _mainPanelPosition = 1;
                _panelSlidePosition.value = 1;
                _closeHomeFloatingPopupsForSheet();
                _setMapGesturesBlocked(true);
              },
              onPanelClosed: () {
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
              collapsed: PointerInterceptor(
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _onSheetPointerDown,
                  onPointerUp: _onSheetPointerEnd,
                  onPointerCancel: _onSheetPointerEnd,
                  child: DriverSheetNav.collapsedDock(
                    context: context,
                    scaffoldKey: _scaffoldKey,
                    isOnline: _isOnline,
                    hasScheduledRideOffers: _hasScheduledRideOffers,
                    goOnlinePulseController: _goOnlinePulseController,
                    onOpenScheduledRides: _openScheduledRides,
                  ),
                ),
              ),

              panelBuilder: (ScrollController sc) => PointerInterceptor(
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _onSheetPointerDown,
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
    );
  }

  Widget _buildRadarMapBackdrop() {
    return SizedBox.expand(
      child: CustomGoogleMap(
        initialPosition: _initialPosition,
        markers: _markers,
        myLocationEnabled: true,
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
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: double.infinity,
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
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            trafficEnabled: false,
            buildingsEnabled: true,
            indoorViewEnabled: false,
            mapType: MapType.normal,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
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

          if (!isDestinationPanel)
            ValueListenableBuilder<double>(
              valueListenable: _panelSlidePosition,
              builder: (context, panelPosition, child) {
                final maxPanelHeight =
                    MediaQuery.of(context).size.height * 0.86;
                const minPanelHeight = 108.0;
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
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 360),
                      reverseDuration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final scale = Tween<double>(
                          begin: 0.94,
                          end: 1.0,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutBack,
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
                );
              },
            ),
          if (!isDestinationPanel && _mainPanelPosition <= 0.04)
            Positioned(
              left: 14,
              right: 14,
              bottom: 178,
              child: IgnorePointer(
                ignoring: _homeDirectOffer == null,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  reverseDuration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0, 0.10),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    );
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: slide,
                        child: child,
                      ),
                    );
                  },
                  child: _homeDirectOffer == null
                      ? const SizedBox.shrink(
                          key: ValueKey<String>('no-direct-offer'),
                        )
                      : KeyedSubtree(
                          key: ValueKey<String>(_homeDirectOffer!.id),
                          child: _buildHomeDirectOfferCard(
                            _homeDirectOffer!,
                          ),
                        ),
                ),
              ),
            ),
          if (!isDestinationPanel) ...[
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
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 260),
                  opacity: _showTodaySummaryPopup ? 1 : 0,
                  child: _buildTodaySummaryPopup(),
                ),
              ),
            ),
          ],
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


        ],
      ),
    );
  }

  Widget _buildHomeDirectOfferCard(_HomeDirectOffer offer) {
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
                      onTap: _dismissHomeDirectOffer,
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
                    Text(
                      offer.fare,
                      style: const TextStyle(
                        color: Color(0xFF252E3A),
                        fontSize: 30,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.9,
                      ),
                    ),
                    const Spacer(),
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
                  duration: _directOfferLifetime,
                  builder: (context, remaining, child) {
                    final seconds = (remaining *
                            (_directOfferLifetime.inMilliseconds / 1000))
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
                            Text(
                              'Direct offer · ${seconds}s',
                              style: const TextStyle(
                                color: Color(0xFFB84F3D),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'Limited time',
                              style: TextStyle(
                                color: Color(0xFF8A9499),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
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
                        onPressed: _acceptHomeDirectOffer,
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
        _homeDirectOffer == null &&
        !showRideRequests) {
      return;
    }

    _directOfferTimeoutTimer?.cancel();
    setState(() {
      _showTodaySummaryPopup = false;
      _homeDirectOffer = null;
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
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFE2E8E5),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF172027).withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(5, 7),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Today",
                    style: TextStyle(
                      color: Color(0xFF252E3A),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
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
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7F7),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Row(
                children: [
                  Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      color: AppColor.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFDDE4E1),
                      ),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Color(0xFF435149),
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
                            color: Color(0xFF20282E),
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
            const SizedBox(height: 3),
            _premiumActivityRow(
              icon: Icons.local_taxi_outlined,
              title: "3 rides",
              subtitle: "Completed today",
            ),
            const Divider(height: 1, color: Color(0xFFE8ECEE)),
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
    if (!isAccountActivated) {
      _showAccountActivationDialog();
      return;
    }

    _onlineTransitionTimer?.cancel();
    _offerSimulationTimer?.cancel();
    _directOfferTimer?.cancel();
    _directOfferTimeoutTimer?.cancel();
    _expandedDirectOfferTimer?.cancel();

    setState(() {
      _isGoingOnline = true;
      _isOnline = false;
      _hasRideOffers = false;
      _showTodaySummaryPopup = false;
      _homeDirectOffer = null;
    });
    _clearDirectOfferRoute();

    _onlineTransitionTimer = Timer(
      const Duration(milliseconds: 1400),
      () {
        if (!mounted) return;
        setState(() {
          _isGoingOnline = false;
          _isOnline = true;
        });

        // Frontend demo only: a direct request appears on the normal Home map.
        _directOfferTimer = Timer(
          const Duration(milliseconds: 2200),
          () {
            if (!mounted || !_isOnline) return;
            _showHomeDirectOffer(_veryCloseDirectOffer);
          },
        );

        // Demo of the second allowed direct-dispatch condition.
        _expandedDirectOfferTimer = Timer(
          const Duration(milliseconds: 13000),
          () {
            if (!mounted || !_isOnline || _homeDirectOffer != null) return;
            _showHomeDirectOffer(_expandedDirectOffer);
          },
        );

        // Normal Trip Radar offers remain a separate flow and arrive later.
        _offerSimulationTimer = Timer(
          const Duration(milliseconds: 24500),
          () {
            if (!mounted ||
                !_isOnline ||
                _homeDirectOffer != null ||
                showRideRequests) {
              return;
            }

            setState(() {
              _hasRideOffers = true;
            });

            Future.delayed(const Duration(milliseconds: 260), () {
              if (!mounted ||
                  !_isOnline ||
                  !_hasRideOffers ||
                  _homeDirectOffer != null) {
                return;
              }
              _openRideOffers();
            });
          },
        );
      },
    );
  }

  Future<void> _goOffline() async {
    _onlineTransitionTimer?.cancel();
    _offerSimulationTimer?.cancel();
    _directOfferTimer?.cancel();
    _directOfferTimeoutTimer?.cancel();
    _expandedDirectOfferTimer?.cancel();

    setState(() {
      _isGoingOnline = false;
      _isOnline = false;
      _hasRideOffers = false;
      _homeDirectOffer = null;
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
    if (_homeDirectOffer != null ||
        _mainPanelPosition > 0.04 ||
        isPanelOpen) {
      return;
    }
    setState(() {
      showRideRequests = true;
      _hasRideOffers = false;
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
        return _buildRadarOrb(
          title: isAccountActivated ? "Radar" : "Pending",
          status: isAccountActivated ? "OFF" : "LOCKED",
          subtitle: isAccountActivated ? "Tap to scan" : "Activation required",
          onTap: _goOnline,
          pulse: _goOnlinePulseController.value,
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
          subtitle: "Going live",
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
        return _buildRadarOrb(
          title: _hasRideOffers ? "Trip found" : "Radar",
          status: _hasRideOffers ? "NEW" : "LIVE",
          subtitle: _hasRideOffers ? "Tap to view" : "Scanning",
          active: true,
          offer: _hasRideOffers,
          pulse: _goOnlinePulseController.value,
          sweep: _radarSweepController.value,
          onTap: _openRideOffers,
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
    const mint = Color(0xFF58E5A6);
    const detectedGold = Color(0xFFFFD166);
    const detectedAmber = Color(0xFFFFA94D);
    final accent = offer
        ? Color.lerp(detectedGold, detectedAmber, pulse) ?? detectedGold
        : mint;
    final glowStrength = active ? 0.14 + (pulse * 0.30) : 0.08;
    final ringScale = active ? 0.74 + (pulse * 0.38) : 1.0;
    final secondWaveScale = active ? 0.84 + ((1 - pulse) * 0.24) : 1.0;

    return Semantics(
      button: true,
      label: "$title, $status. $subtitle",
      child: GestureDetector(
        key: const ValueKey<String>('trip-radar-touch-target'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 104,
          height: 104,
          child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: ringScale,
              child: Container(
                width: 102,
                height: 102,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(active ? 0.04 : 0.025),
                  border: Border.all(
                    color: accent.withOpacity(active ? 0.30 : 0.15),
                    width: 1.2,
                  ),
                ),
              ),
            ),
            if (active)
              Transform.scale(
                scale: secondWaveScale,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(offer ? 0.045 : 0.025),
                    border: Border.all(
                      color: accent.withOpacity(offer ? 0.42 : 0.20),
                      width: offer ? 1.35 : 1.0,
                    ),
                  ),
                ),
              ),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(active ? 0.045 : 0.03),
                border: Border.all(
                  color: Colors.white.withOpacity(0.72),
                  width: 1.2,
                ),
              ),
            ),
            Container(
              width: 79,
              height: 79,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFBFD9CF).withOpacity(0.12),
                border: Border.all(
                  color: accent.withOpacity(active ? 0.38 : 0.19),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(glowStrength),
                    blurRadius: active ? 19 : 11,
                    spreadRadius: active ? 5 : 2,
                  ),
                ],
              ),
            ),
            if (active)
              Transform.rotate(
                angle: sweep * 6.283185307179586,
                child: SizedBox(
                  width: 75,
                  height: 75,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 2,
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accent.withOpacity(0),
                            accent.withOpacity(offer ? 0.95 : 0.78),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Material(
              color: Colors.transparent,
              elevation: 16,
              shadowColor: const Color(0xFF12201C).withOpacity(0.38),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: Ink(
                width: 73,
                height: 73,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.24, -0.32),
                    radius: 0.98,
                    colors: [
                      Color(0xD98F999C),
                      Color(0xD9727D80),
                      Color(0xE05A6468),
                    ],
                    stops: [0, 0.58, 1],
                  ),
                  border: Border.all(
                    color: offer
                        ? accent.withOpacity(0.82)
                        : const Color(0xD9E7ECEE),
                    width: offer ? 1.9 : 1.6,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3D263238),
                      blurRadius: 11,
                      offset: Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Color(0x66FFFFFF),
                      blurRadius: 3,
                      offset: Offset(-1, -2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: null,
                  customBorder: const CircleBorder(),
                  splashColor: accent.withOpacity(0.14),
                  highlightColor: accent.withOpacity(0.07),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                            width: 1,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        child: Container(
                          width: offer ? 7 : 5,
                          height: offer ? 7 : 5,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withOpacity(0.86),
                                blurRadius: offer ? 11 : 7,
                                spreadRadius: offer ? 2.5 : 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 16, 6, 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8.8,
                                height: 1.1,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2.5),
                            Text(
                              status,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: offer
                                    ? accent
                                    : const Color(0xFFE2E9E6),
                                fontSize: 6.1,
                                height: 1,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.9,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              width: 10,
                              height: 1,
                              color: Colors.white.withOpacity(0.36),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFB7C2BE),
                                fontSize: 5.9,
                                height: 1.12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (loading)
                        Positioned(
                          bottom: 5,
                          child: SizedBox(
                            width: 8,
                            height: 8,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.1,
                              color: accent.withOpacity(0.90),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget panelColumn(ScrollController sc) {
    const ink = Color(0xFF252E3A);
    const muted = Color(0xFF7B878E);

    return Stack(
      clipBehavior: Clip.none,
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
                const SizedBox(height: 62),
                Expanded(
                  child: ListView(
                    controller: sc,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
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
                      _sheetAlertCard(
                        icon: Icons.event_available_outlined,
                        iconColor: const Color(0xFF7E8A93),
                        title: "Scheduled rides available",
                        subtitle: "View open requests in your area",
                      ),
                      const SizedBox(height: 10),
                      _driverStatCard(
                        title: "Star rating",
                        mainText: "★ 4.88",
                        mainColor: ink,
                      ),
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
        DriverSheetNav.onlineEdgeDashOverlay(isOnline: _isOnline),
      ],
    );
  }

  Widget _sheetAlertCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
      ),
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
        ],
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
    _goOnlinePulseController.dispose();
    _onlineTransitionTimer?.cancel();
    _offerSimulationTimer?.cancel();
    _directOfferTimer?.cancel();
    _directOfferTimeoutTimer?.cancel();
    _expandedDirectOfferTimer?.cancel();
    _radarSweepController.dispose();
    _panelSlidePosition.dispose();
    _mapController?.dispose();
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
