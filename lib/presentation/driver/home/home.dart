// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/accept%20ride/accept_ride.dart';
import 'package:movera/presentation/driver/home/components/account_activation_diaglog.dart';
import 'package:movera/presentation/driver/home/components/destination_set_panel.dart';
import 'package:movera/presentation/driver/home/components/recent_rides.dart';
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
import 'package:lottie/lottie.dart' hide Marker;
import 'package:pointer_interceptor/pointer_interceptor.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome>
    with SingleTickerProviderStateMixin {
  final PanelController _panelController = PanelController();
  final PanelController _destinationPanelController = PanelController();
  late final AnimationController _goOnlinePulseController;
  GoogleMapController? _mapController;
  bool visibleRecentRides = false;
  bool isPanelOpen = false;
  bool _blockMapGestures = false;
  bool _sheetPointerActive = false;
  double _mainPanelPosition = 0;

  static const Duration _sheetMotionDuration = Duration(milliseconds: 420);
  static const Curve _sheetMotionCurve = Curves.easeOutCubic;
  bool showRideRequests = false;
  bool isAccountActivated = true;

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
                      child: InkWell(
                        onTap: isAccountActivated
                            ? () {
                                setState(() {
                                  showRideRequests = true;
                                });
                              }
                            : _showAccountActivationDialog,
                        borderRadius: BorderRadius.circular(24),
                        child: AnimatedBuilder(
                          animation: _goOnlinePulseController,
                          child: Center(
                            child: TextWidget(
                              text: isAccountActivated
                                  ? "Go online"
                                  : "Account pending",
                              color: const Color(0xFF4B5157),
                              fontSize: 17,
                              fontWeight: fwSemiBold,
                            ),
                          ),
                          builder: (context, child) {
                            final pulse = _goOnlinePulseController.value;
                            return Container(
                              height: 54,
                              decoration: BoxDecoration(
                                color: AppColor.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Color.lerp(
                                    const Color(0xFFDDE3E7),
                                    const Color(0xFFB9C5CC),
                                    pulse,
                                  )!,
                                  width: 1 + (pulse * 0.45),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF252E3A)
                                        .withOpacity(0.04 + (pulse * 0.08)),
                                    blurRadius: 8 + (pulse * 12),
                                    spreadRadius: pulse * 1.2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: child,
                            );
                          },
                        ),
                      ),
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
            visible: visibleRecentRides ? false : true,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: ResSize.h * 55,
                horizontal: screenHorizPadding,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: ResSize.h * 32,
                        width: ResSize.w * 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.white,
                        ),
                        child: Builder(
                          builder: (context) => GestureDetector(
                            onTap: () {
                              Scaffold.of(context).openDrawer();
                            },
                            child: Center(
                              child: Icon(
                                Icons.menu_rounded,
                                size: ResSize.h * 20,
                                color: AppColor.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              visibleRecentRides = true;
                            });
                          },
                          icon: Image.asset(
                            AppAssets.logo,
                            height: ResSize.h * 22,
                          ),
                        ),
                      ),
                      Container(
                        height: ResSize.h * 32,
                        width: ResSize.w * 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.white,
                        ),
                        child: Center(
                          child: GestureDetector(
                            onTap: () {
                              showDriverSearchPickupLocationSheet(
                                context,
                                openDestinationPanel,
                              );
                            },
                            child: Image.asset(
                              AppAssets.search,
                              height: ResSize.h * 16,
                              color: AppColor.black,
                            ),
                          ),
                        ),
                      ),
                    ],
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

          isDestinationPanel
              ? SizedBox()
              : Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(top: ResSize.h * 100),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          BottomToTopTransition(AcceptRide()),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.only(
                          right: screenHorizPadding,
                          top: ResSize.h * 10,
                        ),
                        height: ResSize.h * 32,
                        width: ResSize.w * 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.white,
                        ),
                        child: Center(
                          child: Lottie.asset(AppAssets.circleGrow),
                        ),
                      ),
                    ),
                  ),
                ),

          visibleRecentRides
              ? Padding(
                  padding: EdgeInsets.only(top: ResSize.h * 20),
                  child: DriverHomeRecentRides(
                    onVisible: () {
                      setState(() {
                        visibleRecentRides = false;
                      });
                    },
                  ),
                )
              : SizedBox(),
        ],
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
