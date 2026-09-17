// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:movera/constants/appcolors.dart';
import 'responsive_size.dart';

class CustomCheckBox extends StatelessWidget {
  final bool value;
  final VoidCallback? onPressed;
  const CustomCheckBox({super.key, this.onPressed, required this.value});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Container(
        height: ResSize.h * 20,
        width: ResSize.w * 20,
        decoration: BoxDecoration(
          border: value
              ? Border.all(color: Colors.transparent, width: 0)
              : Border.all(color: AppColor.border, width: 0.5),
          borderRadius: BorderRadius.circular(4),
          color: value ? AppColor.primary : Colors.transparent,
        ),
        child: Center(
          child: value
              ? Icon(
                  Icons.done_rounded,
                  size: ResSize.h * 15,
                  color: AppColor.white,
                )
              : SizedBox(),
        ),
      ),
    );
  }
}
