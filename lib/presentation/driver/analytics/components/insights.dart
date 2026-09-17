import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/analytics/acceptance%20rate/acceptance_rate.dart';
import 'package:movera/presentation/driver/analytics/cancelation%20rate/cancelation_rate.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class AnalyticsInsights extends StatelessWidget {
  const AnalyticsInsights({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(
          text: 'Insights',
          color: AppColor.title,
          fontSize: 20,
          fontWeight: fwSemiBold,
        ),
        12.height,
        InkWell(
          onTap: () {
            Navigator.push(context, RightToLeftTransition(AcceptanceRate()));
          },
          child: _insightTile(
            leading: AppAssets.sucess,
            title: 'Acceptance rate',
            subtitle: '17%',
          ),
        ),
        8.height,
        InkWell(
          onTap: () {
            Navigator.push(context, RightToLeftTransition(CancelationRate()));
          },
          child: _insightTile(
            leading: AppAssets.cancelation,
            title: 'Cancelation Rate',
            subtitle: '6%',
          ),
        ),
      ],
    );
  }

  Widget _insightTile({
    required String leading,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12 * ResSize.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(leading, height: ResSize.h * 18),
          12.width,
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                        text: title,
                        color: AppColor.title,
                        fontSize: 16,
                        fontWeight: fwMedium,
                      ),
                      5.height,
                      TextWidget(
                        text: subtitle,
                        color: AppColor.subtitle,
                        fontSize: 14,
                        fontWeight: fwMedium,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColor.subtitle,
                  size: ResSize.h * 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
