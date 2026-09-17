import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/search%20location/confirm%20pickup/confirm_location.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/custom_textfield.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

Future<T?> showDriverSearchPickupLocationSheet<T>(
  BuildContext context,
  VoidCallback? onLocationSelected,
) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return DriverSearchPickupLocation(onLocationSelected: onLocationSelected);
    },
  );
}

class DriverSearchPickupLocation extends StatefulWidget {
  final VoidCallback? onLocationSelected;
  const DriverSearchPickupLocation({super.key, this.onLocationSelected});

  @override
  State<DriverSearchPickupLocation> createState() =>
      _DriverSearchPickupLocationState();
}

class _DriverSearchPickupLocationState
    extends State<DriverSearchPickupLocation> {
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
              Container(
                padding: EdgeInsets.symmetric(vertical: ResSize.h * 8),
                decoration: BoxDecoration(
                  color: Color(0xffF3F6FB),
                  border: Border.all(color: AppColor.border, width: 0.5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: ResSize.w * 70),
                      child: customTextfield(
                        borderColor: Colors.transparent,
                        borderWidth: 0,
                        borderRadius: 0,
                        contentHorizPadding: 10,
                        hint: "Pick-Up Location",
                        contentVertPadding: 0,
                        fontSize: 16,
                        textColor: AppColor.black,
                        fillColor: Colors.transparent,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {},
                            child: SizedBox(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Image.asset(
                                    AppAssets.gps,
                                    height: ResSize.h * 18,
                                    color: AppColor.black,
                                  ),
                                  4.width,
                                  TextWidget(
                                    text: "CURRENT",
                                    fontSize: 8,
                                    fontWeight: fwBold,
                                    color: AppColor.black,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              2.height,
              Row(
                children: [
                  Expanded(
                    child: _buildSavedPlace(
                      icon: AppAssets.home,
                      title: "Home",
                      subtitle: "3.5km| Dubai hotel...",
                      isLeftRounded: true,
                    ),
                  ),
                  2.width,
                  Expanded(
                    child: _buildSavedPlace(
                      icon: AppAssets.office,
                      title: "Office",
                      subtitle: "5.1km| Sharjah mall...",
                    ),
                  ),
                  2.width,
                  InkWell(
                    onTap: () {
                      // Navigator.push(
                      //   context,
                      //   BottomToTopTransition(SavedPlaces()),
                      // );
                    },
                    child: _buildFavorite(),
                  ),
                ],
              ),
              16.height,
              // Location List
              ...List.generate(5, (index) => _buildLocationItem(index)),
              200.height,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedPlace({
    required String icon,
    required String title,
    required String subtitle,
    bool isLeftRounded = false,
  }) {
    return Container(
      height: ResSize.h * 57,
      decoration: BoxDecoration(
        borderRadius: isLeftRounded
            ? const BorderRadius.only(bottomLeft: Radius.circular(10))
            : null,
        color: AppColor.liteBlue,
        border: Border.all(color: AppColor.border, width: 0.5),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: ResSize.w * 10),
        child: Row(
          children: [
            Image.asset(icon, height: ResSize.h * 20),
            10.width,
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: title,
                    fontSize: 12,
                    fontWeight: fwSemiBold,
                    color: const Color(0xff5E5E5E),
                  ),
                  2.height,
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: fwNormal,
                      color: const Color(0xff5E5E5E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Favorite Box
  Widget _buildFavorite() {
    return Container(
      height: ResSize.h * 57,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(10)),
        color: AppColor.liteBlue,
        border: Border.all(color: AppColor.border, width: 0.5),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: ResSize.w * 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AppAssets.star, height: ResSize.h * 18),
            4.height,
            TextWidget(
              text: "Favorite",
              fontSize: 12,
              fontWeight: fwSemiBold,
              color: const Color(0xff5E5E5E),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationItem(int index) {
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
            showDriverPickedLocationConfirmSheet(context, () {
              Future.delayed(Duration(milliseconds: 300), () {
                widget.onLocationSelected?.call();
              });
            });
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                AppAssets.time,
                color: Colors.grey.shade800,
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
