import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/models/onboarding.dart';
import 'package:movera/widgets/custom_btn.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class PinVerification extends StatefulWidget {
  const PinVerification({super.key});

  @override
  State<PinVerification> createState() => _PinVerificationState();
}

class _PinVerificationState extends State<PinVerification> {
  List<OnBoardingModel> items = [
    OnBoardingModel(
      image: AppAssets.verify,
      title: "Verify all trips",
      subTitle: "Verify every trip through pin code from now",
    ),
    OnBoardingModel(
      image: AppAssets.verifyCrntSession,
      title: "Verify current session",
      subTitle: "From now until go offline",
    ),
    OnBoardingModel(
      image: AppAssets.dontVerify,
      title: "Don’t verify",
      subTitle: "Close verification",
    ),
  ];
  int selectedTab = 2;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actionsPadding: EdgeInsets.all(0),
        automaticallyImplyLeading: false,
        backgroundColor: AppColor.white,
        clipBehavior: Clip.none,
        foregroundColor: AppColor.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColor.title,
            size: ResSize.h * 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextWidget(
          text: "Pin Verification",
          fontSize: 16,
          fontWeight: fwSemiBold,
          color: AppColor.title,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              width: double.infinity,
              // ignore: deprecated_member_use
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(AppAssets.pinVerification),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResSize.w * 24,
                vertical: ResSize.h * 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: "Pin Verification",
                      fontSize: 24,
                      fontWeight: fwSemiBold,
                      color: AppColor.black,
                    ),
                    8.height,
                    TextWidget(
                      text:
                          "Add a 4-digit PIN to confirm you're picking up the correct rider.",
                      fontSize: 16,
                      fontWeight: fwNormal,
                      color: AppColor.title,
                    ),
                    32.height,
                    ...List.generate(items.length, (index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          top: index == 0 ? 0 : ResSize.h * 8,
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              selectedTab = index;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResSize.w * 12,
                              vertical: ResSize.h * 11,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedTab == index
                                    ? AppColor.title
                                    : Color(0xffD5D5D5),
                                width: selectedTab == index ? 2 : 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  items[index].image,
                                  height: ResSize.h * 25,
                                ),
                                8.width,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextWidget(
                                        text: items[index].title,
                                        fontSize: 16,
                                        fontWeight: fwSemiBold,
                                        color: AppColor.title,
                                      ),
                                      2.width,
                                      TextWidget(
                                        text: items[index].subTitle,
                                        fontSize: 11,
                                        fontWeight: fwNormal,
                                        color: AppColor.subtitle,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    24.height,
                    CustomButton(centerContent: "Save", onPressed: () {}),
                    24.height,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
