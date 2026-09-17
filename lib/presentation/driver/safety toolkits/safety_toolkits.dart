import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/models/onboarding.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

Future<T?> showSafetyToolKitSheet<T>(BuildContext context) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return SafetyToolKits();
    },
  );
}

// ignore: must_be_immutable
class SafetyToolKits extends StatelessWidget {
  SafetyToolKits({super.key});
  List<OnBoardingModel> tools = [
    OnBoardingModel(
      image: AppAssets.emergencyCallTool,
      title: "Emergency call",
      subTitle: "Call the local authorities",
    ),
    OnBoardingModel(
      image: AppAssets.shareTrip,
      title: "Share trip details",
      subTitle: "Share your location and trip details",
    ),
    OnBoardingModel(
      image: AppAssets.audioRecording,
      title: "Audio Recording",
      subTitle: "Start audio recording",
    ),
    OnBoardingModel(
      image: AppAssets.pinVerificationTool,
      title: "Pin Verification",
      subTitle: "Pin code will ensure that you are picking up the right rider",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(color: Colors.white),
        child: Padding(
          padding: EdgeInsets.only(
            left: ResSize.w * 16,
            right: ResSize.w * 16,
            top: ResSize.h * 31,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(
                text: "Safety toolkit",
                color: AppColor.title,
                fontSize: 20,
                fontWeight: fwSemiBold,
              ),
              TextWidget(
                textAlign: TextAlign.start,
                text:
                    "Smart tools that prioritize your safety every time you drive",
                color: AppColor.subtitle,
                fontSize: 14,
                fontWeight: fwNormal,
              ),
              21.height,
              ...List.generate(tools.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0 : 22),
                  child: Row(
                    children: [
                      Image.asset(tools[index].image, height: ResSize.h * 35),
                      16.width,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWidget(
                              text: tools[index].title,
                              color: AppColor.title,
                              fontSize: 16,
                              fontWeight: fwMedium,
                            ),
                            4.height,
                            TextWidget(
                              text: tools[index].subTitle,
                              color: AppColor.subtitle,
                              fontSize: 14,
                              fontWeight: fwNormal,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              50.height,
            ],
          ),
        ),
      ),
    );
  }
}
