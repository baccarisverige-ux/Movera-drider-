import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/responsive_size.dart';

class CustomExpansionTile extends StatelessWidget {
  final String? iconAsset;
  final IconData? iconData;
  final String title;
  final Widget child;
  final Color? iconColor;
  final Color? titleColor;
  final Color? backgroundColor;
  final double? iconSize;
  final double? titleFontSize;
  final FontWeight? titleFontWeight;
  final EdgeInsetsGeometry? padding;
  final bool initiallyExpanded;
  final Color? expandIconColor;

  const CustomExpansionTile({
    super.key,
    this.iconAsset,
    this.iconData,
    required this.title,
    required this.child,
    this.iconColor,
    this.titleColor,
    this.backgroundColor,
    this.iconSize,
    this.titleFontSize,
    this.titleFontWeight,
    this.padding,
    this.initiallyExpanded = false,
    this.expandIconColor,
  }) : assert(
         iconAsset != null || iconData != null,
         'Either iconAsset or iconData must be provided',
       );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.transparent,
      child: ExpansionTile(
        collapsedBackgroundColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        shape: Border.all(color: Colors.transparent, width: 0),
        initiallyExpanded: initiallyExpanded,
        clipBehavior: Clip.none,
        tilePadding: padding ?? EdgeInsets.symmetric(vertical: 4 * ResSize.h),
        childrenPadding: EdgeInsets.only(
          left: (iconSize ?? 20 * ResSize.h) + 8 * ResSize.w,
          right: 8 * ResSize.w,
          bottom: 12 * ResSize.h,
        ),
        iconColor: expandIconColor ?? AppColor.title,
        collapsedIconColor: expandIconColor ?? AppColor.title,
        leading: iconAsset != null
            ? Image.asset(
                iconAsset!,
                height: iconSize ?? 20 * ResSize.h,
                color: iconColor ?? AppColor.title,
              )
            : Icon(
                iconData!,
                size: iconSize ?? 20 * ResSize.h,
                color: iconColor ?? AppColor.title,
              ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: ResSize.setSp(titleFontSize ?? 16),
            color: titleColor ?? AppColor.title,
            fontWeight: titleFontWeight ?? fwMedium,
          ),
        ),
        children: [child],
      ),
    );
  }
}
