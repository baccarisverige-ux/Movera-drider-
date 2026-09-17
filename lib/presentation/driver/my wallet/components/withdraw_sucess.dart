import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_btn.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class WithdrawAmountSuccessfully extends StatelessWidget {
  const WithdrawAmountSuccessfully({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24 * ResSize.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: Image.asset(
                        AppAssets.sucess,
                        height: ResSize.h * 75,
                      ),
                    ),

                    20.height,
                    TextWidget(
                      text: 'Withdraw request sent!',
                      fontSize: 24,
                      color: AppColor.title,
                      fontWeight: fwBold,
                      textAlign: TextAlign.center,
                    ),
                    8.height,
                    TextWidget(
                      text:
                          "Withdrawal request has been sent and is under process. It will take 3-5 business days to clear your amount.",
                      fontSize: 16,
                      color: AppColor.title,
                      fontWeight: fwNormal,
                      textAlign: TextAlign.center,
                    ),
                    45.height,
                    _infoRow('Total amount', '\$50'),
                    16.height,
                    _infoRow('Request ID', '1310481814'),
                    16.height,
                    _infoRow('Date & Time', 'April 12, 10:30 PM'),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: CustomButton(
                borderRadius: 8,
                centerContent: "Got it",
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            20.height,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: TextWidget(
            text: label,
            fontSize: 16,
            color: const Color(0xFF9A9A9A),
            fontWeight: fwMedium,
          ),
        ),
        TextWidget(
          text: value,
          fontSize: 16,
          color: AppColor.title,
          fontWeight: fwSemiBold,
        ),
      ],
    );
  }
}
