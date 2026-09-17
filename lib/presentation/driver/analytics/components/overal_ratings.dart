import 'package:flutter/material.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class AnalyticsOverallRatings extends StatelessWidget {
  const AnalyticsOverallRatings({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(
          text: 'Overall Rating',
          color: AppColor.title,
          fontSize: 20,
          fontWeight: fwSemiBold,
        ),
        8.height,
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10 * ResSize.w,
                vertical: 3 * ResSize.h,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF12AF54),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: Colors.white,
                    size: 24 * ResSize.h,
                  ),
                  6.width,
                  TextWidget(
                    text: '4.9',
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: fwSemiBold,
                  ),
                ],
              ),
            ),
            8.width,
            TextWidget(
              text: '200 people rated',
              color: AppColor.subtitle,
              fontSize: 14,
              fontWeight: fwSemiBold,
            ),
          ],
        ),
        26.height,
        _ratingBar('5 Star', 0.95),
        10.height,
        _ratingBar('4 Star', 0.35),
        10.height,
        _ratingBar('3 Star', 0.10),
        10.height,
        _ratingBar('2 Star', 0.03),
        10.height,
        _ratingBar('1 Star', 0.02),
      ],
    );
  }

  Widget _ratingBar(String label, double percent) {
    return Row(
      children: [
        SizedBox(
          width: 52 * ResSize.w,
          child: TextWidget(
            text: label,
            color: AppColor.title,
            fontSize: 12,
            fontWeight: fwMedium,
          ),
        ),
        8.width,
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: ResSize.w * 50),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: ResSize.h * 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percent,
                  child: Container(
                    height: ResSize.h * 9,
                    decoration: BoxDecoration(
                      color: const Color(0xFF12AF54),
                      borderRadius: BorderRadius.circular(21),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
