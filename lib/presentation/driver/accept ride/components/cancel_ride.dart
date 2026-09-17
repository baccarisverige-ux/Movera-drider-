import 'package:flutter/material.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_btn.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

void showDriverRideCanceledDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: ResSize.w * 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResSize.w * 20,
            vertical: ResSize.h * 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              TextWidget(
                text: "Ride Canceled",
                color: AppColor.title,
                fontSize: 24,
                fontWeight: fwSemiBold,
              ),
              4.height,
              TextWidget(
                text: "The passenger has canceled the ride",
                color: AppColor.subtitle,
                fontSize: 14,
                fontWeight: fwMedium,
              ),
              15.height,

              // Red car icon
              Center(
                child: Image.asset(
                  AppAssets.cancelRideImg, // e.g., your red car cancel icon
                  height: ResSize.h * 80,
                ),
              ),
              15.height,

              // Passenger Info Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    height: ResSize.h * 50,
                    width: ResSize.w * 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage(AppAssets.profileImg),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  12.width,

                  // Name & Price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          text: "Dora Sipes",
                          color: AppColor.title,
                          fontSize: 16,
                          fontWeight: fwMedium,
                        ),
                        4.height,
                        TextWidget(
                          text: "\$12.55",
                          color: Color(0xffE16255),
                          fontSize: 14,
                          fontWeight: fwNormal,
                        ),
                      ],
                    ),
                  ),
                  TextWidget(
                    text: "10:30 AM",
                    color: AppColor.subtitle,
                    fontSize: 12,
                    fontWeight: fwNormal,
                  ),
                ],
              ),
              15.height,

              // Location Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppColor.subtitle,
                    size: ResSize.h * 16,
                  ),
                  8.width,
                  Expanded(
                    child: TextWidget(
                      text: "1141 central park",
                      color: AppColor.title,
                      fontSize: 12,
                      fontWeight: fwNormal,
                    ),
                  ),
                ],
              ),

              12.height,

              // Message
              TextWidget(
                text:
                    "Unfortunately, the passenger decided to cancel the trip. You are now available for new ride requests",
                color: AppColor.title,
                fontSize: 12,
                textAlign: TextAlign.start,
                fontWeight: fwNormal,
              ),

              16.height,

              // View other rides button
              CustomButton(
                centerContent: "View other rides",
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              16.height,

              // Footer note
              TextWidget(
                text:
                    "No cancellation fee applies since the passenger canceled before pickup",
                color: AppColor.subtitle,
                fontSize: 12,
                textAlign: TextAlign.center,
                fontWeight: fwNormal,
              ),
            ],
          ),
        ),
      );
    },
  );
}
