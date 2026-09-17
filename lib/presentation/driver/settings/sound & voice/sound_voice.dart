import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';
import 'package:riff_switch/riff_switch.dart';

class SoundAndVoice extends StatefulWidget {
  const SoundAndVoice({super.key});

  @override
  State<SoundAndVoice> createState() => _SoundAndVoiceState();
}

class _SoundAndVoiceState extends State<SoundAndVoice> {
  double generalVolume = 0.35; // 0..1
  bool alwaysPlayRequests = true;
  bool voiceNavigation = true;
  bool readRiderMessages = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColor.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColor.title,
            size: ResSize.h * 18,
          ),
        ),
        centerTitle: true,
        title: TextWidget(
          text: 'Sound & voice',
          color: AppColor.title,
          fontSize: 16,
          fontWeight: FontWeight.w600,
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
              color: const Color(0xFFFAFAFA),
            ),
            16.height,

            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: 'General',
                    color: AppColor.title,
                    fontSize: 18,
                    fontWeight: fwMedium,
                  ),
                  12.height,
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4 * ResSize.h,
                      activeTrackColor: AppColor.primary,
                      inactiveTrackColor: const Color(0xFFCCCCCC),
                      thumbColor: Colors.white,
                      overlayColor: Colors.transparent,
                      thumbShape: const RoundSliderThumbShape(
                        elevation: 3,

                        enabledThumbRadius: 11,
                      ),
                    ),
                    child: Slider(
                      value: generalVolume,
                      onChanged: (v) => setState(() => generalVolume = v),
                    ),
                  ),
                  22.height,
                  TextWidget(
                    text: 'Alerts',
                    color: AppColor.title,
                    fontSize: 18,
                    fontWeight: fwMedium,
                  ),
                  4.height,
                  TextWidget(
                    text: 'Include notifications and trip requests',
                    color: AppColor.subtitle,
                    fontSize: 14,
                    fontWeight: fwNormal,
                  ),
                  17.height,
                  _testTile(
                    title: 'Test alerts volume',
                    subtitle: 'Controlled by device volume',
                    onTest: _onTestAlerts,
                  ),
                  24.height,
                  Row(
                    children: [
                      Expanded(
                        child: TextWidget(
                          text: 'Always play trip requests',
                          color: AppColor.title,
                          fontSize: 18,
                          fontWeight: fwMedium,
                        ),
                      ),
                      Transform.scale(
                        scale: 0.9,
                        child: RiffSwitch(
                          type: RiffSwitchType.cupertino,
                          value: alwaysPlayRequests,
                          onChanged: (v) =>
                              setState(() => alwaysPlayRequests = v),
                          activeColor: const Color(0xFF00C24D),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: const Color(0xFFBEBEBE),
                          activeTrackColor: const Color(0xFF00C24D),
                          trackColor: const WidgetStatePropertyAll(
                            Color(0xFFBEBEBE),
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextWidget(
                    text: 'Play even when device is muted/silent',
                    color: AppColor.subtitle,
                    fontSize: 14,
                    fontWeight: fwNormal,
                  ),
                  20.height,
                ],
              ),
            ),

            Divider(
              color: const Color(0xFFEAEAEA),
              thickness: 1 * ResSize.h,
              height: 0,
            ),

            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16 * ResSize.w,
                vertical: 18 * ResSize.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: 'Voice',
                    color: AppColor.title,
                    fontSize: 18,
                    fontWeight: fwMedium,
                  ),
                  4.height,
                  TextWidget(
                    text: 'Include speech like voice navigation',
                    color: const Color(0xFF9F9F9F),
                    fontSize: 14,
                    fontWeight: fwNormal,
                  ),
                  12.height,
                  _testTile(
                    title: 'Test voice volume',
                    subtitle: 'Controlled by device volume',
                    onTest: _onTestVoice,
                  ),
                  24.height,
                  Row(
                    children: [
                      Expanded(
                        child: TextWidget(
                          text: 'Voice Navigation',
                          color: AppColor.title,
                          fontSize: 18,
                          fontWeight: fwMedium,
                        ),
                      ),
                      Transform.scale(
                        scale: 0.9,
                        child: RiffSwitch(
                          type: RiffSwitchType.cupertino,
                          value: voiceNavigation,
                          onChanged: (v) => setState(() => voiceNavigation = v),
                          activeColor: const Color(0xFF00C24D),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: const Color(0xFFBEBEBE),
                          activeTrackColor: const Color(0xFF00C24D),
                          trackColor: const WidgetStatePropertyAll(
                            Color(0xFFBEBEBE),
                          ),
                        ),
                      ),
                    ],
                  ),
                  18.height,
                  Row(
                    children: [
                      Expanded(
                        child: TextWidget(
                          text: 'Read rider messages',
                          color: AppColor.title,
                          fontSize: 18,
                          fontWeight: fwMedium,
                        ),
                      ),
                      Transform.scale(
                        scale: 0.9,
                        child: RiffSwitch(
                          type: RiffSwitchType.cupertino,
                          value: readRiderMessages,
                          onChanged: (v) =>
                              setState(() => readRiderMessages = v),
                          activeColor: const Color(0xFF00C24D),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: const Color(0xFFBEBEBE),
                          activeTrackColor: const Color(0xFF00C24D),
                          trackColor: const WidgetStatePropertyAll(
                            Color(0xFFBEBEBE),
                          ),
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
    );
  }

  Widget _testTile({
    required String title,
    required String subtitle,
    required VoidCallback onTest,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: const Color(0xFF233C8E).withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 14 * ResSize.w,
        vertical: 14 * ResSize.h,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: title,
                  color: AppColor.title,
                  fontSize: 18,
                  fontWeight: fwMedium,
                ),
                4.height,
                TextWidget(
                  text: subtitle,
                  color: AppColor.subtitle,
                  fontSize: 14,
                  fontWeight: fwNormal,
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF173C5E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 12 * ResSize.w,
                vertical: 6 * ResSize.h,
              ),
            ),
            onPressed: onTest,
            child: Row(
              children: [
                Image.asset(
                  AppAssets.sound,
                  height: 22 * ResSize.h,
                  color: AppColor.white,
                ),
                6.width,
                TextWidget(
                  text: 'Test',
                  color: AppColor.white,
                  fontSize: 12,
                  fontWeight: fwMedium,
                ),
                2.width,
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onTestAlerts() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Playing alert sound (mock)')));
  }

  void _onTestVoice() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Playing voice sound (mock)')));
  }
}
