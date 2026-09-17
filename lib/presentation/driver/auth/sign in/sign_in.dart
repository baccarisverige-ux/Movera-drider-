import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/auth/additional%20detail/navigation.dart';
import 'package:movera/presentation/driver/auth/create%20acc/create_acc.dart';
import 'package:movera/presentation/driver/auth/sign%20in%20phone/sign_in_phone.dart';
import 'package:movera/widgets/custom_btn.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class DriverSignIn extends StatelessWidget {
  const DriverSignIn({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            56.height,
            TextWidget(text: "Sign in", fontSize: 24, fontWeight: fwExtraBold),
            9.height,
            TextWidget(
              text: "Welcome back! Let’s get you riding",
              color: AppColor.subtitle,
              fontSize: 16,
              fontWeight: fwMedium,
            ),
            50.height,
            CustomButton(
              icon: Padding(
                padding: EdgeInsets.only(right: ResSize.w * 12),
                child: Image.asset(AppAssets.mobile, height: ResSize.h * 24),
              ),
              centerContent: "Continue with phone",
              onPressed: () {
                Navigator.push(
                  context,
                  BottomToTopTransition(const DriverSignInPhone()),
                );
              },
              borderColor: AppColor.border,
              borderwidth: 0.5,
              textColor: AppColor.title,
              btncolor: Colors.transparent,
              fontSize: 16,
            ),
            16.height,
            Row(
              children: [
                Expanded(
                  child: Divider(color: AppColor.border, thickness: 0.5),
                ),
                10.width,
                TextWidget(
                  text: "or",
                  color: AppColor.title,
                  fontSize: 16,
                  fontWeight: fwMedium,
                ),
                10.width,
                Expanded(
                  child: Divider(color: AppColor.border, thickness: 0.5),
                ),
              ],
            ),
            16.height,
            CustomButton(
              icon: Padding(
                padding: EdgeInsets.only(right: ResSize.w * 12),
                child: Image.asset(AppAssets.apple, height: ResSize.h * 24),
              ),
              centerContent: "Continue with apple",
              onPressed: () {
                Navigator.push(
                  context,
                  BottomToTopTransition(const AdditionalInfoNavigation()),
                );
              },
              borderColor: AppColor.border,
              borderwidth: 0.5,
              textColor: AppColor.title,
              btncolor: Colors.transparent,
              fontSize: 16,
            ),
            16.height,
            CustomButton(
              icon: Padding(
                padding: EdgeInsets.only(right: ResSize.w * 12),
                child: Image.asset(AppAssets.google, height: ResSize.h * 24),
              ),
              centerContent: "Continue with Google",
              onPressed: () {
                Navigator.push(
                  context,
                  BottomToTopTransition(const AdditionalInfoNavigation()),
                );
              },
              borderColor: AppColor.border,
              borderwidth: 0.5,
              textColor: AppColor.title,
              btncolor: Colors.transparent,
              fontSize: 16,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: ResSize.h * 60,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextWidget(
                    text: "Don't have an account?",
                    color: AppColor.subtitle,
                    fontSize: 16,
                    fontWeight: fwMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        RightToLeftTransition(DriverCreateAccount()),
                      );
                    },
                    child: TextWidget(
                      text: "Sign up",
                      color: AppColor.primary,
                      fontSize: 16,
                      fontWeight: fwMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
