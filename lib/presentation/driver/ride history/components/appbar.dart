import 'package:flutter/material.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class DriverRideHistoryAppBar extends StatelessWidget {
  const DriverRideHistoryAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      actionsPadding: EdgeInsets.all(0),
      automaticallyImplyLeading: false,
      backgroundColor: AppColor.white,
      clipBehavior: Clip.none,
      foregroundColor: AppColor.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: TextWidget(
        text: "History",
        color: AppColor.black,
        fontSize: 16,
        fontWeight: fwSemiBold,
      ),
      leading: Row(
        children: [
          16.width,
          InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              height: ResSize.h * 30,
              width: ResSize.w * 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColor.border, width: 0.3),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Color(0xff999999).withOpacity(0.1),
                    blurRadius: 40,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppColor.title,
                  size: ResSize.h * 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
