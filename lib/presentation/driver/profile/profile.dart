// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/analytics/analytics.dart';
import 'package:movera/presentation/driver/documents/documents.dart';
import 'package:movera/presentation/driver/my%20wallet/wallet.dart';
import 'package:movera/presentation/driver/settings/settings.dart';
import 'package:movera/presentation/driver/vehicles/vehicles.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class DriverProfile extends StatelessWidget {
  const DriverProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              8.height,
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),

                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColor.title,
                      size: 20 * ResSize.h,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        RightToLeftTransition(Settings()),
                      );
                    },
                    icon: Image.asset(
                      AppAssets.setting,
                      height: ResSize.h * 20,
                    ),
                  ),
                ],
              ),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 64 * ResSize.h,
                    backgroundImage: const AssetImage(AppAssets.profileImg),
                    backgroundColor: const Color(0xFFECECEC),
                  ),
                  Container(
                    height: ResSize.h * 36,
                    width: ResSize.w * 36,
                    decoration: BoxDecoration(
                      color: AppColor.title,
                      borderRadius: BorderRadius.circular(20 * ResSize.w),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(AppAssets.camera),
                    ),
                  ),
                ],
              ),
              18.height,
              TextWidget(
                text: 'Andrew Johns',
                fontSize: 18,
                color: AppColor.title,
                fontWeight: fwBold,
              ),
              TextWidget(
                text: 'Joined since 2024',
                fontSize: 14,
                color: AppColor.subtitle,
                fontWeight: fwNormal,
              ),
              30.height,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      RightToLeftTransition(DriverVehicles()),
                    );
                  },

                  child: _vehiclesCard(),
                ),
              ),
              18.height,
              _menuItem(
                icon: AppAssets.analytics,
                title: 'Analytics',
                onTap: () {
                  Navigator.push(context, RightToLeftTransition(Analytics()));
                },
              ),
              _menuItem(
                icon: AppAssets.myBank,
                title: 'My bank',
                onTap: () {
                  Navigator.push(
                    context,
                    RightToLeftTransition(WalletScreen()),
                  );
                },
              ),
              _menuItem(
                icon: AppAssets.document,
                title: 'Documents',
                onTap: () {
                  Navigator.push(
                    context,
                    RightToLeftTransition(DriverDocuments()),
                  );
                },
              ),
              _menuItem(
                icon: AppAssets.privacyPolicy,
                title: 'Privacy policy',
                onTap: () {},
              ),
              _menuItem(
                icon: AppAssets.privacyPolicy,
                title: 'Terms of service',
                onTap: () {},
              ),
              _menuItem(
                icon: AppAssets.helpCenter,
                title: 'Help center',
                onTap: () {},
              ),
              _logoutItem(),
              24.height,
            ],
          ),
        ),
      ),
    );
  }

  Widget _vehiclesCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: ResSize.h * 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Transform.scale(
            scale: 1.1,
            child: Image.asset(AppAssets.profileCar, width: ResSize.w * 75),
          ),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: 'Vehicles',
                  fontSize: 18,
                  color: AppColor.title,
                  fontWeight: fwMedium,
                ),
                1.height,
                Row(
                  children: [
                    TextWidget(
                      text: 'Mercedes-Benz C200',
                      fontSize: 14,
                      color: AppColor.title,
                      fontWeight: fwMedium,
                    ),
                    20.width,
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColor.title,
                      size: ResSize.h * 18,
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

  Widget _menuItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
    double iconScaleSize = 1,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: AppColor.primary.withOpacity(0.1),
      highlightColor: AppColor.primary.withOpacity(0.1),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 12 * ResSize.h,
          horizontal: screenHorizPadding,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Transform.scale(
                  scale: iconScaleSize,
                  child: Image.asset(
                    icon,
                    height: ResSize.h * 20,
                    color: AppColor.title,
                  ),
                ),
                16.width,
                TextWidget(
                  text: title,
                  color: AppColor.title,
                  fontSize: 18,
                  fontWeight: fwMedium,
                ),
              ],
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColor.subtitle,
              size: ResSize.h * 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoutItem() {
    return InkWell(
      onTap: () {},
      splashColor: AppColor.red.withOpacity(0.1),
      highlightColor: AppColor.red.withOpacity(0.1),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 12 * ResSize.h,
          horizontal: screenHorizPadding,
        ),
        child: Row(
          children: [
            Transform.scale(
              scale: 1,
              child: Image.asset(
                AppAssets.logout,
                height: ResSize.h * 24,
                color: AppColor.red,
              ),
            ),
            16.width,
            TextWidget(
              text: 'Log out',
              fontSize: 18,
              color: AppColor.red,
              fontWeight: fwMedium,
            ),
          ],
        ),
      ),
    );
  }
}
