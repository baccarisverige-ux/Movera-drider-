import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/my%20bank/add%20new%20account/add_new_account.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class MyBank extends StatefulWidget {
  const MyBank({super.key});

  @override
  State<MyBank> createState() => _MyBankState();
}

class _MyBankState extends State<MyBank> {
  final List<_BankItem> _banks = [
    const _BankItem(
      initials: 'EJ',
      name: 'Erik Johansson',
      account: 'SE45 5000 0000 0583 9825 7466',
      bank: 'Handelsbanken',
    ),
    const _BankItem(
      initials: 'EJ',
      name: 'Erik Johansson',
      account: 'SE91 1200 0000 2418 3000 8415',
      bank: 'Nordea',
    ),
  ];
  int _payoutIndex = 0;

  Future<void> _openAccount(_BankItem bank, int index) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bank.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF252E3A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${bank.bank}\n${bank.account}',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Color(0xFF7D898F),
                  ),
                ),
                const SizedBox(height: 16),
                if (_payoutIndex != index)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle_outline),
                    title: const Text('Use for weekly payouts'),
                    onTap: () {
                      setState(() => _payoutIndex = index);
                      Navigator.pop(sheetContext);
                    },
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit account'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      TopToBottomTransition(AddNewAccount()),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline, color: Color(0xFFE31E37)),
                  title: const Text(
                    'Remove account',
                    style: TextStyle(color: Color(0xFFE31E37)),
                  ),
                  onTap: () {
                    setState(() {
                      _banks.removeAt(index);
                      if (_payoutIndex >= _banks.length) {
                        _payoutIndex = _banks.isEmpty ? 0 : _banks.length - 1;
                      }
                    });
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFAFAFA),
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
      body: ListView(
        children: [
          12.height,
          if (_banks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No payout accounts yet. Add a Swedish bank account for weekly payouts.',
                style: TextStyle(color: Color(0xFF7D898F)),
              ),
            ),
          ...List.generate(_banks.length, (index) {
            final _BankItem bank = _banks[index];
            final selected = index == _payoutIndex;
            return Padding(
              padding: EdgeInsets.only(bottom: 8 * ResSize.h),
              child: InkWell(
                onTap: () => _openAccount(bank, index),
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
                            if (selected)
                              const Text(
                                'Weekly payouts',
                                style: TextStyle(
                                  color: Color(0xFF19865C),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
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
  final String bank;
  const _BankItem({
    required this.initials,
    required this.name,
    required this.account,
    required this.bank,
  });
}
