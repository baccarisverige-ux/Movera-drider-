import 'package:flutter/material.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/my%20wallet/components/choose_bank.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFAFAFA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          16.height,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
            child: TextWidget(
              text: 'Recent Transactions',
              fontSize: 16,
              color: AppColor.title,
              fontWeight: fwSemiBold,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  ListView.builder(
                    itemCount: 4,
                    shrinkWrap: true,
                    clipBehavior: Clip.none,
                    padding: EdgeInsets.all(0),
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          top: index == 0 ? 0 : ResSize.h * 8,
                        ),
                        child: _transactionTile(
                          title: 'Ride | ID #MD13014',
                          subtitle: '20 Mar, 10:30 AM',
                          amountText: '\$12.0',
                          amountColor: index == 3
                              ? AppColor.red
                              : AppColor.title,
                          tipText: index == 0 ? '+ 2.00 tip' : null,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final Color headerColor = const Color(0xFF1E5B74);
    return Container(
      color: headerColor,
      width: double.infinity,
      padding: EdgeInsets.only(
        top: ResSize.h * 50,
        left: 16 * ResSize.w,
        right: 16 * ResSize.w,
        bottom: 24 * ResSize.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18 * ResSize.h,
                ),
              ),
              Expanded(
                child: Center(
                  child: TextWidget(
                    text: 'Wallet',
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: fwSemiBold,
                  ),
                ),
              ),
              SizedBox(width: 22 * ResSize.w),
            ],
          ),
          22.height,
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: 'Available balance',
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: fwSemiBold,
                    ),
                    TextWidget(
                      text: '\$22.10',
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: fwExtraBold,
                    ),
                  ],
                ),
              ),
              12.width,
              InkWell(
                onTap: () => showWithdrawAmountBottomSheet(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 17 * ResSize.w,
                    vertical: 10 * ResSize.h,
                  ),
                  child: TextWidget(
                    text: 'Withdraw',
                    fontSize: 16,
                    color: AppColor.title,
                    fontWeight: fwSemiBold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _transactionTile({
    required String title,
    required String subtitle,
    required String amountText,
    required Color amountColor,
    String? tipText,
  }) {
    return Container(
      color: AppColor.white,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16 * ResSize.w,
          vertical: 14 * ResSize.h,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: title,
                    fontSize: 16,
                    color: AppColor.title,
                    fontWeight: fwSemiBold,
                  ),
                  6.height,
                  TextWidget(
                    text: subtitle,
                    fontSize: 14,
                    color: AppColor.subtitle,
                    fontWeight: fwBold,
                  ),
                ],
              ),
            ),
            12.width,
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextWidget(
                  text: amountText,
                  fontSize: 24,
                  color: amountColor,
                  fontWeight: fwSemiBold,
                ),
                if (tipText != null) ...[
                  4.height,
                  TextWidget(
                    text: tipText,
                    fontSize: 12,
                    color: AppColor.subtitle,
                    fontWeight: fwMedium,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
