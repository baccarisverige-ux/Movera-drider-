import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/my%20bank/add%20new%20account/add_new_account.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class MyBank extends StatelessWidget {
  const MyBank({super.key});
  final List<_BankItem> _banks = const [
    _BankItem(
      initials: 'JV',
      name: 'Edith Dare',
      account: 'ASK13141918591494015810',
    ),
    _BankItem(
      initials: 'SA',
      name: 'Jan Douglas',
      account: 'ASK13141918591494015810',
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFAFAFA),
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
          text: 'My bank',
          color: AppColor.title,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, TopToBottomTransition(AddNewAccount()));
            },
            icon: Icon(Icons.add_rounded, size: ResSize.h * 25),
          ),
        ],
      ),
      body: Column(
        children: [
          12.height,
          ...List.generate(_banks.length, (index) {
            final _BankItem bank = _banks[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 8 * ResSize.h),
              child: InkWell(
                onTap: () {},
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenHorizPadding,
                    vertical: ResSize.h * 10,
                  ),
                  decoration: BoxDecoration(color: AppColor.white),
                  child: Row(
                    children: [
                      Container(
                        height: ResSize.h * 52,
                        width: ResSize.w * 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2F2F2F),
                          borderRadius: BorderRadius.circular(8 * ResSize.w),
                        ),
                        child: Center(
                          child: TextWidget(
                            text: bank.initials,
                            fontSize: 20,
                            color: AppColor.white,
                            fontWeight: fwSemiBold,
                          ),
                        ),
                      ),
                      12.width,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWidget(
                              text: bank.name,
                              fontSize: 16,
                              color: AppColor.title,
                              fontWeight: fwSemiBold,
                            ),
                            TextWidget(
                              text: bank.account,
                              fontSize: 14,
                              color: AppColor.subtitle,
                              fontWeight: fwSemiBold,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Image.asset(AppAssets.delete, height: ResSize.h * 20),
                          14.width,
                          Image.asset(
                            AppAssets.editNote,
                            height: ResSize.h * 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BankItem {
  final String initials;
  final String name;
  final String account;
  const _BankItem({
    required this.initials,
    required this.name,
    required this.account,
  });
}
