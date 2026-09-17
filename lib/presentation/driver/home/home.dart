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
              minHeight: ResSize.h * 65,
              padding: EdgeInsets.symmetric(vertical: ResSize.h * 19),
              boxShadow: [],
              isDraggable: true,
              defaultPanelState: PanelState.CLOSED,
              maxHeight: ResSize.h * 340,
              parallaxEnabled: false,
              onPanelSlide: (double pos) {
                setState(() {
                  isPanelOpen = pos > 0.3;
                });
              },
              collapsed: InkWell(
                onTap: () {
                  _panelController.open();
                },
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenHorizPadding,
                      ),
                      child: AnimatedOpacity(
                        duration: Duration(milliseconds: 150),
                        opacity: isPanelOpen ? 0.0 : 1.0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  AppAssets.wallet2,
                                  height: ResSize.h * 20,
                                  color: AppColor.title,
                                ),
                                8.width,
                                TextWidget(
                                  text: "Wallet",
                                  fontSize: 14,
                                  fontWeight: fwMedium,
                                  color: AppColor.title,
                                ),
                              ],
                            ),
                            Expanded(
                              child: Center(
                                child: TextWidget(
                                  text: isAccountActivated
                                      ? "Ready to go online"
                                      : "Account pending",
                                  fontSize: 14,
                                  fontWeight: fwMedium,
                                  color: isAccountActivated
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ),
                            Image.asset(
                              AppAssets.menu,
                              height: ResSize.h * 12,
                              color: AppColor.title,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
    const moveraMint = Color(0xFF39C6A3);
    const sheetBackground = Color(0xFFF6F9FB);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: isPanelOpen ? 1.0 : 0.0,
      child: Container(
        decoration: const BoxDecoration(
          color: sheetBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              width: ResSize.w * 38,
              height: ResSize.h * 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD6E0E6),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            10.height,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: Row(
                children: [
                  InkWell(
                    onTap: _panelController.close,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: ResSize.h * 34,
                      width: ResSize.w * 34,
                      decoration: BoxDecoration(
                        color: AppColor.white,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: const Color(0xFFE5EDF1),
                        ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          text: "Movera cockpit",
                          color: moveraNavy,
                          fontSize: 17,
                          fontWeight: fwSemiBold,
                        ),
                        2.height,
                        TextWidget(
                          text: "Plan your next move",
                          color: AppColor.subtitle,
                          fontSize: 11,
                          fontWeight: fwNormal,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResSize.w * 10,
                      vertical: ResSize.h * 6,
                    ),
                    decoration: BoxDecoration(
                      color: moveraMint.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: ResSize.w * 7,
                          height: ResSize.h * 7,
                          decoration: const BoxDecoration(
                            color: moveraMint,
                            shape: BoxShape.circle,
                          ),
                        ),
                        6.width,
                        TextWidget(
                          text: isAccountActivated ? "Ready" : "Pending",
                          color: isAccountActivated
                              ? moveraNavy
                              : Colors.orange.shade800,
                          fontSize: 11,
                          fontWeight: fwSemiBold,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            14.height,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(ResSize.h * 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [moveraNavy, moveraBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: moveraNavy.withOpacity(0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      height: ResSize.h * 46,
                      width: ResSize.w * 46,
                      decoration: BoxDecoration(
                        color: AppColor.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColor.white.withOpacity(0.18),
                        ),
                      ),
                      child: Icon(
                        Icons.alt_route_rounded,
                        color: moveraMint,
                        size: ResSize.h * 27,
                      ),
                    ),
                    14.width,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWidget(
                            text: "Waybill",
                            fontSize: 16,
                            fontWeight: fwSemiBold,
                            color: AppColor.white,
                          ),
                          5.height,
                          TextWidget(
                            text:
                                "Add a destination and find rides along your route",
                            fontSize: 11,
                            fontWeight: fwNormal,
                            color: AppColor.white.withOpacity(0.76),
                          ),
                        ],
                      ),
                    ),
                    8.width,
                    Container(
                      height: ResSize.h * 34,
                      width: ResSize.w * 34,
                      decoration: const BoxDecoration(
                        color: moveraMint,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: moveraNavy,
                        size: ResSize.h * 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: moveraNavy.withOpacity(0.08),
                    blurRadius: 22,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _moveraDockButton(
                    icon: Icons.tune_rounded,
                    label: "Tools",
                    color: moveraNavy,
                  ),
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
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResSize.w * 18,
                        vertical: ResSize.h * 9,
                      ),
                      decoration: BoxDecoration(
                        gradient: isAccountActivated
                            ? const LinearGradient(
                                colors: [moveraMint, Color(0xFF20AFC0)],
                              )
                            : null,
                        color: isAccountActivated
                            ? null
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: isAccountActivated
                            ? [
                                BoxShadow(
                                  color: moveraMint.withOpacity(0.28),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_taxi_rounded,
                            color: isAccountActivated
                                ? moveraNavy
                                : Colors.grey.shade600,
                            size: ResSize.h * 21,
                          ),
                          7.width,
                          TextWidget(
                            text: isAccountActivated ? "Go online" : "Pending",
                            fontSize: 12,
                            fontWeight: fwSemiBold,
                            color: isAccountActivated
                                ? moveraNavy
                                : Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _moveraDockButton(
                    icon: Icons.auto_awesome_rounded,
                    label: "Rewards",
                    color: moveraBlue,
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
    );
  }

  Widget _moveraDockButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: ResSize.w * 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: ResSize.h * 32,
              width: ResSize.w * 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: ResSize.h * 18,
                color: color,
              ),
            ),
            4.height,
            TextWidget(
              text: label,
              fontSize: 10,
              fontWeight: fwMedium,
              color: color,
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
