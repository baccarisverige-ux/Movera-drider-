import 'package:flutter/material.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/my%20wallet/components/withdraw_sucess.dart';
import 'package:movera/widgets/custom_btn.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

Future<T?> showWithdrawAmountBottomSheet<T>(BuildContext context) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => const WithdrawBottomSheet(),
  );
}

class WithdrawBottomSheet extends StatefulWidget {
  const WithdrawBottomSheet({super.key});

  @override
  State<WithdrawBottomSheet> createState() => _WithdrawBottomSheetState();
}

class _WithdrawBottomSheetState extends State<WithdrawBottomSheet> {
  int _selectedIndex = 0;
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
    final double radius = 12;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radius),
            topRight: Radius.circular(radius),
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                16 * ResSize.w,
                22 * ResSize.h,
                16 * ResSize.w,
                16 * ResSize.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWidget(
                              text: 'Choose Bank',
                              fontSize: 16,
                              color: AppColor.title,
                              fontWeight: fwBold,
                            ),
                            4.height,
                            TextWidget(
                              text:
                                  'Select bank where you want to receive the amount',
                              fontSize: 12,
                              color: AppColor.subtitle,
                              fontWeight: fwMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  24.height,
                  ...List.generate(_banks.length, (index) {
                    final _BankItem bank = _banks[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 14 * ResSize.h),
                      child: InkWell(
                        onTap: () => setState(() => _selectedIndex = index),
                        child: Row(
                          children: [
                            Container(
                              height: ResSize.h * 52,
                              width: ResSize.w * 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2F2F2F),
                                borderRadius: BorderRadius.circular(
                                  8 * ResSize.w,
                                ),
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
                            16.width,
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
                                    fontSize: 16,
                                    color: AppColor.subtitle,
                                    fontWeight: fwSemiBold,
                                  ),
                                ],
                              ),
                            ),
                            _selectedIndex == index
                                ? Container(
                                    height: ResSize.h * 20,
                                    width: ResSize.w * 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColor.black,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.done_rounded,
                                        color: AppColor.white,
                                        size: ResSize.h * 10,
                                      ),
                                    ),
                                  )
                                : SizedBox(),
                          ],
                        ),
                      ),
                    );
                  }),
                  29.height,
                  CustomButton(
                    centerContent: "Confirm",
                    onPressed: () => Navigator.push(
                      context,
                      BottomToTopTransition(const WithdrawAmountSuccessfully()),
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
