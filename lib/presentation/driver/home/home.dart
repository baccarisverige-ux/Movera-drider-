import 'dart:async';

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/home/components/account_activation_diaglog.dart';
import 'package:movera/presentation/driver/home/components/destination_set_panel.dart';
import 'package:movera/presentation/driver/my%20queue%20position/components/in_airport_queue.dart';
import 'package:movera/presentation/driver/promotions/promotions.dart';
import 'package:movera/presentation/driver/ride%20requests/ride_requests.dart';
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
              minHeight: 160,
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
                  color: Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(26),
                  ),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: _openDriverSheet,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                      child: _isOnline
                          ? _buildTripRadarButton()
                          : _isGoingOnline
                          ? _buildGoingOnlineButton()
                          : _buildGoOnlineButton(),
                    ),
                    const Spacer(),
                    _emptyBottomNavigation(),
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
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: ResSize.h * 48,
                      width: ResSize.w * 152,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColor.white.withOpacity(0.97),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: AppColor.white.withOpacity(0.9),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF172027).withOpacity(0.18),
                            blurRadius: 20,
                            offset: const Offset(0, 7),
                          ),
                          BoxShadow(
                            color: AppColor.white.withOpacity(0.7),
                            blurRadius: 2,
                            offset: const Offset(0, -1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Builder(
                            builder: (context) => _mapControlButton(
                              icon: Icons.menu_rounded,
                              semanticsLabel: "Menu",
                              onTap: () => Scaffold.of(context).openDrawer(),
                            ),
                          ),
                          const SizedBox(width: 3),
                          _mapControlButton(
                            icon: Icons.search_rounded,
                            semanticsLabel: "Search",
                            onTap: () {
                              showDriverSearchPickupLocationSheet(
                                context,
                                openDestinationPanel,
                              );
                            },
                          ),
                          const SizedBox(width: 3),
                          _mapControlButton(
                            icon: Icons.account_balance_wallet_rounded,
                            semanticsLabel: "Today's activity",
                            accent: true,
                            onTap: _showTodaySummary,
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

          // The former third floating map button was intentionally removed.


        ],
      ),
    );
  }

  Widget _mapControlButton({
    required IconData icon,
    required String semanticsLabel,
    required VoidCallback onTap,
    bool accent = false,
  }) {
    return Expanded(
      child: Semantics(
        button: true,
        label: semanticsLabel,
        child: Material(
          color: accent ? const Color(0xFFE4F6EF) : Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: const Color(0xFF2FBE7B).withOpacity(0.15),
            child: Center(
              child: Icon(
                icon,
                size: ResSize.h * 20,
                color: accent
                    ? const Color(0xFF158A5B)
                    : const Color(0xFF252E3A),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTodaySummary() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xFF111820).withOpacity(0.34),
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F7),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF111820).withOpacity(0.18),
                  blurRadius: 30,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5DCE0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's activity",
                            style: TextStyle(
                              color: Color(0xFF20282E),
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Live overview of your day",
                            style: TextStyle(
                              color: Color(0xFF7B878E),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: AppColor.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.pop(sheetContext),
                        child: const SizedBox(
                          height: 38,
                          width: 38,
                          child: Icon(
                            Icons.close_rounded,
                            color: Color(0xFF4C585F),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF18252E), Color(0xFF29414A)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF18252E).withOpacity(0.22),
                        blurRadius: 20,
                        offset: const Offset(0, 9),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 54,
                        width: 54,
                        decoration: BoxDecoration(
                          color: AppColor.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: AppColor.white.withOpacity(0.18),
                          ),
                        ),
                        child: const Icon(
                          Icons.payments_rounded,
                          color: Color(0xFF62D7AA),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "TOTAL EARNINGS TODAY",
                              style: TextStyle(
                                color: Color(0xFFAFC0C6),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              "183.25 kr",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 27,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.7,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF62D7AA).withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF62D7AA),
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "Updated",
                              style: TextStyle(
                                color: Color(0xFFBCEEDB),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _activityInfoCard(
                  icon: Icons.directions_car_filled_rounded,
                  iconBackground: const Color(0xFFE6F3FF),
                  iconColor: const Color(0xFF2879B9),
                  title: "3 rides",
                  subtitle: "Completed today",
                  trailingIcon: Icons.arrow_forward_ios_rounded,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColor.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE5E9EB)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A2730).withOpacity(0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 46,
                            width: 46,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF49D19A), Color(0xFF159666)],
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.route_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Last trip",
                                  style: TextStyle(
                                    color: Color(0xFF252E3A),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  "Comfort • 21:42",
                                  style: TextStyle(
                                    color: Color(0xFF7B878E),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            "126 kr",
                            style: TextStyle(
                              color: Color(0xFF20282E),
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFE8ECEE)),
                      const SizedBox(height: 14),
                      const Row(
                        children: [
                          SizedBox(
                            width: 22,
                            child: Column(
                              children: [
                                Icon(
                                  Icons.radio_button_checked_rounded,
                                  size: 16,
                                  color: Color(0xFF2FBE7B),
                                ),
                                SizedBox(
                                  height: 18,
                                  child: VerticalDivider(
                                    width: 1,
                                    thickness: 1.5,
                                    color: Color(0xFFC8D1D5),
                                  ),
                                ),
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 18,
                                  color: Color(0xFF252E3A),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Central Station",
                                  style: TextStyle(
                                    color: Color(0xFF39444A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 17),
                                Text(
                                  "Södermalm",
                                  style: TextStyle(
                                    color: Color(0xFF39444A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
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
        );
      },
    );
  }

  Widget _activityInfoCard({
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String title,
    required String subtitle,
    IconData? trailingIcon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E9EB)),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF252E3A),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF7B878E),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (trailingIcon != null)
            Icon(trailingIcon, color: const Color(0xFFA1ABB0), size: 16),
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

  Widget _buildGoOnlineButton() {
    return AnimatedBuilder(
      animation: _goOnlinePulseController,
      child: Center(
        child: TextWidget(
          text: isAccountActivated ? "Go online" : "Account pending",
          color: const Color(0xFF3F454A),
          fontSize: 17,
          fontWeight: fwSemiBold,
        ),
      ),
      builder: (context, child) {
        final pulse = _goOnlinePulseController.value;
        return Material(
          color: AppColor.white,
          elevation: 5 + (pulse * 2.5),
          shadowColor: const Color(0xFF252E3A)
              .withOpacity(0.24 + (pulse * 0.08)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Color.lerp(
                const Color(0xFFCDD5DA),
                const Color(0xFFAEBBC2),
                pulse,
              )!,
              width: 1.2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _goOnline,
            splashColor: const Color(0xFF252E3A).withOpacity(0.08),
            highlightColor: const Color(0xFF252E3A).withOpacity(0.05),
            child: SizedBox(
              height: 54,
              width: double.infinity,
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoingOnlineButton() {
    return Material(
      color: AppColor.white,
      elevation: 7,
      shadowColor: const Color(0xFF252E3A).withOpacity(0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFC4CED4), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 54,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _radarSweepController,
              child: const Icon(
                Icons.sync_rounded,
                color: Color(0xFF3F454A),
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            TextWidget(
              text: "Connecting to Movera",
              color: const Color(0xFF3F454A),
              fontSize: 15,
              fontWeight: fwSemiBold,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripRadarButton() {
    final radarOpacity = Tween<double>(
      begin: 0.35,
      end: 1,
    ).animate(_goOnlinePulseController);

    return Material(
      color: AppColor.white,
      elevation: 7,
      shadowColor: const Color(0xFF252E3A).withOpacity(0.28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFCDD5DA), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openRideOffers,
        splashColor: const Color(0xFF252E3A).withOpacity(0.08),
        child: SizedBox(
          height: 54,
          child: Row(
            children: [
              const SizedBox(width: 12),
              FadeTransition(
                opacity: _hasRideOffers
                    ? radarOpacity
                    : const AlwaysStoppedAnimation<double>(1),
                child: SizedBox(
                  height: 40,
                  width: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F4F5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF3F454A),
                            width: 1.4,
                          ),
                        ),
                      ),
                      Container(
                        height: 25,
                        width: 25,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF9AA6AD),
                          ),
                        ),
                      ),
                      RotationTransition(
                        turns: _radarSweepController,
                        child: const Icon(
                          Icons.navigation_rounded,
                          color: Color(0xFF3F454A),
                          size: 19,
                        ),
                      ),
                      const CircleAvatar(
                        radius: 3,
                        backgroundColor: Color(0xFF2FBE7B),
                      ),
                    ],
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
                      text: _hasRideOffers
                          ? "New ride request"
                          : "Finding a new trip",
                      color: const Color(0xFF30363B),
                      fontSize: 15,
                      fontWeight: fwSemiBold,
                    ),
                    const SizedBox(height: 2),
                    TextWidget(
                      text: _hasRideOffers
                          ? "A nearby passenger is waiting • Tap to view"
                          : "Searching for ride requests near you",
                      color: const Color(0xFF7B878E),
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
                    margin: const EdgeInsets.only(right: 14),
                    height: 10,
                    width: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2FBE7B),
                      shape: BoxShape.circle,
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
                    icon: Icons.calendar_month_outlined,
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
            _emptyBottomNavigation(),
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

  Widget _emptyBottomNavigation() {
    return Container(
      height: MediaQuery.paddingOf(context).bottom + 62,
      padding: EdgeInsets.fromLTRB(
        18,
        9,
        18,
        MediaQuery.paddingOf(context).bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: AppColor.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E7EB)),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SizedBox(width: 72, height: 44),
          SizedBox(width: 72, height: 44),
          SizedBox(width: 72, height: 44),
          SizedBox(width: 72, height: 44),
        ],
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
