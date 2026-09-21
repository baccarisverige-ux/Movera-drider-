import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class AnalyticsReviews extends StatelessWidget {
  const AnalyticsReviews({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: ResSize.h * 44,
          width: ResSize.w * 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: AssetImage(AppAssets.profileImg),
              fit: BoxFit.cover,
            ),
          ),
        ),
        12.width,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextWidget(
                      text: 'Sofia Lindgren',
                      color: AppColor.title,
                      fontSize: 16,
                      fontWeight: fwMedium,
                    ),
                  ),
                  TextWidget(
                    text: '18 Sep, 2026',
                    color: AppColor.subtitle,
                    fontSize: 12,
                    fontWeight: fwSemiBold,
                  ),
                ],
              ),
              3.height,
              Row(
                children: List.generate(
                  5,
                  (index) => Padding(
                    padding: EdgeInsets.only(right: 3 * ResSize.w),
                    child: Icon(
                      Icons.star_rounded,
                      color: const Color(0xFF12AF54),
                      size: 18 * ResSize.h,
                    ),
                  ),
                ),
              ),
              7.height,
              TextWidget(
                text:
                    'Quiet ride from Södermalm to Arlanda. Driver waited at the door and the car was clean.',
                color: AppColor.subtitle,
                fontSize: 14,
                fontWeight: fwMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
