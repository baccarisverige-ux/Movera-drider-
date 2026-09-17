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

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  final PanelController _panelController = PanelController();
  final PanelController _destinationPanelController = PanelController();
  GoogleMapController? _mapController;
  bool visibleRecentRides = false;
  bool isPanelOpen = false;
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
              minHeight: ResSize.h * 122,
              padding: EdgeInsets.zero,
              boxShadow: [],
              isDraggable: true,
              defaultPanelState: PanelState.CLOSED,
              maxHeight: MediaQuery.of(context).size.height * 0.62,
              parallaxEnabled: false,
              onPanelSlide: (double pos) {
                setState(() {
                  isPanelOpen = pos > 0.3;
                });
              },
              collapsed: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCFDFD),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFE1E8EC)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF102F45).withOpacity(0.14),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _seatBeltHandle(onTap: _panelController.open),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Center(
                          child: InkWell(
                            onTap: isAccountActivated
                                ? () {
                                    setState(() {
                                      showRideRequests = true;
                                    });
                                  }
                                : _showAccountActivationDialog,
                            customBorder: const CircleBorder(),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Lottie.asset(
                                  AppAssets.circleGrow,
                                  height: 74,
                                  width: 74,
                                ),
                                Container(
                                  height: 58,
                                  width: 58,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF102F45),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF36C59A),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF36C59A)
                                            .withOpacity(0.32),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      AppAssets.homeImage1,
                                      height: 35,
                                      color: AppColor.white,
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
              panelBuilder: (ScrollController sc) => panelColumn(sc),
              body: body(),
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
    const ink = Color(0xFF102F45);
    const mint = Color(0xFF36C59A);
    const line = Color(0xFFE3E9EC);
    const muted = Color(0xFF74838D);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: isPanelOpen ? 1.0 : 0.0,
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        decoration: const BoxDecoration(
          color: Color(0xFFFCFDFD),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _seatBeltHandle(onTap: _panelController.close),
            Padding(
              padding: EdgeInsets.fromLTRB(
                screenHorizPadding,
                10,
                screenHorizPadding,
                8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextWidget(
                      text: "DRIVER MODE",
                      color: ink,
                      fontSize: 13,
                      fontWeight: fwSemiBold,
                    ),
                  ),
                  InkWell(
                    onTap: _panelController.close,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 38,
                      width: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: ink,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: line),
            Expanded(
              child: SingleChildScrollView(
                controller: sc,
                padding: EdgeInsets.fromLTRB(
                  screenHorizPadding,
                  20,
                  screenHorizPadding,
                  MediaQuery.paddingOf(context).bottom + 30,
                ),
                child: Column(
                  children: [
                    Container(
                      height: 72,
                      width: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF8F4),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: mint.withOpacity(0.45),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.local_taxi_rounded,
                        color: ink,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextWidget(
                      text: isAccountActivated
                          ? "Ready to drive"
                          : "Account pending",
                      color: ink,
                      fontSize: 22,
                      fontWeight: fwSemiBold,
                    ),
                    const SizedBox(height: 5),
                    TextWidget(
                      text: isAccountActivated
                          ? "Go online when you are ready"
                          : "Complete activation to start driving",
                      color: muted,
                      fontSize: 12,
                      fontWeight: fwNormal,
                    ),
                    const SizedBox(height: 18),
                    InkWell(
                      onTap: isAccountActivated
                          ? () {
                              _panelController.close().then((_) {
                                setState(() {
                                  showRideRequests = true;
                                });
                              });
                            }
                          : _showAccountActivationDialog,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        height: 56,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isAccountActivated
                              ? ink
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 30,
                              width: 30,
                              decoration: BoxDecoration(
                                color: isAccountActivated
                                    ? mint
                                    : Colors.grey.shade400,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.power_settings_new_rounded,
                                color: isAccountActivated
                                    ? ink
                                    : Colors.grey.shade700,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            TextWidget(
                              text: isAccountActivated
                                  ? "GO ONLINE"
                                  : "ACTIVATION REQUIRED",
                              color: isAccountActivated
                                  ? AppColor.white
                                  : Colors.grey.shade700,
                              fontSize: 13,
                              fontWeight: fwSemiBold,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColor.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: line),
                      ),
                      child: Column(
                        children: [
                          _driverMenuRow(
                            icon: Icons.alt_route_rounded,
                            title: "Set destination",
                            subtitle: "Find rides heading your way",
                            accent: mint,
                          ),
                          const Divider(
                            height: 1,
                            indent: 66,
                            color: line,
                          ),
                          _driverMenuRow(
                            icon: Icons.schedule_rounded,
                            title: "Driving time",
                            subtitle: "See today’s activity",
                            accent: const Color(0xFF5E7E91),
                          ),
                          const Divider(
                            height: 1,
                            indent: 66,
                            color: line,
                          ),
                          _driverMenuRow(
                            icon: Icons.shield_outlined,
                            title: "Safety centre",
                            subtitle: "Open driver safety tools",
                            accent: const Color(0xFFDF9B42),
                            onTap: () {
                              showSafetyToolKitSheet(context);
                            },
                          ),
                          const Divider(
                            height: 1,
                            indent: 66,
                            color: line,
                          ),
                          _driverMenuRow(
                            icon: Icons.auto_awesome_rounded,
                            title: "Rewards",
                            subtitle: "Offers and driver bonuses",
                            accent: const Color(0xFF7767D8),
                            onTap: () {
                              Navigator.push(
                                context,
                                BottomToTopTransition(Promotions()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seatBeltHandle({required VoidCallback onTap}) {
    return Semantics(
      button: true,
      label: "Toggle driver sheet",
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 30,
          width: 190,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 150,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF102F45),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Positioned(
                right: 8,
                child: Container(
                  height: 24,
                  width: 32,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCFDFD),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF102F45),
                      width: 2,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF36C59A),
                      borderRadius: BorderRadius.circular(4),
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

  Widget _driverMenuRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: title,
                    color: const Color(0xFF102F45),
                    fontSize: 13,
                    fontWeight: fwSemiBold,
                  ),
                  const SizedBox(height: 3),
                  TextWidget(
                    text: subtitle,
                    color: const Color(0xFF74838D),
                    fontSize: 10,
                    fontWeight: fwNormal,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFAAB6BD),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
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
