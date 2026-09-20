import 'dart:async';
import 'dart:ui' as ui;

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/accept%20ride/accept_ride.dart';
import 'package:movera/presentation/driver/home/components/account_activation_diaglog.dart';
import 'package:movera/presentation/driver/home/components/destination_set_panel.dart';
import 'package:movera/presentation/driver/home/components/driver_sheet_nav.dart';
import 'package:movera/presentation/driver/my%20queue%20position/components/in_airport_queue.dart';
import 'package:movera/presentation/driver/ride%20requests/ride_requests.dart';
import 'package:movera/presentation/driver/scheduled%20rides/scheduled_rides.dart';
import 'package:movera/presentation/driver/safety%20toolkits/safety_toolkits.dart';
import 'package:movera/presentation/driver/search%20location/pickup_location.dart';
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
  static const Curve _sheetMotionCurve = Curves.easeOutCubic;
  bool showRideRequests = false;
  bool isAccountActivated = true;
  bool _isGoingOnline = false;
  bool _isOnline = false;
  bool _hasRideOffers = false;
  bool _hasScheduledRideOffers = true;
  bool _showTodaySummaryPopup = false;
  _HomeDirectOffer? _homeDirectOffer;

  // ignore: prefer_final_fields
  Set<Marker> _markers = {};
  Set<Marker> _directOfferRouteMarkers = {};
  Set<Polyline> _directOfferRoutePolylines = {};
  bool _isDirectOfferRoutePreview = false;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(59.3293, 18.0686),
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
        position: LatLng(59.3293, 18.0686),
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
    if (!mounted || !_isOnline || showRideRequests) return;

    await _closeDriverSheet();
    if (!mounted || !_isOnline || showRideRequests) return;

    setState(() {
      _homeDirectOffer = offer;
    });

    await _previewDirectOfferRoute(
      offer.pickupPosition,
      offer.dropoffPosition,
    );

    _directOfferTimeoutTimer?.cancel();
    _directOfferTimeoutTimer = Timer(
      const Duration(milliseconds: 8500),
      () {
        if (!mounted || _homeDirectOffer?.id != offer.id) return;
        _dismissHomeDirectOffer();
      },
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
                  onCloseRides: () {
                    setState(() {
                      showRideRequests = false;
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
              ..._directOfferRouteMarkers,
            },
            polylines: _directOfferRoutePolylines,
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
                children: [
                  Align(
                    alignment: Alignment.centerRight,
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
                            color: const Color(0xFF172027).withOpacity(0.11),
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
                              onTap: () {
                                showDriverSearchPickupLocationSheet(
                                  context,
                                  openDestinationPanel,
                                );
                              },
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
                  isDestinationPanel
                      ? Padding(
                          padding: EdgeInsets.only(top: ResSize.h * 12),
                          child: InAirportQueue(),
                        )
                      : SizedBox(),
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
          if (!isDestinationPanel)
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
              left: _showTodaySummaryPopup ? -58 : -12,
              top: MediaQuery.sizeOf(context).height * 0.44,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _showTodaySummaryPopup ? 0 : 1,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showTodaySummary,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(19),
                    ),
                    child: Container(
                      width: 62,
                      height: 50,
                      padding: const EdgeInsets.only(left: 14, right: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FBFA),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(19),
                        ),
                        border: Border.all(
                          color: const Color(0xFFDDE5E1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF172027).withOpacity(0.13),
                            blurRadius: 16,
                            offset: const Offset(4, 5),
                          ),
                        ],
                      ),
                      alignment: Alignment.centerRight,
                      child: const Icon(
                        Icons.insights_rounded,
                        color: Color(0xFF315E4D),
                        size: 21,
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
              left: _showTodaySummaryPopup ? 14 : -360,
              top: MediaQuery.sizeOf(context).height * 0.25,
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
              bottom: _homeDirectOffer == null ? 138 : 458,
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
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColor.primary.withOpacity(0.34),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF11181C).withOpacity(0.18),
              blurRadius: 28,
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
                      color: const Color(0xFFE9F6F0),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      offer.reason,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF257658),
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

  Widget _buildTodaySummaryPopup() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 330,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFE2E8E5),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF172027).withOpacity(0.16),
              blurRadius: 28,
              offset: const Offset(8, 10),
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
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                InkWell(
                  onTap: _hideTodaySummary,
                  borderRadius: BorderRadius.circular(20),
                  child: const SizedBox(
                    height: 36,
                    width: 36,
                    child: Icon(
                      Icons.close_rounded,
                      color: Color(0xFF7A858B),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 17),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7F7),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
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
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "183.25 kr",
                          style: TextStyle(
                            color: Color(0xFF20282E),
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          "Total earnings today",
                          style: TextStyle(
                            color: Color(0xFF7B878E),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 8,
                    width: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2FBE7B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
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
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          SizedBox(
            height: 34,
            width: 34,
            child: Icon(
              icon,
              color: const Color(0xFF69757B),
              size: 21,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF8A959B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            Text(
              trailing,
              style: const TextStyle(
                color: Color(0xFF252E3A),
                fontSize: 14,
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
    });
    _clearDirectOfferRoute();
    await _closeDriverSheet();
  }

  void _openRideOffers() {
    if (_homeDirectOffer != null) return;
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
          title: isAccountActivated ? "Trip radar" : "Account pending",
          status: isAccountActivated ? "OFFLINE" : "UNAVAILABLE",
          subtitle: isAccountActivated
              ? "Tap to start\nscanning"
              : "Activation required",
          onTap: _goOnline,
          pulse: _goOnlinePulseController.value,
        );
      },
    );
  }

  Widget _buildGoingOnlineButton() {
    return AnimatedBuilder(
      animation: _radarSweepController,
      builder: (context, child) {
        return _buildRadarOrb(
          title: "Trip radar",
          status: "CONNECTING",
          subtitle: "Starting nearby\nride scanning",
          active: true,
          loading: true,
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
          title: _hasRideOffers ? "New ride" : "Finding new trips",
          status: _hasRideOffers ? "RIDE AVAILABLE" : "SCANNING",
          subtitle: _hasRideOffers
              ? "Tap to view\nthe offer"
              : "Searching nearby\nrequests",
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
    final glowStrength = active ? 0.12 + (pulse * 0.28) : 0.08;
    final ringScale = active ? 0.76 + (pulse * 0.40) : 1.0;

    return Semantics(
      button: true,
      label: "$title, $status. $subtitle",
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
                  color: mint.withOpacity(active ? 0.035 : 0.025),
                  border: Border.all(
                    color: mint.withOpacity(active ? 0.22 : 0.15),
                    width: 1.2,
                  ),
                ),
              ),
            ),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: mint.withOpacity(active ? 0.045 : 0.03),
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
                  color: mint.withOpacity(active ? 0.30 : 0.19),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: mint.withOpacity(glowStrength),
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
                            mint.withOpacity(0),
                            mint.withOpacity(0.72),
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
                    color: const Color(0xD9E7ECEE),
                    width: 1.6,
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
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  splashColor: mint.withOpacity(0.12),
                  highlightColor: mint.withOpacity(0.06),
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
                            color: offer ? const Color(0xFFFFD166) : mint,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (offer
                                        ? const Color(0xFFFFD166)
                                        : mint)
                                    .withOpacity(0.82),
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
                                    ? const Color(0xFFFFD166)
                                    : const Color(0xFFD8E1DE),
                                fontSize: 5.4,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
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
                              color: mint.withOpacity(0.85),
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
