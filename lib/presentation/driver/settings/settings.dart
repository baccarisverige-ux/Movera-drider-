// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/models/title_image.dart';
import 'package:movera/presentation/driver/pin%20verification/pin_verification.dart';
import 'package:movera/presentation/driver/settings/accessibility/accessibility.dart';
import 'package:movera/presentation/driver/settings/sound%20&%20voice/sound_voice.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';
import 'package:riff_switch/riff_switch.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  List<TitleImageModel> items = [
    TitleImageModel(image: AppAssets.sound, title: "Sound & Voice"),
    TitleImageModel(image: AppAssets.darkMode, title: "Dark mode"),
    TitleImageModel(image: AppAssets.language, title: "Language"),
    TitleImageModel(image: AppAssets.access, title: "Accessibility"),
    TitleImageModel(image: AppAssets.pin, title: "Pin Verification"),
    TitleImageModel(
      image: AppAssets.emergencyCall,
      title: "Emergency Contacts",
    ),
    TitleImageModel(image: AppAssets.safety, title: "Safety "),
  ];
  bool val = false;
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
                onTap: () {
                  switch (index) {
                    case 0:
                      Navigator.push(
                        context,
                        RightToLeftTransition(SoundAndVoice()),
                      );
                      break;
                    case 1:
                      // Navigator.push(context, RightToLeftTransition(Analytics()));
                      break;
                    case 2:
                      // Navigator.push(context, RightToLeftTransition(Analytics()));
                      break;
                    case 3:
                      Navigator.push(
                        context,
                        RightToLeftTransition(Accessibility()),
                      );
                      break;
                    case 4:
                      Navigator.push(
                        context,
                        RightToLeftTransition(PinVerification()),
                      );
                      break;
                    case 5:
                      // Navigator.push(context, RightToLeftTransition(Analytics()));
                      break;
                    case 6:
                    // Navigator.push(context, RightToLeftTransition(Analytics()));
                    default:
                  }
                  // Navigator.push(context, RightToLeftTransition(Analytics()));
                },
                showArrow: items[index].image == AppAssets.darkMode
                    ? false
                    : true,
                trailing: items[index].image == AppAssets.darkMode
                    ? Transform.scale(
                        scale: 0.8,
                        child: RiffSwitch(
                          trackColor: WidgetStatePropertyAll(Color(0xffBEBEBE)),
                          activeTrackColor: Color(0xff00C24D),
                          value: val,
                          onChanged: (value) => setState(() {
                            val = value;
                          }),
                          type: RiffSwitchType.cupertino,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Color(0xffBEBEBE),
                          activeColor: Color(0xff00C24D),
                        ),
                      )
                    : items[index].image == AppAssets.language
                    ? TextWidget(
                        text: "English (US) ",
                        color: AppColor.title,
                        fontSize: 14,
                        fontWeight: fwMedium,
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
    required VoidCallback onTap,
    double iconScaleSize = 1,
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
            Expanded(
              child: TextWidget(
                text: title,
                color: AppColor.title,
                fontSize: 18,
                fontWeight: fwMedium,
              ),
            ),
            Row(
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
      ),
    );
  }
}
