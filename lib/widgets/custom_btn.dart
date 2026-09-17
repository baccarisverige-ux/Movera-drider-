import 'package:flutter/material.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'custom_text_widget.dart';
import 'responsive_size.dart';

// ignore: must_be_immutable
class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double borderRadius;
  final double height;
  final double width;
  final Color btncolor;
  final String centerContent;
  final double borderwidth;
  final Color borderColor;
  final Color textColor;
  final double fontSize;
  final Widget icon;
  final Widget loader;
  bool isLoading;
  final double iconSize;
  CustomButton({
    super.key,
    this.onPressed,
    this.borderRadius = 12,
    this.height = 56,
    this.width = double.infinity,
    this.btncolor = AppColor.btn,
    required this.centerContent,
    this.borderwidth = 0,
    this.borderColor = Colors.transparent,
    this.textColor = AppColor.whiteText,
    this.fontSize = 16,
    this.icon = const SizedBox(),
    this.loader = const SizedBox(),
    this.isLoading = false,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      clipBehavior: Clip.none,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      height: ResSize.h * height,
      minWidth: width,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      color: null,
      child: Container(
        height: ResSize.h * height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: btncolor,
          border: Border.all(color: borderColor, width: borderwidth),
        ),
        child: Center(
          child: isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [loader],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    icon,
                    TextWidget(
                      fontSize: ResSize.setSp(fontSize),
                      text: centerContent,
                      color: textColor,
                      fontWeight: fwSemiBold,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
