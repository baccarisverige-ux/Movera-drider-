// ignore_for_file: unused_field
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/common/chat/chat.dart';
import 'package:movera/presentation/driver/accept%20ride/components/cancel_ride.dart';
import 'package:movera/presentation/driver/ride%20completed/ride_completed.dart';
import 'package:movera/widgets/custom_btn.dart';
import 'package:movera/widgets/custom_google_map.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class AcceptRide extends StatefulWidget {
  const AcceptRide({super.key});

  @override
  State<AcceptRide> createState() => _AcceptRideState();
}

class _AcceptRideState extends State<AcceptRide> {
  final PanelController _panelController = PanelController();
  final PanelController _endRidepPanelController = PanelController();
  GoogleMapController? _mapController;
  // ignore: prefer_final_fields
  Set<Marker> _markers = {};

  // Default location
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(33.6844, 73.0479), // Islamabad coordinates
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  void _loadMarkers() {
    // Add any initial markers if needed
    // Example: driver location marker
    _markers.add(
      Marker(
        markerId: MarkerId('driver_location'),
        position: LatLng(33.6844, 73.0479),
        infoWindow: InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
  }

  bool isArrived = false;
  bool isRideStarted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SlidingUpPanel(
        color: AppColor.white,
        backdropColor: Colors.transparent,
        backdropOpacity: 0,
        backdropEnabled: true,
        backdropTapClosesPanel: true,
        controller: _panelController,
        margin: EdgeInsets.all(0),
        minHeight: ResSize.h * 200,
        padding: EdgeInsets.symmetric(
          // horizontal: screenHorizPadding,
          vertical: ResSize.h * 19,
        ),
        boxShadow: [],
        defaultPanelState: PanelState.CLOSED,
        maxHeight: isRideStarted
            ? ResSize.h * 200
            : isArrived
            ? ResSize.h * 360
            : ResSize.h * 530,
        parallaxEnabled: false,
        panelBuilder: (ScrollController sc) => panelColumn(sc),
        body: body(),
      ),
    );
  }

  Widget body() {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: double.infinity,
      child: Stack(
        children: [
          // Using the reusable CustomGoogleMap widget
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
              // Any additional map setup can be done here
            },
            onTap: (LatLng position) {
              // Handle map tap events
            },
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
            child: Column(
              children: [
                55.height,
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenHorizPadding,
                    vertical: ResSize.h * 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColor.white,
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Color(0xff262626).withOpacity(0.12),
                        blurRadius: 30,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResSize.w * 8,
                              vertical: ResSize.h * 7,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Color(0xffFFCC00),
                            ),
                            child: Center(
                              child: TextWidget(
                                text: "Not arrived",
                                fontSize: 12,
                                fontWeight: fwMedium,
                                color: AppColor.title,
                              ),
                            ),
                          ),
                        ],
                      ),
                      8.height,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextWidget(
                                text: "1141 central park",
                                fontSize: 16,
                                fontWeight: fwSemiBold,
                                color: AppColor.title,
                              ),
                              TextWidget(
                                text: "2 km  - arrival time 19:35 ",
                                fontSize: 12,
                                fontWeight: fwNormal,
                                color: AppColor.title,
                              ),
                            ],
                          ),
                          TextWidget(
                            text: "5 mins",
                            fontSize: 24,
                            fontWeight: fwSemiBold,
                            color: AppColor.title,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                8.height,
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResSize.w * 8,
                        vertical: ResSize.h * 9,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColor.white,
                        boxShadow: [
                          BoxShadow(
                            // ignore: deprecated_member_use
                            color: Color(0xff262626).withOpacity(0.12),
                            blurRadius: 30,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          TextWidget(
                            text: "200 m",
                            fontSize: 16,
                            fontWeight: fwSemiBold,
                            color: AppColor.title,
                          ),
                          5.width,
                          Image.asset(
                            AppAssets.arrowLeft,
                            height: ResSize.h * 24,
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
    );
  }

  Widget panelColumn(ScrollController sc) {
    return SingleChildScrollView(
      controller: sc,
      child: isRideStarted
          ? Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: endRide(),
            )
          : Column(
              children: [
                10.height,
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
                  child: Row(
                    children: [
                      Container(
                        height: ResSize.h * 56,
                        width: ResSize.w * 62,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: AssetImage(AppAssets.profileImg),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      12.width,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWidget(
                              text: "Passenger name",
                              color: AppColor.title,
                              fontSize: 16,
                              fontWeight: fwBold,
                            ),
                            3.height,
                            TextWidget(
                              text: "\$12.55",
                              color: AppColor.green,
                              fontSize: 16,
                              fontWeight: fwBold,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: () {},
                            child: Container(
                              height: ResSize.h * 32,
                              width: ResSize.w * 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: Color(
                                  0xff333333,
                                  // ignore: deprecated_member_use
                                ).withOpacity(0.10),
                              ),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Image.asset(
                                    AppAssets.phone,
                                    color: AppColor.title,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          15.width,
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                BottomToTopTransition(Chat()),
                              );
                            },
                            child: Container(
                              height: ResSize.h * 32,
                              width: ResSize.w * 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: Color(
                                  0xff333333,
                                  // ignore: deprecated_member_use
                                ).withOpacity(0.10),
                              ),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Image.asset(
                                    AppAssets.message,
                                    color: AppColor.title,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                16.height,
                Container(
                  height: ResSize.h * 4,
                  width: double.infinity,
                  color: Color(0xffF9F9F9),
                ),
                16.height,
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: ResSize.h * 92, // more height to fit A & B
                        child: Column(
                          children: [
                            5.height,
                            // Pickup Circle
                            Container(
                              height: ResSize.h * 32,
                              width: ResSize.w * 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColor.liteBlue,
                              ),
                              child: Center(
                                child: Image.asset(
                                  AppAssets.locationFill,
                                  height: ResSize.h * 20,
                                ),
                              ),
                            ),
                            Expanded(
                              child: DottedLine(
                                dashLength: 3,
                                dashGapLength: 3,
                                lineThickness: 1.4,
                                dashColor: AppColor.black,
                                direction: Axis.vertical,
                              ),
                            ),

                            Container(
                              height: ResSize.h * 32,
                              width: ResSize.w * 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColor.liteBlue,
                              ),
                              child: Center(
                                child: Image.asset(
                                  AppAssets.arrowUp,
                                  height: ResSize.h * 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      12.width,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextWidget(
                                  fontSize: 12,
                                  fontWeight: fwSemiBold,
                                  text: "Pickup from",
                                  color: Color(0xffA3A3A3),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "1141 central park, Lemonade Homilton",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: ResSize.setSp(14),
                                          fontWeight: fwBold,
                                          color: AppColor.title,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            18.height,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextWidget(
                                  fontSize: 12,
                                  fontWeight: fwSemiBold,
                                  text: "Drop off location",
                                  color: Color(0xffA3A3A3),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "1141 central park, Lemonade Homilton",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: ResSize.setSp(14),
                                          fontWeight: fwBold,
                                          color: AppColor.title,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                16.height,
                Container(
                  height: ResSize.h * 4,
                  width: double.infinity,
                  color: Color(0xffF9F9F9),
                ),
                16.height,
                isArrived
                    ? SizedBox()
                    : Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenHorizPadding,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextWidget(
                                  color: AppColor.title,
                                  fontSize: 16,
                                  fontWeight: fwBold,
                                  text: "Ride Cost",
                                ),
                                TextWidget(
                                  color: AppColor.title,
                                  fontSize: 16,
                                  fontWeight: fwBold,
                                  text: "\$14.30",
                                ),
                              ],
                            ),
                            16.height,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextWidget(
                                  color: AppColor.title,
                                  fontSize: 16,
                                  fontWeight: fwBold,
                                  text: "Payment Method",
                                ),
                                Row(
                                  children: [
                                    Transform.scale(
                                      scale: 1.2,
                                      child: Image.asset(
                                        AppAssets.wallet2,
                                        color: AppColor.title,
                                        height: ResSize.h * 22,
                                      ),
                                    ),
                                    6.width,
                                    TextWidget(
                                      color: AppColor.title,
                                      fontSize: 16,
                                      fontWeight: fwBold,
                                      text: "Cash",
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            16.height,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextWidget(
                                  color: AppColor.title,
                                  fontSize: 16,
                                  fontWeight: fwBold,
                                  text: "Ride Type",
                                ),
                                TextWidget(
                                  color: AppColor.title,
                                  fontSize: 16,
                                  fontWeight: fwBold,
                                  text: "Eco-friendly",
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
                  child: Column(
                    children: [
                      isArrived ? 12.height : 32.height,
                      CustomButton(
                        centerContent: !isArrived
                            ? "Mark Arrived"
                            : !isRideStarted
                            ? "Begin Ride"
                            : "End Ride",
                        onPressed: () {
                          setState(() {
                            if (!isArrived) {
                              isArrived = true;
                            } else if (!isRideStarted) {
                              isRideStarted = true;
                            } else {
                              // Ride ended, navigate to ride completed screen
                            }
                          });
                        },

                        // Navigator.push(
                        //   context,
                        //   BottomToTopTransition(DriverRideCompleted()),
                        // );
                      ),
                      isArrived
                          ? SizedBox()
                          : IconButton(
                              onPressed: () {
                                showDriverRideCanceledDialog(context);
                              },
                              icon: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cancel_outlined,
                                    color: AppColor.red,
                                    size: ResSize.h * 18,
                                  ),
                                  6.width,
                                  TextWidget(
                                    color: AppColor.red,
                                    fontSize: 12,
                                    fontWeight: fwMedium,
                                    text: "CANCEL RIDE",
                                  ),
                                ],
                              ),
                            ),

                      50.height,
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget endRide() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(AppAssets.dropOff, height: ResSize.h * 24),
            12.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: "Drop off location",
                    color: AppColor.subtitle,
                    fontSize: 12,
                    fontWeight: fwSemiBold,
                  ),
                  3.height,
                  TextWidget(
                    text: "1141 central park, Lemonade Homilton",
                    color: AppColor.title,
                    fontSize: 14,
                    fontWeight: fwBold,
                  ),
                ],
              ),
            ),
          ],
        ),
        16.height,
        Container(
          height: ResSize.h * 4,
          width: double.infinity,
          color: Color(0xffF9F9F9),
        ),
        16.height,
        CustomButton(
          centerContent: "End Ride",
          onPressed: () {
            Navigator.push(
              context,
              BottomToTopTransition(DriverRideCompleted()),
            );
          },
        ),
      ],
    );
  }
}

//
