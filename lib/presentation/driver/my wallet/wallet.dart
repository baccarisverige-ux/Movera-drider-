import 'package:flutter/material.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/presentation/driver/my%20wallet/components/choose_bank.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  static const Color _page = Color(0xFF171B1E);
  static const Color _surface = Color(0xFF22282C);
  static const Color _surfaceSoft = Color(0xFF1D2226);
  static const Color _line = Color(0xFF343C41);
  static const Color _text = Color(0xFFF3F5F6);
  static const Color _muted = Color(0xFFA7B0B5);
  static const Color _green = Color(0xFF58E5A6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _balanceCard(context),
                    const SizedBox(height: 26),
                    _sectionHeader(
                      title: 'Payout activity',
                      action: 'See all',
                    ),
                    const SizedBox(height: 12),
                    _payoutCard(),
                    const SizedBox(height: 24),
                    _settingsCard(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 18, 8),
      child: SizedBox(
        height: 54,
        child: Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  height: 44,
                  width: 44,
                  child: Icon(
                    Icons.close_rounded,
                    color: _text,
                    size: 25,
                  ),
                ),
              ),
            ),
            const Expanded(
              child: Text(
                'Wallet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _text,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.25,
                ),
              ),
            ),
            const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }

  Widget _balanceCard(BuildContext context) {
    return InkWell(
      onTap: () => showWithdrawAmountBottomSheet(context),
      borderRadius: BorderRadius.circular(26),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 19, 20, 18),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: const Color(0xFF30383D),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.20),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Available balance',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF707A80),
                  size: 23,
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              '2 994,80 kr',
              style: TextStyle(
                color: _text,
                fontSize: 36,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.1,
              ),
            ),
            const SizedBox(height: 17),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Next payout · 21 Sep',
                    style: TextStyle(
                      color: Color(0xFFC8D0D4),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.24),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Weekly',
                    style: TextStyle(
                      color: Color(0xFFAFC9DC),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required String action,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.35,
            ),
          ),
        ),
        Text(
          action,
          style: const TextStyle(
            color: Color(0xFFB8C1C5),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _payoutCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: const [
          _PayoutRow(
            amount: '3 072,88 kr',
            date: 'Initiated · 14 Sep',
          ),
          Divider(
            height: 1,
            indent: 58,
            endIndent: 16,
            color: _line,
          ),
          _PayoutRow(
            amount: '4 780,29 kr',
            date: 'Initiated · 7 Sep',
          ),
        ],
      ),
    );
  }

  Widget _settingsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          _WalletActionRow(
            icon: Icons.account_balance_outlined,
            title: 'Payout method',
            subtitle: 'Weekly to bank account ·•••• 41',
            onTap: () => showWithdrawAmountBottomSheet(context),
          ),
          const Divider(
            height: 1,
            indent: 58,
            endIndent: 16,
            color: _line,
          ),
          _WalletActionRow(
            icon: Icons.help_outline_rounded,
            title: 'Help',
            subtitle: 'Payouts, balance and payment support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Wallet help is ready for backend support later.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PayoutRow extends StatelessWidget {
  final String amount;
  final String date;

  const _PayoutRow({
    required this.amount,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF283037),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFFC9D1D5),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly payout',
                  style: TextStyle(
                    color: WalletScreen._text,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  color: WalletScreen._text,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                date,
                style: const TextStyle(
                  color: WalletScreen._muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _WalletActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Icon(
                  icon,
                  color: const Color(0xFFC8D0D4),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: WalletScreen._text,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: WalletScreen._muted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF657077),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
