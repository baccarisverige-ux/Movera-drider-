import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/ride%20history/components/appbar.dart';
import 'package:movera/presentation/driver/ride%20history/history%20detail/history_detail.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class DriverRideHistory extends StatelessWidget {
  const DriverRideHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ResSize.h * 70),
        child: DriverRideHistoryAppBar(),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              height: ResSize.h * 6,
              width: double.infinity,
              color: Color(0xffFAFAFA),
            ),
            16.height,
            ListView.builder(
              itemCount: 10,
              shrinkWrap: true,
              clipBehavior: Clip.none,
              padding: EdgeInsets.all(0),
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: EdgeInsets.only(
                    top: index == 0 ? 0 : ResSize.h * 16,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenHorizPadding,
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              RightToLeftTransition(DriverRideHistoryDetail()),
                            );
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(
                                AppAssets.hisImg,
                                height: ResSize.h * 50,
                                width: ResSize.w * 54,
                              ),
                              8.width,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextWidget(
                                      text: "Skypulse solution pvt",
                                      color: AppColor.black,
                                      fontSize: 16,
                                      fontWeight: fwSemiBold,
                                    ),
                                    4.height,
                                    Row(
                                      children: [
                                        TextWidget(
                                          text: "Ride - ",
                                          color: AppColor.subtitle,
                                          fontSize: 14,
                                          fontWeight: fwMedium,
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: ResSize.w * 7,
                                          ),
                                          height: ResSize.h * 21,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            color: AppColor.green,
                                          ),
                                          child: Center(
                                            child: TextWidget(
                                              text: "Completed",
                                              color: AppColor.white,
                                              fontSize: 12,
                                              fontWeight: fwBold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    14.height,
                                    Divider(
                                      color: AppColor.border,
                                      thickness: 0.2,
                                      height: 0,
                                    ),
                                    9.height,
                                    Row(
                                      children: [
                                        // 62.width,
                                        TextWidget(
                                          text: "5.6 km",
                                          color: AppColor.subtitle,
                                          fontSize: 12,
                                          fontWeight: fwSemiBold,
                                        ),
                                        14.width,
                                        SizedBox(
                                          width: ResSize.w * 6,
                                          child: Divider(
                                            color: AppColor.border,
                                            height: 0,
                                            thickness: 2,
                                          ),
                                        ),
                                        14.width,
                                        TextWidget(
                                          text: "\$12.00",
                                          color: AppColor.subtitle,
                                          fontSize: 12,
                                          fontWeight: fwSemiBold,
                                        ),
                                        12.width,
                                        SizedBox(
                                          width: ResSize.w * 6,
                                          child: Divider(
                                            color: AppColor.border,
                                            height: 0,
                                            thickness: 2,
                                          ),
                                        ),
                                        12.width,
                                        TextWidget(
                                          text: "20 Jun, 10:30 AM",
                                          color: AppColor.subtitle,
                                          fontSize: 12,
                                          fontWeight: fwSemiBold,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      16.height,
                      Container(
                        height: ResSize.h * 6,
                        width: double.infinity,
                        color: Color(0xffFAFAFA),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
