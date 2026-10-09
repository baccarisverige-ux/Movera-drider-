import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';

class AppDropdownField extends StatefulWidget {
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
  State<AppDropdownField> createState() => _AppDropdownFieldState();
}

class _AppDropdownFieldState extends State<AppDropdownField> {
  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(AppDropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final items = widget.items.toSet().toList(growable: false);
    final String? value = items.contains(controller.text)
        ? controller.text
        : null;
    return DropdownButtonFormField<String>(
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      dropdownColor: AppColor.white,

      initialValue: value,
      isExpanded: true,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColor.title,
        size: ResSize.h * 22,
      ),
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResSize.w * widget.contentHorizPadding,
          vertical: ResSize.h * widget.contentVertPadding,
        ),
        hintStyle: GoogleFonts.poppins(
          color: AppColor.hintText,
          fontSize: ResSize.setSp(widget.fontSize),
          fontWeight: fwMedium,
        ),
        hintText: widget.hint,
        fillColor: widget.fillColor,
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: widget.borderColor,
            width: widget.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: widget.borderColor,
            width: widget.borderWidth,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: widget.borderColor,
            width: widget.borderWidth,
          ),
        ),
      ),
      style: GoogleFonts.poppins(
        color: AppColor.title,
        fontSize: ResSize.setSp(widget.fontSize),
        fontWeight: fwMedium,
      ),
      items: items
          .map(
            (e) => DropdownMenuItem<String>(
              value: e,
              child: TextWidget(
                text: e,
                color: AppColor.title,
                fontSize: widget.fontSize,
                fontWeight: fwMedium,
              ),
            ),
          )
          .toList(),
      onChanged: (val) {
        if (val == null ||
            !mounted ||
            !identical(controller, widget.controller) ||
            ModalRoute.of(context)?.isCurrent == false ||
            !widget.items.contains(val)) {
          return;
        }
        controller.text = val;
        widget.onChanged?.call(val);
      },
    );
  }
}
