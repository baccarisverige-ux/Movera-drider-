// ignore_for_file: must_be_immutable
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/models/home_recent_rides.dart';
import 'package:movera/presentation/driver/analytics/analytics.dart';
import 'package:movera/widgets/custom_btn.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class DriverHomeRecentRides extends StatelessWidget {
  final VoidCallback? onVisible;
  DriverHomeRecentRides({super.key, this.onVisible});

  List<HomeRecentRidesModel> rides = [
    HomeRecentRidesModel(
      title: "Last Trip",
      subTitle: "Today at 12:30 am",
      price: "Ride type - Comfort",
    ),
    HomeRecentRidesModel(
      title: "Today's trip",
      subTitle: "Total Rides - 10",
      price: "Earning - \$56.00",
    ),
    HomeRecentRidesModel(
      title: "Total trips",
      subTitle: "Total Rides - 140",
      price: "Earning - \$120.00",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: rides.length,
          itemBuilder: (context, index, realIndex) {
            return SizedBox(
              height: ResSize.h * 320,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    // height: ResSize.h * 232,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenHorizPadding,
                      vertical: ResSize.h * 14,
                    ),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColor.white,
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: Color(0xff393939).withOpacity(0.12),
                          blurRadius: 50,
                          spreadRadius: 3,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: onVisible,
                              child: Icon(
                                Icons.visibility_off_outlined,
                                size: ResSize.h * 20,
                                color: AppColor.black,
                              ),
                            ),
                            Row(
                              children: [
                                TextWidget(
                                  text: "\$",
                                  fontSize: 24,
                                  fontWeight: fwSemiBold,
                                  color: AppColor.green,
                                ),
                                TextWidget(
                                  text: " 120.00",
                                  fontSize: 24,
                                  fontWeight: fwSemiBold,
                                  color: AppColor.black,
                                ),
                              ],
                            ),
                            Image.asset(AppAssets.info, height: ResSize.h * 24),
                          ],
                        ),
                        12.height,
                        TextWidget(
                          text: rides[index].title,
                          fontSize: 16,
                          fontWeight: fwNormal,
                          color: AppColor.subtitle,
                        ),
                        6.height,
                        TextWidget(
                          text: rides[index].subTitle,
                          fontSize: 16,
                          fontWeight: fwNormal,
                          color: AppColor.title,
                        ),
                        6.height,
                        TextWidget(
                          text: rides[index].price,
                          fontSize: 16,
                          fontWeight: fwNormal,
                          color: AppColor.title,
                        ),
                        30.height,
                        CustomButton(
                          centerContent: "View stats",
                          fontSize: 14,
                          height: ResSize.h * 42,
                          onPressed: () {
                            Navigator.push(
                              context,
                              TopToBottomTransition(Analytics()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          options: CarouselOptions(
            height: ResSize.h * 320,
            enableInfiniteScroll: true,
            autoPlay: false,
            viewportFraction: 0.78, // Shows part of adjacent slides
            enlargeCenterPage: true, // Makes center slide slightly larger
            scrollDirection: Axis.horizontal,
            initialPage: 2, // Equivalent to your PageController's initialPage
            scrollPhysics: const BouncingScrollPhysics(),
          ),
        ),
      ],
    );
  }
}
