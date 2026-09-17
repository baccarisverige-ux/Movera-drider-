import 'package:flutter/material.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/analytics/components/appbar.dart';
import 'package:movera/presentation/driver/analytics/components/earnings.dart';
import 'package:movera/presentation/driver/analytics/components/insights.dart';
import 'package:movera/presentation/driver/analytics/components/overal_ratings.dart';
import 'package:movera/presentation/driver/analytics/components/reviews.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class Analytics extends StatelessWidget {
  const Analytics({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ResSize.h * 65),
        child: AnalyticsAppBar(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // _header(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    12.height,
                    Container(
                      height: ResSize.h * 8,
                      width: double.infinity,
                      color: Color(0xffFAFAFA),
                    ),
                    12.height,
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenHorizPadding,
                      ),
                      child: Row(
                        children: [
                          _summaryTile('Rides', '12'),
                          _summaryTile('Driven', '109Km'),
                          _summaryTile('Earnings', '120'),
                        ],
                      ),
                    ),
                    12.height,
                    Container(
                      height: ResSize.h * 8,
                      width: double.infinity,
                      color: Color(0xffFAFAFA),
                    ),

                    16.height,
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenHorizPadding,
                      ),
                      child: AnalyticsEarnings(),
                    ),
                    16.height,
                    Container(
                      height: ResSize.h * 8,
                      width: double.infinity,
                      color: Color(0xffFAFAFA),
                    ),

                    16.height,
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenHorizPadding,
                      ),
                      child: AnalyticsInsights(),
                    ),
                    16.height,
                    Container(
                      height: ResSize.h * 8,
                      width: double.infinity,
                      color: Color(0xffFAFAFA),
                    ),

                    16.height,
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenHorizPadding,
                      ),
                      child: AnalyticsOverallRatings(),
                    ),
                    30.height,
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenHorizPadding,
                      ),
                      child: AnalyticsReviews(),
                    ),
                    24.height,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryTile(String title, String value) {
    return Expanded(
      child: Column(
        children: [
          TextWidget(
            text: title,
            color: const Color(0xFF8D8D8D),
            fontSize: 16,
            fontWeight: fwMedium,
          ),
          8.height,
          TextWidget(
            text: value,
            color: AppColor.title,
            fontSize: 24,
            fontWeight: fwBold,
          ),
        ],
      ),
    );
  }
}
