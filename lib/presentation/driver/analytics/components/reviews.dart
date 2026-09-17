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
                      text: 'Jeff Pfannerstill',
                      color: AppColor.title,
                      fontSize: 16,
                      fontWeight: fwMedium,
                    ),
                  ),
                  TextWidget(
                    text: '12 Mar, 2025',
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
                    'Similique doloremque aut quae quos vel modi iure repellendus tenetur.',
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
