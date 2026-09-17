// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/home/home.dart';
import 'package:movera/widgets/custom_btn.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

// Project utilities and widgets (following existing import style in the repo)

class DriverRideCompleted extends StatefulWidget {
  const DriverRideCompleted({super.key});

  @override
  State<DriverRideCompleted> createState() => _DriverRideCompletedState();
}

class _DriverRideCompletedState extends State<DriverRideCompleted> {
  double _rating = 0.0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            50.height,
            _buildHeader(),
            24.height,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: _buildRiderStrip(context),
            ),
            16.height,

            _buildTripDetailsTitle(),
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
              child: Column(
                children: [
                  _buildMetaRows(),
                  24.height,
                  CustomButton(
                    centerContent: 'Done',
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        BottomToTopTransition(DriverHome()),
                      );
                    },
                  ),
                  30.height,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 12 * ResSize.h),
        Center(child: Image.asset(AppAssets.sucess, height: ResSize.h * 75)),
        16.height,
        Center(
          child: TextWidget(
            text: 'Ride Completed',
            color: AppColor.black,
            fontSize: 20,
            fontWeight: fwBold,
          ),
        ),
        12.height,
        Center(
          child: TextWidget(
            text: 'Rate your experience',
            color: AppColor.black,
            fontSize: 14,
            fontWeight: fwBold,
          ),
        ),
        16.height,
        Center(
          child: RatingBar.builder(
            initialRating: _rating,
            minRating: 1,
            glow: false,
            direction: Axis.horizontal,
            allowHalfRating: true,
            unratedColor: Color(0xff909090),
            itemCount: 5,
            itemSize: ResSize.h * 37,
            itemPadding: EdgeInsets.symmetric(horizontal: ResSize.w * 6),
            itemBuilder: (context, _) =>
                Icon(Icons.star_rounded, color: Color(0xffF99417)),
            onRatingUpdate: (rating) {
              setState(() {
                _rating = rating;
              });
            },
            updateOnDrag: true,
          ),
        ),
        12.height,
      ],
    );
  }

  Widget _buildRiderStrip(BuildContext context) {
    return Row(
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
        TextWidget(
          text: 'Dora Sipes',
          color: AppColor.title,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ],
    );
  }

  Widget _buildTripDetailsTitle() {
    return Container(
      width: double.infinity,
      color: Color(0xffF9F9F9),
      padding: EdgeInsets.symmetric(
        horizontal: ResSize.w * 19,
        vertical: ResSize.h * 6,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextWidget(
            text: 'Trip Details',
            color: Color(0xff6E6E6E),
            fontSize: 14,
            fontWeight: fwSemiBold,
          ),
          TextWidget(
            text: '20.2 km (26 min)',
            color: Color(0xff6E6E6E),
            fontSize: 14,
            fontWeight: fwSemiBold,
          ),
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
              color: AppColor.title,
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
              color: AppColor.title,
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
              color: AppColor.title,
              fontSize: 16,
              fontWeight: fwBold,
              text: 'Ride Type',
            ),
            TextWidget(
              color: AppColor.title,
              fontSize: 16,
              fontWeight: fwBold,
              text: 'ILift Mini',
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
              color: AppColor.title,
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
              color: AppColor.title,
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
