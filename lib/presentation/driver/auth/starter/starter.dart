import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/auth/create%20acc/create_acc.dart';
import 'package:movera/presentation/driver/auth/sign%20in/sign_in.dart';
import 'package:movera/widgets/custom_btn.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class DriverStarter extends StatelessWidget {
  const DriverStarter({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        child: Column(
          children: [
            100.height,
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    AppAssets.getStartedDriver,
                    height: ResSize.h * 200,
                  ),
                  38.height,
                  TextWidget(
                    text: "Ready to drive!",
                    color: AppColor.title,
                    fontSize: 34,
                    fontWeight: fwExtraBold,
                  ),
                  8.height,
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenHorizPadding,
                    ),
                    child: TextWidget(
                      textAlign: TextAlign.center,
                      text:
                          "Let’s hit the road. Accept rides in real time and make every minute count",
                      color: AppColor.subtitle,
                      fontSize: 16,
                      fontWeight: fwMedium,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: Column(
                children: [
                  CustomButton(
                    centerContent: "Sign in",
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        BottomToTopTransition(const DriverSignIn()),
                      );
                    },
                  ),
                  8.height,
                  CustomButton(
                    centerContent: "Create account",
                    onPressed: () {
                      Navigator.push(
                        context,
                        BottomToTopTransition(const DriverCreateAccount()),
                      );
                    },
                    btncolor: Colors.transparent,
                    borderColor: AppColor.primary,
                    borderwidth: 0.5,
                    textColor: AppColor.primary,
                  ),
                  20.height,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
