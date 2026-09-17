// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/search%20location/drop_off_location.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

Future<T?> showDriverPickedLocationConfirmSheet<T>(
  BuildContext context,
  VoidCallback? onLocationSelected,
) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return DriverConfirmPickupLocationSheet(
        onLocationSelected: onLocationSelected,
      );
    },
  );
}

class DriverConfirmPickupLocationSheet extends StatelessWidget {
  final VoidCallback? onLocationSelected;
  const DriverConfirmPickupLocationSheet({super.key, this.onLocationSelected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: ResSize.w * 16,
            right: ResSize.w * 16,
            top: ResSize.h * 31,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pickup Location Section
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResSize.w * 7,
                  vertical: ResSize.h * 14,
                ),
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xff2E2C2C).withOpacity(0.12),
                      blurRadius: 50,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: ResSize.w * 40,
                      height: ResSize.h * 40,
                      decoration: BoxDecoration(
                        color: AppColor.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 20 * ResSize.h,
                      ),
                    ),
                    12.width,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWidget(
                            text: "Pickup location",
                            color: AppColor.subtitle,
                            fontSize: 10,
                            fontWeight: fwMedium,
                          ),
                          TextWidget(
                            text: "F10 markaz, Islamabad",
                            color: AppColor.darkTitle,
                            fontSize: 16,
                            fontWeight: fwNormal,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              16.height,
              // Location List
              ...List.generate(
                5,
                (index) => _buildLocationItem(index, context),
              ),
              300.height,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationItem(int index, BuildContext context) {
    final locations = [
      {
        'title': '765 Ludwig Passage',
        'subtitle': 'Hotel - Tashkent, Alisher Navol Stree, A',
      },
      {
        'title': '765 Ludwig Passage',
        'subtitle': 'Hotel - Tashkent, Alisher Navol Stree, A',
      },
      {
        'title': '765 Ludwig Passage',
        'subtitle': 'Hotel - Tashkent, Alisher Navol Stree, A',
      },
      {
        'title': '765 Ludwig Passage',
        'subtitle': 'Hotel - Tashkent, Alisher Navol Stree, A',
      },
      {
        'title': '765 Ludwig Passage',
        'subtitle': 'Hotel - Tashkent, Alisher Navol Stree, A',
      },
    ];

    return Column(
      children: [
        InkWell(
          onTap: () {
            Navigator.pop(context);
            showDriverSearchDropOffLocationSheet(context, () {
              Future.delayed(Duration(milliseconds: 300), () {
                onLocationSelected?.call();
              });
            });
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                AppAssets.locationFill,
                color: Colors.grey.shade400,
                height: ResSize.h * 20,
              ),
              12.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: locations[index]['title']!,
                      color: AppColor.title,
                      fontSize: 16,
                      fontWeight: fwNormal,
                    ),
                    4.height,
                    TextWidget(
                      text: locations[index]['subtitle']!,
                      color: AppColor.subtitle,
                      fontSize: 12,
                      fontWeight: fwNormal,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (index < 4) ...[
          10.height,
          Padding(
            padding: EdgeInsets.only(left: ResSize.w * 30),
            child: Divider(color: Colors.grey.shade200, height: 1),
          ),
          10.height,
        ],
      ],
    );
  }
}
