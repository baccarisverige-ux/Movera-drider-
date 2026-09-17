// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/models/onboarding.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';
import 'package:riff_switch/riff_switch.dart';

class Accessibility extends StatefulWidget {
  const Accessibility({super.key});

  @override
  State<Accessibility> createState() => _AccessibilityState();
}

class _AccessibilityState extends State<Accessibility> {
  List<OnBoardingModel> items = [
    OnBoardingModel(
      image: AppAssets.hearing,
      title: "Hearing",
      subTitle: "choose to disclose whether your are deaf or hard of hearing",
    ),
    OnBoardingModel(
      image: AppAssets.flash,
      title: "Flash for requests",
      subTitle:
          "Your phone screen will flash and play an audio alert upon receiving request",
    ),
    OnBoardingModel(
      image: AppAssets.vibration,
      title: "Vibration for requests",
      subTitle:
          "Your phone will vibrate and play an audio alert upon receiving request",
    ),
  ];
  bool val1 = false;
  bool val2 = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        actionsPadding: EdgeInsets.all(0),
        automaticallyImplyLeading: false,
        backgroundColor: AppColor.white,
        clipBehavior: Clip.none,
        foregroundColor: AppColor.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColor.title,
            size: ResSize.h * 18,
          ),
        ),
        centerTitle: true,
        title: TextWidget(
          text: "App setting",
          color: AppColor.title,
          fontSize: 16,
          fontWeight: fwMedium,
        ),
      ),
      body: SingleChildScrollView(
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
            ...List.generate(items.length, (index) {
              return _menuItem(
                icon: items[index].image,
                title: items[index].title,
                subTitle: items[index].subTitle,
                onTap: () {
                  // Navigator.push(context, RightToLeftTransition(Analytics()));
                },
                showArrow: items[index].image == AppAssets.hearing
                    ? true
                    : false,
                trailing: items[index].image == AppAssets.flash
                    ? Transform.scale(
                        scale: 0.8,
                        child: RiffSwitch(
                          trackColor: WidgetStatePropertyAll(Color(0xffBEBEBE)),
                          activeTrackColor: Color(0xff00C24D),
                          value: val1,
                          onChanged: (value) => setState(() {
                            val1 = value;
                          }),
                          type: RiffSwitchType.cupertino,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Color(0xffBEBEBE),
                          activeColor: Color(0xff00C24D),
                        ),
                      )
                    : items[index].image == AppAssets.vibration
                    ? Transform.scale(
                        scale: 0.8,
                        child: RiffSwitch(
                          trackColor: WidgetStatePropertyAll(Color(0xffBEBEBE)),
                          activeTrackColor: Color(0xff00C24D),
                          value: val2,
                          onChanged: (value) => setState(() {
                            val2 = value;
                          }),
                          type: RiffSwitchType.cupertino,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Color(0xffBEBEBE),
                          activeColor: Color(0xff00C24D),
                        ),
                      )
                    : SizedBox(),
              );
            }),

            24.height,
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required String icon,
    required String title,
    subTitle,
    required VoidCallback onTap,
    double iconScaleSize = 1.2,
    bool showArrow = true,
    Widget trailing = const SizedBox(),
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: AppColor.primary.withOpacity(0.1),
      highlightColor: AppColor.primary.withOpacity(0.1),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 14 * ResSize.h,
          horizontal: screenHorizPadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform.scale(
              scale: iconScaleSize,
              child: Padding(
                padding: EdgeInsets.only(top: ResSize.h * 8),
                child: Image.asset(
                  icon,
                  height: ResSize.h * 20,
                  color: AppColor.title,
                ),
              ),
            ),
            16.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextWidget(
                          text: title,
                          color: AppColor.title,
                          fontSize: 18,
                          fontWeight: fwMedium,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          trailing,
                          showArrow
                              ? Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: AppColor.subtitle,
                                  size: ResSize.h * 18,
                                )
                              : SizedBox(),
                        ],
                      ),
                    ],
                  ),
                  2.height,
                  Padding(
                    padding: EdgeInsets.only(right: ResSize.w * 16),
                    child: TextWidget(
                      text: subTitle,
                      color: AppColor.subtitle,
                      fontSize: 14,
                      fontWeight: fwNormal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
