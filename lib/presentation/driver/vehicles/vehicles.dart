import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/models/onboarding.dart';
import 'package:movera/presentation/driver/add%20vehicle/add_vehicle.dart';
import 'package:movera/widgets/custom_btn.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

// ignore: must_be_immutable
class DriverVehicles extends StatelessWidget {
  DriverVehicles({super.key});
  List<OnBoardingModel> vehicles = [
    OnBoardingModel(
      image: AppAssets.vehicle1,
      title: "2022 Mercedes-Benz C200",
      subTitle: "LA-319",
    ),
    OnBoardingModel(
      image: AppAssets.vehicle2,
      title: "2024 BMW i7 Electric Sedan",
      subTitle: "WA-319",
    ),
    OnBoardingModel(
      image: AppAssets.vehicle1,
      title: "2022 Mercedes-Benz C200",
      subTitle: "LA-319",
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColor.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColor.title,
            size: ResSize.h * 18,
          ),
        ),
        centerTitle: true,
        title: TextWidget(
          text: 'Vehicle',
          color: AppColor.title,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, TopToBottomTransition(AddVehicle()));
            },
            icon: Image.asset(AppAssets.addVehicle, height: ResSize.h * 25),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...List.generate(vehicles.length, (index) {
              return Column(
                children: [
                  Container(
                    height: ResSize.h * 6,
                    width: double.infinity,
                    color: const Color(0xFFFAFAFA),
                  ),
                  vehicleCard(
                    title: vehicles[index].title,
                    image: vehicles[index].image,
                    subTitle: vehicles[index].subTitle,
                  ),
                ],
              );
            }),
            22.height,
          ],
        ),
      ),
    );
  }

  Widget vehicleCard({String? image, title, subTitle}) {
    return SizedBox(
      // padding: EdgeInsets.symmetric(vertical: ResSize.h * 12),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: ResSize.h * 156,
              width: double.infinity,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Image.asset(image!, height: ResSize.h * 146),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.only(top: ResSize.h * 20),
                      child: Container(
                        height: ResSize.h * 35,
                        width: ResSize.w * 35,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Color(0xffEAEAEA),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.more_vert_rounded,
                            color: AppColor.title,
                            size: ResSize.h * 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            33.height,
            TextWidget(
              text: title,
              color: AppColor.title,
              fontSize: 20,
              fontWeight: fwSemiBold,
            ),
            2.height,
            TextWidget(
              text: subTitle,
              color: AppColor.subtitle,
              fontSize: 16,
              fontWeight: fwMedium,
            ),
            5.height,
            TextWidget(
              text: "Trip only",
              color: AppColor.subtitle,
              fontSize: 16,
              fontWeight: fwMedium,
            ),
            22.height,
            CustomButton(
              centerContent: "Manage Vehicle",
              btncolor: Color(0xffF0F0F0),
              textColor: AppColor.title,
              borderRadius: 8,
              fontSize: 16,
              onPressed: () {},
            ),
            22.height,
          ],
        ),
      ),
    );
  }
}
