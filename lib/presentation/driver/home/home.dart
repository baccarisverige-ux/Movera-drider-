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
  bool isAccountActivated =
      false; // This should come from your backend/state management

  // ignore: prefer_final_fields
  Set<Marker> _markers = {};

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(33.6844, 73.0479),
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _loadMarkers();
    // Show popup after widget is built if account is not activated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isAccountActivated) {
        _showAccountActivationDialog();
      }
    });
  }

  void _loadMarkers() {
    _markers.add(
      Marker(
        markerId: MarkerId('driver_location'),
        position: LatLng(33.6844, 73.0479),
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
                            Padding(
                              padding: EdgeInsets.only(right: ResSize.w * 30),
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
    return AnimatedOpacity(
      duration: Duration(milliseconds: 150),
      opacity: isPanelOpen ? 1.0 : 0.0,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    _panelController.close();
                  },
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: ResSize.h * 24,
                    color: AppColor.title,
                  ),
                ),
                TextWidget(
                  text: "Driver tools",
                  color: AppColor.title,
                  fontSize: 16,
                  fontWeight: fwSemiBold,
                ),
                SizedBox(width: ResSize.w * 20),
              ],
            ),
          ),
          24.height,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenHorizPadding,
                vertical: ResSize.h * 16,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xffDADADA), width: 0.8),
              ),
              child: Column(
                children: [
                  TextWidget(
                    text: "Waybill",
                    fontSize: 16,
                    fontWeight: fwMedium,
                    color: AppColor.title,
                  ),
                  8.height,
                  TextWidget(
                    textAlign: TextAlign.center,
                    text:
                        "Add your destination to get matched with rides going the same way",
                    fontSize: 12,
                    fontWeight: fwNormal,
                    color: AppColor.subtitle,
                  ),
                ],
              ),
            ),
          ),
          Spacer(),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColor.white,
              border: Border(
                top: BorderSide(color: Color(0xffEFEFEF), width: 1),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: Column(
                children: [
                  11.height,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(AppAssets.homeImage1, height: ResSize.h * 36),
                      InkWell(
                        onTap: isAccountActivated
                            ? () {
                                _panelController.close().then((_) {
                                  setState(() {
                                    showRideRequests = true;
                                  });
                                });
                              }
                            : () {
                                _showAccountActivationDialog();
                              },
                        child: Container(
                          height: ResSize.h * 57,
                          width: ResSize.w * 57,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isAccountActivated
                                ? AppColor.white
                                : Colors.grey.shade200,
                            boxShadow: isAccountActivated
                                ? [
                                    BoxShadow(
                                      color: AppColor.black.withOpacity(0.12),
                                      blurRadius: 23.7,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Image.asset(
                              AppAssets.homeImage2,
                              height: ResSize.h * 40,
                              color: isAccountActivated ? null : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            BottomToTopTransition(Promotions()),
                          );
                        },
                        child: Image.asset(
                          AppAssets.homeImage3,
                          height: ResSize.h * 36,
                        ),
                      ),
                    ],
                  ),
                  55.height,
                ],
              ),
            ),
          ),
        ],
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
