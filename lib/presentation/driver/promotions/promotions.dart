import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class Promotions extends StatefulWidget {
  const Promotions({super.key});

  @override
  State<Promotions> createState() => _PromotionsState();
}

class _PromotionsState extends State<Promotions> {
  int selectedTab = 1;
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
        leading: Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: AppColor.title,
                size: ResSize.h * 20,
              ),
            ),
          ],
        ),
        centerTitle: true,
        title: TextWidget(
          text: "Promotions",
          color: AppColor.title,
          fontSize: 16,
          fontWeight: fwBold,
        ),
      ),
      body: SizedBox(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
          child: Column(
            children: [
              Column(
                children: [
                  12.height,
                  SizedBox(
                    height: ResSize.h * 44,
                    child: Row(
                      children: [
                        ...List.generate(2, (index) {
                          return Padding(
                            padding: EdgeInsets.only(
                              left: index == 0 ? 0 : ResSize.w * 16,
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  selectedTab = index;
                                });
                              },
                              child: Container(
                                height: ResSize.h * 44,
                                padding: EdgeInsets.symmetric(
                                  horizontal: ResSize.w * 16,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: selectedTab == index
                                      ? AppColor.primary
                                      : Color(0xffF8F5F5),
                                  border: Border.all(
                                    color: Color(0xffD6D6D6),
                                    width: selectedTab == index ? 0 : 0.4,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(
                                        right: ResSize.w * 10,
                                      ),
                                      child: Image.asset(
                                        index == 0
                                            ? AppAssets.bookmark
                                            : AppAssets.promotionIcon,
                                        height: ResSize.h * 20,
                                        color: selectedTab == index
                                            ? AppColor.whiteText
                                            : AppColor.title,
                                      ),
                                    ),
                                    TextWidget(
                                      text: index == 0 ? "Saved" : "Promotions",
                                      color: selectedTab == index
                                          ? AppColor.whiteText
                                          : AppColor.title,
                                      fontSize: 12,
                                      fontWeight: fwNormal,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  18.height,
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(
                        color: AppColor.border,
                        thickness: 0.4,
                        height: 0,
                      ),
                      6.height,
                      promoCard(
                        AppAssets.promoCard2Bg,
                        AppAssets.promoCard2Img,
                      ),
                      12.height,
                      promoCard(AppAssets.promoCardBg, AppAssets.promoCardImg),
                      16.height,
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResSize.w * 14,
                          vertical: ResSize.h * 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColor.border,
                            width: 0.4,
                          ),
                        ),
                        child: Column(
                          children: [
                            card("Thursday, Jul 17"),
                            16.height,
                            Divider(
                              color: AppColor.border,
                              thickness: 0.3,
                              height: 0,
                            ),
                            16.height,
                            card("Friday, Jul 18"),
                          ],
                        ),
                      ),
                      20.height,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget promoCard(String bg, img) {
    return SizedBox(
      height: ResSize.h * 130,
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: ResSize.h * 130,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Image.asset(
                      AppAssets.percentage,
                      height: ResSize.h * 65,
                    ),
                  ),
                  SizedBox(
                    height: ResSize.h * 130,
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.only(right: ResSize.w * 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: ResSize.w * 8,
                                  vertical: ResSize.h * 5,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xff18C07A),
                                      Color(0xff083321),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: TextWidget(
                                    text: "Discount Coupon",
                                    color: AppColor.whiteText,
                                    fontSize: 6,
                                    fontWeight: fwNormal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          5.height,
                          TextWidget(
                            text: "Sed at risus magna.\nPhasellus 20%",
                            color: AppColor.title,
                            fontSize: 14,
                            fontWeight: fwSemiBold,
                          ),
                          5.height,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextWidget(
                                      text: "Start Date",
                                      color: AppColor.subtitle,
                                      fontSize: 7,
                                      fontWeight: fwSemiBold,
                                    ),
                                    TextWidget(
                                      text: "10.08.2023",
                                      color: AppColor.title,
                                      fontSize: 9,
                                      fontWeight: fwBold,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextWidget(
                                      text: "End Date",
                                      color: AppColor.subtitle,
                                      fontSize: 7,
                                      fontWeight: fwSemiBold,
                                    ),
                                    TextWidget(
                                      text: "10.08.2023",
                                      color: AppColor.title,
                                      fontSize: 9,
                                      fontWeight: fwBold,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextWidget(
                                      text: "Deal Category",
                                      color: AppColor.subtitle,
                                      fontSize: 7,
                                      fontWeight: fwSemiBold,
                                    ),
                                    TextWidget(
                                      text: "Rides",
                                      color: AppColor.title,
                                      fontSize: 9,
                                      fontWeight: fwBold,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          5.height,
                          Row(
                            children: [
                              TextWidget(
                                text: "You Can use this coupon ",
                                color: AppColor.subtitle,
                                fontSize: 8,
                                fontWeight: fwBold,
                              ),
                              TextWidget(
                                text: "5 Time",
                                color: AppColor.title,
                                fontSize: 8,
                                fontWeight: fwBold,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: ResSize.h * 130,
            width: ResSize.w * 157,
            decoration: BoxDecoration(
              image: DecorationImage(image: AssetImage(bg), fit: BoxFit.cover),
            ),
            child: Center(
              child: Column(
                children: [
                  16.height,
                  Expanded(child: Image.asset(img)),
                  8.height,
                  TextWidget(
                    text: "Coupon Code",
                    color: AppColor.whiteText,
                    fontSize: 6,
                    fontWeight: fwNormal,
                  ),
                  TextWidget(
                    text: "C2C5902X37T8",
                    color: AppColor.whiteText,
                    fontSize: 8.5,
                    fontWeight: fwBold,
                  ),
                  TextWidget(
                    text: "Click to Copy Code Coupon",
                    color: AppColor.whiteText,
                    fontSize: 4,
                    fontWeight: fwNormal,
                  ),
                  12.height,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget card(String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(
          text: date,
          color: AppColor.title,
          fontSize: 20,
          fontWeight: fwSemiBold,
        ),
        14.height,
        Row(
          children: [
            Container(
              height: ResSize.h * 68,
              width: ResSize.w * 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: AssetImage(AppAssets.promoMapimg),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            12.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: "\$106 extra by completing 1 trip",
                    color: AppColor.title,
                    fontSize: 14,
                    fontWeight: fwSemiBold,
                  ),
                  2.height,
                  TextWidget(
                    text: "7:00 PM, 6:00 PM",
                    color: AppColor.subtitle,
                    fontSize: 12,
                    fontWeight: fwNormal,
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResSize.w * 8,
                vertical: ResSize.h * 5,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Color(0xffF3F3F3),
              ),
              child: Center(
                child: TextWidget(
                  text: "Rides only",
                  color: AppColor.subtitle,
                  fontSize: 12,
                  fontWeight: fwMedium,
                ),
              ),
            ),
          ],
        ),
        14.height,
        TextWidget(
          text:
              "Lorem ipsum dolor sit amet consectetur. Bibendum orci tellus vivamus massa pretium sagittis eget nam.",
          color: AppColor.subtitle,
          fontSize: 12,
          fontWeight: fwMedium,
        ),
        14.height,
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResSize.w * 22,
                vertical: ResSize.h * 9,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColor.red, width: 1),
              ),
              child: Center(
                child: TextWidget(
                  text: "Cancel",
                  color: AppColor.red,
                  fontSize: 12,
                  fontWeight: fwNormal,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
