import 'package:flutter/material.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class DrivingLogs extends StatelessWidget {
  const DrivingLogs({super.key});

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
          text: "Driving Logs",
          color: AppColor.title,
          fontSize: 16,
          fontWeight: fwBold,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              12.height,
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: screenHorizPadding,
                  vertical: ResSize.h * 22,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  // ignore: deprecated_member_use
                  color: Color(0xff215277).withOpacity(0.10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: "Current driving session",
                      color: AppColor.subtitle,
                      fontSize: 16,
                      fontWeight: fwSemiBold,
                    ),
                    2.height,
                    TextWidget(
                      text: "6 hr 26min",
                      color: AppColor.title,
                      fontSize: 36,
                      fontWeight: fwSemiBold,
                    ),
                    8.height,
                    SizedBox(
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            height: ResSize.h * 9,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD9D9D9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: 0.75,
                            child: Container(
                              height: ResSize.h * 9,
                              decoration: BoxDecoration(
                                color: AppColor.primary,
                                borderRadius: BorderRadius.circular(21),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    12.height,
                    TextWidget(
                      text: "75% daily limit reached",
                      color: AppColor.title,
                      fontSize: 16,
                      fontWeight: fwNormal,
                    ),
                  ],
                ),
              ),
              32.height,
              ...List.generate(2, (index) {
                return Column(
                  children: [
                    index == 0
                        ? SizedBox()
                        : Column(
                            children: [
                              16.height,
                              Divider(
                                color: AppColor.border,
                                thickness: 0.3,
                                height: 0,
                              ),
                              16.height,
                            ],
                          ),
                    Row(
                      children: [
                        Expanded(
                          child: TextWidget(
                            text: "Driving Regulations overview",
                            color: AppColor.title,
                            fontSize: 20,
                            fontWeight: fwSemiBold,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: ResSize.h * 14,
                          color: AppColor.title,
                        ),
                      ],
                    ),
                    8.height,
                    TextWidget(
                      text:
                          "Lorem ipsum dolor sit amet consectetur. Viverra nulla pulvinar risus turpis molestie metus congue tristique aliquam. Lacinia dolor nec penatibus consectetu",
                      color: AppColor.title,
                      fontSize: 14,
                      fontWeight: fwNormal,
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
