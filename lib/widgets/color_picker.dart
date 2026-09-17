// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class ColorPickerDialog {
  static void show(Function(String) onColorSelected) {
    final List<Map<String, dynamic>> colors = [
      {"name": "Red", "color": Colors.red},
      {"name": "Blue", "color": Colors.blue},
      {"name": "Green", "color": Colors.green},
      {"name": "Black", "color": Colors.black},
      {"name": "White", "color": Colors.white},
      {"name": "Gray", "color": Colors.grey},
      {"name": "Silver", "color": Colors.blueGrey},
      {"name": "Yellow", "color": Colors.yellow},
      {"name": "Orange", "color": Colors.orange},
      {"name": "Brown", "color": Colors.brown},
      {"name": "Purple", "color": Colors.purple},
      {"name": "Pink", "color": Colors.pink},
    ];

    Get.dialog(
      barrierColor: Colors.black.withOpacity(0.5),
      Dialog.fullscreen(
        backgroundColor: Colors.black.withOpacity(0.5),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenHorizPadding + ResSize.h * 16,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResSize.w * 8,
                    vertical: ResSize.h * 20,
                  ),
                  child: GridView.builder(
                    clipBehavior: Clip.none,
                    padding: EdgeInsets.all(0),
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: colors.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 3 colors per row
                      mainAxisExtent: ResSize.h * 75,
                      crossAxisSpacing: ResSize.w * 8,
                      mainAxisSpacing: ResSize.h * 8,
                    ),
                    itemBuilder: (context, index) {
                      final item = colors[index];
                      return GestureDetector(
                        onTap: () {
                          onColorSelected(item["name"]);
                          Get.back();
                        },
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                width: 50,
                                decoration: BoxDecoration(
                                  color: item["color"],
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black26),
                                ),
                              ),
                            ),
                            6.height,
                            TextWidget(
                              text: item["name"],
                              fontSize: 14,
                              color: AppColor.black,
                              fontWeight: fwMedium,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
