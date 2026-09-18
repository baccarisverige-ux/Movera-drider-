import 'dart:async';

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/support/support_inbox.dart';
import 'package:movera/presentation/driver/home/components/account_activation_diaglog.dart';
import 'package:movera/presentation/driver/home/components/destination_set_panel.dart';
import 'package:movera/presentation/driver/my%20queue%20position/components/in_airport_queue.dart';
import 'package:movera/presentation/driver/my%20wallet/wallet.dart';
import 'package:movera/presentation/driver/promotions/promotions.dart';
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
  GoogleMapController? _mapController;
  bool isPanelOpen = false;
  bool _blockMapGestures = false;
  bool _sheetPointerActive = false;
  double _mainPanelPosition = 0;

  static const Duration _sheetMotionDuration = Duration(milliseconds: 420);
  static const Curve _sheetMotionCurve = Curves.easeOutCubic;
  bool showRideRequests = false;
  bool isAccountActivated = true;
  bool _isGoingOnline = false;
  bool _isOnline = false;
  bool _hasRideOffers = false;
  bool _hasScheduledRideOffers = true;

  // ignore: prefer_final_fields
  Set<Marker> _markers = {};

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(59.3293, 18.0686),
    zoom: 14.0,
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
          ? RideRequests(
              onCloseRides: () {
                setState(() {
                  showRideRequests = false;
                });
              },
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
              minHeight: 88,
              padding: EdgeInsets.zero,
              boxShadow: [],
              isDraggable: true,
              defaultPanelState: PanelState.CLOSED,
              maxHeight: MediaQuery.of(context).size.height * 0.86,
              parallaxEnabled: false,
              onPanelSlide: (double pos) {
                _mainPanelPosition = pos;
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
                _setMapGesturesBlocked(true);
              },
              onPanelClosed: () {
                _mainPanelPosition = 0;
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
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF7F8F9),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(26),
                      ),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: _openDriverSheet,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 7, bottom: 3),
                            child: Container(
                              width: 38,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD5DADF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: _emptyBottomNavigation(showQuickActions: true),
                        ),
                      ],
                    ),
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

  Widget body({bool isDestinationPanel = false}) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: double.infinity,
      child: Stack(
        children: [
          CustomGoogleMap(
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
                      height: ResSize.h * 52,
                      width: ResSize.w * 112,
                      decoration: BoxDecoration(
                        color: AppColor.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFFF0F2F3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF172027).withOpacity(0.13),
                            blurRadius: 24,
                            spreadRadius: 1,
                            offset: const Offset(0, 9),
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
                                    size: ResSize.h * 22,
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
                                  height: ResSize.h * 17,
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
            Positioned(
              left: 0,
              right: 0,
              bottom: 104,
              child: Center(
                child: _isOnline
                    ? _buildTripRadarButton()
                    : _isGoingOnline
                    ? _buildGoingOnlineButton()
                    : _buildGoOnlineButton(),
              ),
            ),
          if (!isDestinationPanel)
            Positioned(
              left: 18,
              top: ResSize.h * 55,
              child: Material(
                color: AppColor.white,
                elevation: 6,
                shadowColor: const Color(0xFF1D2730).withOpacity(0.20),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () => showSafetyToolKitSheet(context),
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    height: 52,
                    width: 52,
                    child: Icon(
                      Icons.shield_outlined,
                      color: Color(0xFF3F4A50),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),


        ],
      ),
    );
  }

  Widget _mapControlDivider() {
    return Container(
      height: ResSize.h * 28,
      width: 1,
      color: const Color(0xFFE2E5E7),
    );
  }

  void _showTodaySummary() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xFF172027).withOpacity(0.30),
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF172027).withOpacity(0.12),
                  blurRadius: 28,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE2E5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 14),
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
                      onTap: () => Navigator.pop(sheetContext),
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
      },
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

    setState(() {
      _isGoingOnline = true;
      _isOnline = false;
      _hasRideOffers = false;
    });

    _onlineTransitionTimer = Timer(
      const Duration(milliseconds: 1400),
      () {
        if (!mounted) return;
        setState(() {
          _isGoingOnline = false;
          _isOnline = true;
        });

        // Frontend demo: replace this timer with the backend ride-offer stream.
        _offerSimulationTimer = Timer(
          const Duration(milliseconds: 2800),
          () {
            if (!mounted || !_isOnline) return;
            setState(() {
              _hasRideOffers = true;
            });
          },
        );
      },
    );
  }

  Future<void> _goOffline() async {
    _onlineTransitionTimer?.cancel();
    _offerSimulationTimer?.cancel();
    setState(() {
      _isGoingOnline = false;
      _isOnline = false;
      _hasRideOffers = false;
    });
    await _closeDriverSheet();
  }

  void _openRideOffers() {
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
        final pulse = _goOnlinePulseController.value;
        return Material(
          color: Colors.transparent,
          elevation: 5 + (pulse * 2),
          shadowColor: const Color(0xFF263238).withOpacity(0.18),
          borderRadius: BorderRadius.circular(27),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            width: 246,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFDDE1E4),
              borderRadius: BorderRadius.circular(27),
              border: Border.all(
                color: Color.lerp(
                  const Color(0xFFC8CED2),
                  const Color(0xFFADB7BD),
                  pulse,
                )!,
              ),
            ),
            child: InkWell(
              onTap: _goOnline,
              borderRadius: BorderRadius.circular(27),
              splashColor: const Color(0xFF202A30).withOpacity(0.08),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC9D0D4),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFAAB4BA)),
                    ),
                    child: const Icon(
                      Icons.radar_rounded,
                      color: Color(0xFF68747B),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          text: isAccountActivated
                              ? "Trip radar"
                              : "Account pending",
                          color: const Color(0xFF303A40),
                          fontSize: 14,
                          fontWeight: fwSemiBold,
                        ),
                        const SizedBox(height: 2),
                        TextWidget(
                          text: isAccountActivated
                              ? "Offline • Tap to start"
                              : "Activation is required",
                          color: const Color(0xFF727E85),
                          fontSize: 10,
                          fontWeight: fwNormal,
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 14),
                    child: Icon(
                      Icons.power_settings_new_rounded,
                      color: Color(0xFF59666D),
                      size: 20,
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

  Widget _buildGoingOnlineButton() {
    return Material(
      color: Colors.transparent,
      elevation: 8,
      shadowColor: const Color(0xFF10181D).withOpacity(0.30),
      borderRadius: BorderRadius.circular(27),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        width: 270,
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF39454B), Color(0xFF232D32)],
          ),
          borderRadius: BorderRadius.circular(27),
        ),
        child: Row(
          children: [
            const SizedBox(width: 9),
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF2FBE7B).withOpacity(0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF52D99A).withOpacity(0.55),
                ),
              ),
              child: RotationTransition(
                turns: _radarSweepController,
                child: const Icon(
                  Icons.radar_rounded,
                  color: Color(0xFF52D99A),
                  size: 25,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: "Starting trip radar",
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: fwSemiBold,
                  ),
                  const SizedBox(height: 3),
                  TextWidget(
                    text: "Connecting to nearby requests",
                    color: const Color(0xFFB3BDC2),
                    fontSize: 10,
                    fontWeight: fwNormal,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF52D99A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripRadarButton() {
    final radarOpacity = Tween<double>(
      begin: 0.45,
      end: 1,
    ).animate(_goOnlinePulseController);

    return Material(
      color: Colors.transparent,
      elevation: 9,
      shadowColor: const Color(0xFF10181D).withOpacity(0.34),
      borderRadius: BorderRadius.circular(27),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        width: 278,
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF263239), Color(0xFF172127)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(27),
          border: Border.all(color: const Color(0xFF3C494F)),
        ),
        child: InkWell(
          onTap: _openRideOffers,
          borderRadius: BorderRadius.circular(27),
          splashColor: const Color(0xFF2FBE7B).withOpacity(0.16),
          child: Row(
            children: [
              const SizedBox(width: 9),
              FadeTransition(
                opacity: _hasRideOffers
                    ? radarOpacity
                    : const AlwaysStoppedAnimation<double>(1),
                child: SizedBox(
                  height: 44,
                  width: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2FBE7B).withOpacity(0.13),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF52D99A).withOpacity(0.70),
                          ),
                        ),
                      ),
                      Container(
                        height: 27,
                        width: 27,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF52D99A).withOpacity(0.42),
                          ),
                        ),
                      ),
                      RotationTransition(
                        turns: _radarSweepController,
                        child: const Icon(
                          Icons.radar_rounded,
                          color: Color(0xFF52D99A),
                          size: 25,
                        ),
                      ),
                      const CircleAvatar(
                        radius: 2.7,
                        backgroundColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: _hasRideOffers
                          ? "New ride available"
                          : "Finding new trips",
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: fwSemiBold,
                    ),
                    const SizedBox(height: 3),
                    TextWidget(
                      text: _hasRideOffers
                          ? "Tap to review the offer"
                          : "Scanning nearby requests",
                      color: const Color(0xFFADB8BE),
                      fontSize: 10,
                      fontWeight: fwNormal,
                    ),
                  ],
                ),
              ),
              if (_hasRideOffers)
                FadeTransition(
                  opacity: radarOpacity,
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    height: 10,
                    width: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF52D99A),
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF87949B),
                    size: 22,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget panelColumn(ScrollController sc) {
    const canvas = Color(0xFFF1F3F5);
    const ink = Color(0xFF252E3A);
    const muted = Color(0xFF8A97A8);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: isPanelOpen ? 1.0 : 0.0,
      child: Container(
        decoration: const BoxDecoration(
          color: canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: _closeDriverSheet,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE2E7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: sc,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                children: [
                  _sheetAlertCard(
                    icon: Icons.event_available_outlined,
                    iconColor: const Color(0xFF8F9CAF),
                    title: "Scheduled rides available",
                    subtitle: "View open requests in your area",
                  ),
                  const SizedBox(height: 12),
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
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _goOffline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3F454A),
                      backgroundColor: AppColor.white,
                      side: const BorderSide(
                        color: Color(0xFFBFC9CF),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: TextWidget(
                      text: "Go offline",
                      color: const Color(0xFF3F454A),
                      fontSize: 15,
                      fontWeight: fwSemiBold,
                    ),
                  ),
                ),
              ),
            _emptyBottomNavigation(showQuickActions: true),
          ],
        ),
      ),
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
        borderRadius: BorderRadius.circular(17),
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
        borderRadius: BorderRadius.circular(17),
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

  Widget _emptyBottomNavigation({bool showQuickActions = false}) {
    if (!showQuickActions) return const SizedBox.shrink();

    return Container(
      height: MediaQuery.paddingOf(context).bottom + 62,
      padding: EdgeInsets.fromLTRB(
        16,
        2,
        16,
        MediaQuery.paddingOf(context).bottom + 4,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8F9),
        border: Border(
          top: BorderSide(color: Color(0xFFE8EBED)),
        ),
      ),
      child: Row(
        children: [
          _sheetQuickAction(
            icon: Icons.grid_view_rounded,
            tooltip: "Menu",
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          _sheetQuickAction(
            icon: Icons.wallet_outlined,
            tooltip: "Wallet",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WalletScreen()),
              );
            },
          ),
          _sheetQuickAction(
            icon: Icons.forum_outlined,
            tooltip: "Inbox",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportInboxScreen()),
              );
            },
          ),
          AnimatedBuilder(
            animation: _goOnlinePulseController,
            builder: (context, child) {
              return _sheetQuickAction(
                icon: Icons.calendar_month_outlined,
                tooltip: "Scheduled",
                onTap: _openScheduledRides,
                hasAlert: _hasScheduledRideOffers,
                pulse: _goOnlinePulseController.value,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sheetQuickAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool hasAlert = false,
    double pulse = 0,
  }) {
    final alertStrength = hasAlert ? (0.55 + (pulse * 0.45)) : 0.0;

    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            splashColor: const Color(0xFF2FBE7B).withOpacity(0.12),
            child: SizedBox(
              height: 50,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon,
                    color: hasAlert
                        ? const Color(0xFF16895B)
                        : const Color(0xFF3F4A50),
                    size: 24,
                  ),
                  if (hasAlert)
                    Positioned(
                      top: 7,
                      right: 13,
                      child: Opacity(
                        opacity: alertStrength,
                        child: Container(
                          height: 8,
                          width: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2FBE7B),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _goOnlinePulseController.dispose();
    _onlineTransitionTimer?.cancel();
    _offerSimulationTimer?.cancel();
    _radarSweepController.dispose();
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
