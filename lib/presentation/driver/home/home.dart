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
              color: AppColor.white,
              backdropColor: Colors.transparent,
              backdropOpacity: 0,
              backdropEnabled: false, // Changed to false
              backdropTapClosesPanel: false,
              controller: _panelController,
              margin: EdgeInsets.all(0),
              minHeight: ResSize.h * 88,
              padding: EdgeInsets.zero,
              boxShadow: [],
              isDraggable: true,
              defaultPanelState: PanelState.CLOSED,
              maxHeight: MediaQuery.of(context).size.height * 0.54,
              parallaxEnabled: false,
              onPanelSlide: (double pos) {
                setState(() {
                  isPanelOpen = pos > 0.3;
                });
              },
              collapsed: InkWell(
                onTap: _panelController.open,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColor.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF183F5B).withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 7),
                      Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9E3E8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenHorizPadding,
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF153F5F),
                                      Color(0xFF2376A5),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Image.asset(
                                    AppAssets.logo,
                                    height: 23,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextWidget(
                                  text: isAccountActivated
                                      ? "Movera Drive  •  Ready for rides"
                                      : "Movera Drive  •  Account pending",
                                  fontSize: 13,
                                  fontWeight: fwSemiBold,
                                  color: const Color(0xFF153F5F),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                height: 36,
                                width: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF3F7),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(
                                  Icons.keyboard_arrow_up_rounded,
                                  size: 22,
                                  color: Color(0xFF153F5F),
                                ),
                              ),
                            ],
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
    const moveraNavy = Color(0xFF153F5F);
    const moveraBlue = Color(0xFF2376A5);
    const moveraMint = Color(0xFF36C59A);
    const moveraCanvas = Color(0xFFF4F8FA);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: isPanelOpen ? 1.0 : 0.0,
      child: Container(
        decoration: const BoxDecoration(
          color: moveraCanvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            8.height,
            Container(
              width: ResSize.w * 38,
              height: ResSize.h * 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD4E0E6),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                screenHorizPadding,
                ResSize.h * 8,
                screenHorizPadding,
                ResSize.h * 10,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: _panelController.close,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: ResSize.h * 36,
                      width: ResSize.w * 36,
                      decoration: BoxDecoration(
                        color: AppColor.white,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: ResSize.h * 23,
                        color: moveraNavy,
                      ),
                    ),
                  ),
                  12.width,
                  Expanded(
                    child: TextWidget(
                      text: "Driver hub",
                      color: moveraNavy,
                      fontSize: 18,
                      fontWeight: fwSemiBold,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResSize.w * 10,
                      vertical: ResSize.h * 6,
                    ),
                    decoration: BoxDecoration(
                      color: isAccountActivated
                          ? moveraMint.withOpacity(0.12)
                          : Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: TextWidget(
                      text: isAccountActivated ? "Ready" : "Pending",
                      color: isAccountActivated
                          ? moveraNavy
                          : Colors.orange.shade800,
                      fontSize: 11,
                      fontWeight: fwSemiBold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: sc,
                padding: EdgeInsets.fromLTRB(
                  screenHorizPadding,
                  0,
                  screenHorizPadding,
                  ResSize.h * 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(ResSize.h * 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [moveraNavy, moveraBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: ResSize.h * 46,
                            width: ResSize.w * 46,
                            decoration: BoxDecoration(
                              color: AppColor.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.local_taxi_rounded,
                              color: moveraMint,
                              size: ResSize.h * 25,
                            ),
                          ),
                          13.width,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextWidget(
                                  text: "Ready when you are",
                                  fontSize: 16,
                                  fontWeight: fwSemiBold,
                                  color: AppColor.white,
                                ),
                                4.height,
                                TextWidget(
                                  text:
                                      "Your route tools are prepared for the next drive.",
                                  fontSize: 11,
                                  fontWeight: fwNormal,
                                  color: AppColor.white.withOpacity(0.74),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    16.height,
                    TextWidget(
                      text: "Quick tools",
                      color: moveraNavy,
                      fontSize: 14,
                      fontWeight: fwSemiBold,
                    ),
                    10.height,
                    Row(
                      children: [
                        Expanded(
                          child: _hubToolCard(
                            icon: Icons.alt_route_rounded,
                            title: "Waybill",
                            subtitle: "Set destination",
                            color: moveraBlue,
                          ),
                        ),
                        10.width,
                        Expanded(
                          child: _hubToolCard(
                            icon: Icons.schedule_rounded,
                            title: "Driving time",
                            subtitle: "View activity",
                            color: moveraNavy,
                          ),
                        ),
                      ],
                    ),
                    10.height,
                    Row(
                      children: [
                        Expanded(
                          child: _hubToolCard(
                            icon: Icons.shield_outlined,
                            title: "Safety",
                            subtitle: "Driver toolkit",
                            color: moveraMint,
                            onTap: () {
                              showSafetyToolKitSheet(context);
                            },
                          ),
                        ),
                        10.width,
                        Expanded(
                          child: _hubToolCard(
                            icon: Icons.auto_awesome_rounded,
                            title: "Rewards",
                            subtitle: "Offers & bonuses",
                            color: const Color(0xFF7767D8),
                            onTap: () {
                              Navigator.push(
                                context,
                                BottomToTopTransition(Promotions()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                screenHorizPadding,
                ResSize.h * 10,
                screenHorizPadding,
                MediaQuery.paddingOf(context).bottom + ResSize.h * 10,
              ),
              decoration: BoxDecoration(
                color: AppColor.white,
                boxShadow: [
                  BoxShadow(
                    color: moveraNavy.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: InkWell(
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
                  height: ResSize.h * 50,
                  decoration: BoxDecoration(
                    gradient: isAccountActivated
                        ? const LinearGradient(
                            colors: [moveraNavy, moveraBlue],
                          )
                        : null,
                    color: isAccountActivated
                        ? null
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: ResSize.h * 28,
                        width: ResSize.w * 28,
                        decoration: BoxDecoration(
                          color: isAccountActivated
                              ? moveraMint
                              : Colors.grey.shade400,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.power_settings_new_rounded,
                          color: isAccountActivated
                              ? moveraNavy
                              : Colors.grey.shade700,
                          size: ResSize.h * 18,
                        ),
                      ),
                      10.width,
                      TextWidget(
                        text:
                            isAccountActivated ? "Go online" : "Account pending",
                        fontSize: 14,
                        fontWeight: fwSemiBold,
                        color: isAccountActivated
                            ? AppColor.white
                            : Colors.grey.shade700,
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

  Widget _hubToolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: EdgeInsets.all(ResSize.h * 12),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5EDF1)),
        ),
        child: Row(
          children: [
            Container(
              height: ResSize.h * 34,
              width: ResSize.w * 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.11),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: ResSize.h * 19,
              ),
            ),
            9.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: title,
                    color: const Color(0xFF153F5F),
                    fontSize: 12,
                    fontWeight: fwSemiBold,
                  ),
                  2.height,
                  TextWidget(
                    text: subtitle,
                    color: AppColor.subtitle,
                    fontSize: 9,
                    fontWeight: fwNormal,
                  ),
                ],
              ),
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
