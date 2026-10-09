import 'package:flutter/material.dart';
import 'package:movera/constants/appcolors.dart';

class CustomCheckBox extends StatelessWidget {
  final bool value;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  const CustomCheckBox({
    super.key,
    this.onPressed,
    required this.value,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: value,
      semanticLabel: semanticLabel,
      onChanged: onPressed == null ? null : (_) => onPressed!(),
      activeColor: AppColor.primary,
      checkColor: AppColor.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: const BorderSide(color: AppColor.border, width: .5),
    );
  }
}
