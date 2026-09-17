import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/accept%20ride/accept_ride.dart';
import 'package:movera/widgets/custom_btn.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RideRequests extends StatelessWidget {
  final VoidCallback? onCloseRides;

  const RideRequests({super.key, this.onCloseRides});

  @override
  Widget build(BuildContext context) {
    return Container(
      // ignore: deprecated_member_use
      color: Colors.black.withOpacity(0.5),
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
          child: Column(
            children: [
              50.height,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: onCloseRides,
                    child: Icon(
                      Icons.cancel_outlined,
                      color: AppColor.white,
                      size: ResSize.h * 22,
                    ),
                  ),
                  TextWidget(
                    text: "10 requests",
                    color: AppColor.whiteText,
                    fontSize: 16,
                    fontWeight: fwNormal,
                  ),
                ],
              ),
              19.height,
              ListView.builder(
                itemCount: 10,
                shrinkWrap: true,
                padding: EdgeInsets.all(0),
                physics: NeverScrollableScrollPhysics(),
                clipBehavior: Clip.none,
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      top: index == 0 ? 0 : ResSize.h * 19,
                    ),
                    child:
                        Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResSize.w * 14,
                                vertical: ResSize.h * 22,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppColor.white,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: ResSize.w * 120,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: ResSize.w * 7,
                                      vertical: ResSize.h * 7,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: AppColor.primary,
                                    ),
                                    child: Center(
                                      child: TextWidget(
                                        text: "Movera Comfort",
                                        color: AppColor.whiteText,
                                        fontSize: 12,
                                        fontWeight: fwMedium,
                                      ),
                                    ),
                                  ),
                                  8.height,
                                  TextWidget(
                                    text: "\$15.50",
                                    color: AppColor.black,
                                    fontSize: 24,
                                    fontWeight: fwNormal,
                                  ),
                                  2.height,
                                  Container(
                                    width: ResSize.w * 55,
                                    padding: EdgeInsets.symmetric(
                                      vertical: ResSize.h * 3,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: Color(0xffECECEC),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          color: Color(0xffFF8D28),
                                          size: ResSize.h * 18,
                                        ),
                                        3.width,
                                        TextWidget(
                                          text: "4.9",
                                          color: AppColor.black,
                                          fontSize: 12,
                                          fontWeight: fwNormal,
                                        ),
                                      ],
                                    ),
                                  ),
                                  16.height,
                                  TextWidget(
                                    fontSize: 16,
                                    fontWeight: fwBold,
                                    text: "Ride Details",
                                    color: AppColor.title,
                                  ),
                                  12.height,
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height:
                                            ResSize.h *
                                            87, // more height to fit A & B
                                        child: Column(
                                          children: [
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                TextWidget(
                                                  fontSize: 12,
                                                  fontWeight: fwSemiBold,
                                                  text: "1.0 km (4 min)",
                                                  color: Color(0xffA3A3A3),
                                                ),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        "1141 central park, Lemonade",
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize:
                                                                  ResSize.setSp(
                                                                    16,
                                                                  ),
                                                              fontWeight:
                                                                  fwMedium,
                                                              color: AppColor
                                                                  .title,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            18.height,
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                TextWidget(
                                                  fontSize: 12,
                                                  fontWeight: fwSemiBold,
                                                  text: "12.0 km (15 min)",
                                                  color: Color(0xffA3A3A3),
                                                ),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        "1141 central park, DHA",
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize:
                                                                  ResSize.setSp(
                                                                    16,
                                                                  ),
                                                              fontWeight:
                                                                  fwMedium,
                                                              color: AppColor
                                                                  .title,
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
                                  24.height,
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomButton(
                                          centerContent: "Reject",
                                          onPressed: () {},
                                          height: ResSize.h * 41,
                                          textColor: AppColor.whiteText,
                                          btncolor: AppColor.red,
                                          borderRadius: 8,
                                        ),
                                      ),
                                      15.width,
                                      Expanded(
                                        child: CustomButton(
                                          centerContent: "Accept",
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              BottomToTopTransition(
                                                const AcceptRide(),
                                              ),
                                            );
                                          },
                                          height: ResSize.h * 41,
                                          textColor: AppColor.whiteText,
                                          btncolor: AppColor.green,
                                          borderRadius: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(
                              duration: const Duration(milliseconds: 600),
                              delay: Duration(
                                milliseconds: index * 200,
                              ), // Staggered delay
                              curve: Curves.easeOutCubic,
                            )
                            .slideY(
                              begin: 0.3,
                              end: 0,
                              duration: const Duration(milliseconds: 600),
                              delay: Duration(
                                milliseconds: index * 200,
                              ), // Same delay
                              curve: Curves.easeOutCubic,
                            ),
                  );
                },
              ),
              20.height,
            ],
          ),
        ),
      ),
    );
  }
}
