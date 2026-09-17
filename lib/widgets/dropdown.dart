import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';

class AppDropdownField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final List<String> items;
  final ValueChanged<String>? onChanged;
  final double borderRadius;
  final double borderWidth;
  final Color borderColor;
  final Color fillColor;
  final double fontSize;
  final double contentVertPadding;
  final double contentHorizPadding;

  const AppDropdownField({
    super.key,
    required this.controller,
    this.hint,
    required this.items,
    this.onChanged,
    this.borderRadius = 8,
    this.borderWidth = 0,
    this.borderColor = Colors.transparent,
    this.fillColor = const Color(0xffF6F8FA),
    this.fontSize = 16,
    this.contentVertPadding = 16,
    this.contentHorizPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    final String? value = items.contains(controller.text)
        ? controller.text
        : null;
    return DropdownButtonFormField<String>(
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      dropdownColor: AppColor.white,

      value: value,
      isExpanded: true,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColor.title,
        size: ResSize.h * 22,
      ),
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResSize.w * contentHorizPadding,
          vertical: ResSize.h * contentVertPadding,
        ),
        hintStyle: GoogleFonts.poppins(
          color: AppColor.hintText,
          fontSize: ResSize.setSp(fontSize),
          fontWeight: fwMedium,
        ),
        hintText: hint,
        fillColor: fillColor,
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: borderColor, width: borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: borderColor, width: borderWidth),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: borderColor, width: borderWidth),
        ),
      ),
      style: GoogleFonts.poppins(
        color: AppColor.title,
        fontSize: ResSize.setSp(fontSize),
        fontWeight: fwMedium,
      ),
      items: items
          .map(
            (e) => DropdownMenuItem<String>(
              value: e,
              child: TextWidget(
                text: e,
                color: AppColor.title,
                fontSize: fontSize,
                fontWeight: fwMedium,
              ),
            ),
          )
          .toList(),
      onChanged: (val) {
        if (val == null) return;
        controller.text = val;
        if (onChanged != null) onChanged!(val);
      },
    );
  }
}
