import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/preferences/preferences.dart';
import 'package:movera/presentation/driver/profile/profile.dart';
import 'package:movera/presentation/driver/ride%20history/ride_history.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class DriverSideMenu extends StatelessWidget {
  const DriverSideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      clipBehavior: Clip.none,
      backgroundColor: AppColor.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      width: MediaQuery.of(context).size.width * 0.78,
      child: Container(
        decoration: BoxDecoration(color: AppColor.white),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              40.height,
              // User Profile Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: ResSize.w * 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          RightToLeftTransition(DriverProfile()),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: ResSize.w * 60,
                                height: ResSize.h * 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: AssetImage(AppAssets.profileImg),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              12.width,
                              TextWidget(
                                text: "Marta Parker",
                                color: AppColor.black,
                                fontSize: 16,
                                fontWeight: fwMedium,
                              ),
                            ],
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: ResSize.h * 14,
                            color: AppColor.black,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              11.height,
              Container(
                height: ResSize.h * 4,
                width: double.infinity,
                color: Color(0xffFAFAFA),
              ),
              // Menu Items
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20 * ResSize.w,
                        ),
                        child: Column(
                          children: [
                            _buildMenuItem(
                              icon: AppAssets.rideHistory,
                              iconScaleSize: 1.3,
                              title: "History",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  RightToLeftTransition(DriverRideHistory()),
                                );
                              },
                            ),
                            _buildMenuItem(
                              icon: AppAssets.preference,
                              title: "Preference",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  RightToLeftTransition(Preferences()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      // 5.height,
                      // // Call to Action Section
                      // Container(
                      //   padding: EdgeInsets.only(
                      //     left: ResSize.w * 35,
                      //     top: ResSize.h * 14,
                      //     bottom: ResSize.h * 14,
                      //   ),
                      //   decoration: BoxDecoration(
                      //     // ignore: deprecated_member_use
                      //     color: const Color(0xFF215277).withOpacity(0.12),
                      //   ),
                      //   child: Row(
                      //     children: [
                      //       Image.asset(
                      //         AppAssets.driverIcon,
                      //         height: 24 * ResSize.h,
                      //       ),
                      //       13.width,
                      //       TextWidget(
                      //         text: "Become a driver",
                      //         color: Color(0xff215277),
                      //         fontSize: 16,
                      //         fontWeight: fwNormal,
                      //       ),
                      //     ],
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),

              // Footer
              // Container(
              //   height: ResSize.h * 4,
              //   width: double.infinity,
              //   color: Color(0xffFAFAFA),
              // ),
              // 20.height,
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     Image.asset(AppAssets.logo, height: ResSize.h * 22),
              //     7.width,
              //     TextWidget(
              //       text: "Powered by",
              //       color: AppColor.black,
              //       fontSize: 12,
              //       fontWeight: fwMedium,
              //     ),
              //     7.width,
              //     Image.asset(AppAssets.skypulse, height: ResSize.h * 22),
              //   ],
              // ),
              20.height,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
    double iconScaleSize = 1,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14 * ResSize.h),
        child: Row(
          children: [
            Transform.scale(
              scale: iconScaleSize,
              child: Image.asset(
                icon,
                height: ResSize.h * 20,
                color: AppColor.black,
              ),
            ),
            16.width,
            TextWidget(
              text: title,
              color: AppColor.black,
              fontSize: 16,
              fontWeight: fwMedium,
            ),
          ],
        ),
      ),
    );
  }
}
