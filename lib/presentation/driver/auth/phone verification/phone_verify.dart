import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/auth/additional%20detail/navigation.dart';
import 'package:movera/widgets/custom_btn.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';
import 'package:pinput/pinput.dart';

class DriverPhoneVerification extends StatelessWidget {
  const DriverPhoneVerification({super.key});

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 50,
      textStyle: GoogleFonts.poppins(
        fontSize: ResSize.setSp(20),
        color: AppColor.title,
        fontWeight: fwSemiBold,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: AppColor.textfieldFill,
      ),
    );
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            56.height,
            Transform.translate(
              offset: Offset(ResSize.w * -10, 0),
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppColor.title,
                  size: ResSize.h * 22,
                ),
              ),
            ),
            18.height,
            TextWidget(
              text: "Phone verification",
              fontSize: 24,
              fontWeight: fwExtraBold,
            ),
            9.height,
            RichText(
              textAlign: TextAlign.start,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "Verification code has been sent to",
                    style: GoogleFonts.poppins(
                      fontSize: ResSize.setSp(16),
                      fontWeight: fwNormal,
                      color: AppColor.subtitle,
                    ),
                  ),
                  TextSpan(
                    text: " +96441938184.",
                    style: GoogleFonts.poppins(
                      decoration: TextDecoration.underline,
                      fontSize: ResSize.setSp(16),
                      fontWeight: fwMedium,
                      color: AppColor.title,
                    ),
                  ),
                  TextSpan(
                    text: " Enter your 4 digit code",
                    style: GoogleFonts.poppins(
                      fontSize: ResSize.setSp(16),
                      fontWeight: fwNormal,
                      color: AppColor.subtitle,
                    ),
                  ),
                ],
              ),
            ),

            24.height,
            Container(
              padding: EdgeInsets.symmetric(vertical: ResSize.h * 14),
              decoration: BoxDecoration(
                color: AppColor.secondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  10.height,
                  Center(
                    child: Pinput(
                      length: 4,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: defaultPinTheme.copyDecorationWith(
                        borderRadius: BorderRadius.circular(6),
                        color: AppColor.textfieldFill,
                      ),
                      followingPinTheme: defaultPinTheme,
                      separatorBuilder: (index) => 26.width,
                      showCursor: true,
                      onCompleted: (pin) {},
                    ),
                  ),
                  14.height,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextWidget(
                        text: "Did you don’t get code?",
                        color: AppColor.title,
                        fontSize: 15,
                        fontWeight: fwNormal,
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigator.push(
                          //   context,
                          //   RightToLeftTransition(SignInPhone()),
                          // );
                        },
                        child: TextWidget(
                          text: "Sign in",
                          color: AppColor.primary,
                          fontSize: 15,
                          fontWeight: fwNormal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: SizedBox(
        height: ResSize.h * 80,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
          child: Column(
            children: [
              CustomButton(
                centerContent: "Continue",
                onPressed: () {
                  Navigator.push(
                    context,
                    BottomToTopTransition(const AdditionalInfoNavigation()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
