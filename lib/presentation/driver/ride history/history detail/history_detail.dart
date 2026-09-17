import 'package:flutter/material.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_google_map.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class DriverRideHistoryDetail extends StatefulWidget {
  const DriverRideHistoryDetail({super.key});

  @override
  State<DriverRideHistoryDetail> createState() =>
      _DriverRideHistoryDetailState();
}

class _DriverRideHistoryDetailState extends State<DriverRideHistoryDetail> {
  final PanelController _panelController = PanelController();
  // ignore: unused_field
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

  // bool isPanelOpen = false;
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
        minHeight: ResSize.h * 120,
        padding: EdgeInsets.symmetric(
          // horizontal: screenHorizPadding,
          vertical: ResSize.h * 19,
        ),
        boxShadow: [],
        defaultPanelState: PanelState.OPEN,
        maxHeight: ResSize.h * 550,
        parallaxEnabled: false,
        panelBuilder: (ScrollController sc) => panelColumn(sc),
        body: SizedBox(
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
                  // Any additional map setup can be done here
                },
                onTap: (LatLng position) {
                  // Handle map tap events
                },
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height,
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
                  child: Column(
                    children: [
                      55.height,
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Container(
                              height: ResSize.h * 24,
                              width: ResSize.w * 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColor.white,
                                boxShadow: [
                                  BoxShadow(
                                    offset: const Offset(0, 4),
                                    // ignore: deprecated_member_use
                                    color: Color(0xff606060).withOpacity(0.12),
                                    spreadRadius: 6,
                                    blurRadius: 40,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.arrow_back_ios_rounded,
                                  color: AppColor.black,
                                  size: ResSize.h * 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
    return SingleChildScrollView(
      controller: sc,
      child: Column(
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
                        text: "May 12, 10:30 am",
                        color: AppColor.title,
                        fontSize: 16,
                        fontWeight: fwBold,
                      ),
                      3.height,
                      TextWidget(
                        text: "Dora Sipes",
                        color: AppColor.subtitle,
                        fontSize: 16,
                        fontWeight: fwBold,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: ResSize.w * 60,
                      padding: EdgeInsets.symmetric(vertical: ResSize.h * 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: AppColor.title,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextWidget(
                            text: "5.0",
                            color: AppColor.whiteText,
                            fontSize: 12,
                            fontWeight: fwBold,
                          ),
                          3.width,
                          Icon(
                            Icons.star_rounded,
                            color: AppColor.white,
                            size: ResSize.h * 18,
                          ),
                        ],
                      ),
                    ),
                    4.height,
                    TextWidget(
                      text: "Rated you",
                      color: AppColor.subtitle,
                      fontSize: 12,
                      fontWeight: fwBold,
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
            child: _buildPickupDropSection(),
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
            child: _buildSummaryRows(context),
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
            child: _buildMetaRows(),
          ),
          50.height,
        ],
      ),
    );
  }

  Widget _buildPickupDropSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: ResSize.h * 92,
          child: Column(
            children: [
              5.height,
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
                  child: Image.asset(AppAssets.arrowUp, height: ResSize.h * 16),
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
                    fontWeight: FontWeight.w600,
                    text: 'Pickup from',
                    color: const Color(0xffA3A3A3),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextWidget(
                          text: '1141 central park, Lemonade Homilton',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColor.title,
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
                    fontWeight: FontWeight.w600,
                    text: 'Drop off location',
                    color: const Color(0xffA3A3A3),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextWidget(
                          text: 'Skypulse office, RWP, Pakistan',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColor.title,
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
    );
  }

  Widget _buildSummaryRows(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextWidget(
              color: AppColor.subtitle,
              fontSize: 16,
              fontWeight: fwBold,
              text: 'Ride Cost',
            ),
            TextWidget(
              color: AppColor.title,
              fontSize: 16,
              fontWeight: fwBold,
              text: '\$14.30',
            ),
          ],
        ),
        16.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextWidget(
              color: AppColor.subtitle,
              fontSize: 16,
              fontWeight: fwBold,
              text: 'Tip',
            ),
            TextWidget(
              color: AppColor.title,
              fontSize: 16,
              fontWeight: fwBold,
              text: '\$4.30',
            ),
          ],
        ),

        16.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextWidget(
              color: AppColor.subtitle,
              fontSize: 16,
              fontWeight: fwBold,
              text: 'Payment Method',
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
                  text: 'Wallet',
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
              color: AppColor.subtitle,
              fontSize: 16,
              fontWeight: fwBold,
              text: 'Ride Type',
            ),
            TextWidget(
              color: AppColor.title,
              fontSize: 16,
              fontWeight: fwBold,
              text: 'Movera VIP',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetaRows() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextWidget(
              text: 'Booking ID',
              color: AppColor.subtitle,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            TextWidget(
              text: '#IL41514',
              color: AppColor.title,
              fontSize: 16,
              fontWeight: fwBold,
            ),
          ],
        ),
        20.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextWidget(
              text: 'Ride Completed on',
              color: AppColor.subtitle,
              fontSize: 16,
              fontWeight: fwBold,
            ),
            TextWidget(
              text: 'Today, 10:30 am',
              color: AppColor.title,
              fontSize: 16,
              fontWeight: fwBold,
            ),
          ],
        ),
      ],
    );
  }
}
