import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class EarningStatsScreen extends StatefulWidget {
  const EarningStatsScreen({super.key});

  @override
  State<EarningStatsScreen> createState() => _EarningStatsScreenState();
}

class _EarningStatsScreenState extends State<EarningStatsScreen> {
  final List<String> tabs = ["Type", "Feature", "7/12 - 7/14", "Clear"];
  int selectedTab = 2;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actionsPadding: EdgeInsets.all(0),
        automaticallyImplyLeading: false,
        backgroundColor: AppColor.white,
        clipBehavior: Clip.none,
        foregroundColor: AppColor.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColor.title,
            size: ResSize.h * 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextWidget(
          text: "Earning Stats",
          fontSize: 16,
          fontWeight: fwSemiBold,
          color: AppColor.title,
        ),
        centerTitle: true,
      ),
      body: SizedBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            8.height,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: SizedBox(
                height: ResSize.h * 46,
                child: ListView.builder(
                  physics: BouncingScrollPhysics(),
                  shrinkWrap: true,
                  clipBehavior: Clip.none,
                  scrollDirection: Axis.horizontal,
                  itemCount: tabs.length, // Sample data
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 0 : ResSize.w * 8,
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedTab = index;
                          });
                        },
                        child: Container(
                          height: ResSize.h * 46,
                          padding: EdgeInsets.symmetric(
                            horizontal: ResSize.w * 16,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: selectedTab == index
                                ? AppColor.title
                                : Color(0xffEDEDED),
                          ),
                          child: Row(
                            children: [
                              TextWidget(
                                text: tabs[index],
                                fontSize: 16,
                                fontWeight: fwMedium,
                                color: selectedTab == index
                                    ? AppColor.whiteText
                                    : AppColor.title,
                              ),
                              8.width,
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: ResSize.h * 20,
                                color: selectedTab == index
                                    ? AppColor.whiteText
                                    : AppColor.title,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            19.height,
            // Rides List
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Container(
                      height: ResSize.h * 6,
                      width: double.infinity,
                      color: Color(0xffFAFAFA),
                    ),
                    10.height,
                    ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenHorizPadding,
                      ),
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      clipBehavior: Clip.none,
                      itemCount: 3, // Sample data
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            index == 0
                                ? SizedBox()
                                : Column(
                                    children: [
                                      16.height,
                                      Divider(
                                        color: AppColor.border,
                                        thickness: 0.3,
                                        height: 0,
                                      ),
                                      16.height,
                                    ],
                                  ),

                            _buildRideCard(),
                          ],
                        );
                      },
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

  Widget _buildRideCard() {
    return SizedBox(
      child: Column(
        children: [
          // Ride Header
          Row(
            children: [
              Image.asset(
                AppAssets.hisImg,
                height: ResSize.h * 50,
                width: ResSize.w * 54,
              ),
              12.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: "Skypulse solution pvt",
                      fontSize: 16,
                      fontWeight: fwSemiBold,
                      color: AppColor.title,
                    ),
                    4.height,
                    Row(
                      children: [
                        TextWidget(
                          text: "VIP Ride",
                          fontSize: 10,
                          fontWeight: fwSemiBold,
                          color: AppColor.subtitle,
                        ),
                        TextWidget(
                          text: "  -  ",
                          fontSize: 10,
                          fontWeight: fwSemiBold,
                          color: AppColor.subtitle,
                        ),
                        TextWidget(
                          text: "5.6 km",
                          fontSize: 10,
                          fontWeight: fwSemiBold,
                          color: AppColor.subtitle,
                        ),
                        TextWidget(
                          text: "  -  ",
                          fontSize: 10,
                          fontWeight: fwSemiBold,
                          color: AppColor.subtitle,
                        ),
                        TextWidget(
                          text: "\$12.00",
                          fontSize: 10,
                          fontWeight: fwSemiBold,
                          color: AppColor.subtitle,
                        ),
                        TextWidget(
                          text: "  -  ",
                          fontSize: 10,
                          fontWeight: fwSemiBold,
                          color: AppColor.subtitle,
                        ),
                        TextWidget(
                          text: "20 Jun, 10:30 AM",
                          fontSize: 10,
                          fontWeight: fwSemiBold,
                          color: AppColor.subtitle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          16.height,
          // Map Section
          Container(
            height: ResSize.h * 112,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ResSize.w * 8),
              image: DecorationImage(
                image: AssetImage(
                  AppAssets.earningStatsCardImg,
                ), // Add your map image
                fit: BoxFit.cover,
              ),
            ),
          ),

          8.height,

          // Pickup & Dropoff Section using your component
          Row(
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
                                "Skypulse office, RWP, Pakistan",
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

          16.height,
        ],
      ),
    );
  }
}
