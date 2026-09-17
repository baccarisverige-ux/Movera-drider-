import 'package:flutter/material.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class AnalyticsAppBar extends StatelessWidget {
  const AnalyticsAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      actionsPadding: EdgeInsets.all(0),
      automaticallyImplyLeading: false,
      backgroundColor: AppColor.white,
      clipBehavior: Clip.none,
      foregroundColor: AppColor.white,
      surfaceTintColor: Colors.transparent,
      leadingWidth: MediaQuery.of(context).size.width * 0.7,
      elevation: 0,
      leading: Row(
        children: [
          // 8.width,
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: AppColor.title,
              size: ResSize.h * 18,
            ),
          ),
          TextWidget(
            text: "Analytics",
            color: AppColor.title,
            fontSize: 16,
            fontWeight: fwBold,
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Row(
            children: [
              TextWidget(
                text: "Today",
                color: AppColor.title,
                fontSize: 16,
                fontWeight: fwBold,
              ),
              6.width,
              Transform.scale(
                scale: 1.4,
                child: Icon(
                  Icons.arrow_drop_down_rounded,
                  color: AppColor.title,
                  size: ResSize.h * 25,
                ),
              ),
            ],
          ),
        ),
        8.width,
      ],
    );
  }
}
