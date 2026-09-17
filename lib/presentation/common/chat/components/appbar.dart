import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class ChatAppBar extends StatelessWidget {
  const ChatAppBar({super.key});

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
          8.width,
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_rounded,
              color: AppColor.title,
              size: ResSize.h * 23,
            ),
          ),
          TextWidget(
            text: "Driver’s name",
            color: AppColor.title,
            fontSize: 16,
            fontWeight: fwBold,
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Image.asset(AppAssets.phoneOutl, height: ResSize.h * 23),
        ),
        8.width,
      ],
    );
  }
}
