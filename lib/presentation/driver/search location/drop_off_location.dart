import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_btn.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

Future<T?> showDriverSearchDropOffLocationSheet<T>(
  BuildContext context,
  VoidCallback? onLocationSelected,
) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return DriverSearchDropOffLocation(
        onLocationSelected: onLocationSelected,
      );
    },
  );
}

class DriverSearchDropOffLocation extends StatelessWidget {
  final VoidCallback? onLocationSelected;
  const DriverSearchDropOffLocation({super.key, this.onLocationSelected});

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
              TextWidget(
                text: "765 Conn Shore",
                fontSize: 24,
                color: AppColor.title,
                fontWeight: fwMedium,
              ),
              8.height,
              TextWidget(
                text: "Heading this way",
                fontSize: 14,
                color: Color(0xff0088FF),
                fontWeight: fwNormal,
              ),
              28.height,
              Row(
                children: [
                  Image.asset(AppAssets.addArrivalTime, height: ResSize.h * 18),
                  4.width,
                  TextWidget(
                    text: "Add arrival time",
                    fontSize: 14,
                    color: AppColor.title,
                    fontWeight: fwNormal,
                  ),
                ],
              ),
              26.height,
              CustomButton(
                centerContent: "Set Destination",
                onPressed: () {
                  Navigator.pop(context);
                  Future.delayed(Duration(milliseconds: 300), () {
                    onLocationSelected?.call();
                  });
                },
              ),
              20.height,
            ],
          ),
        ),
      ),
    );
  }
}
