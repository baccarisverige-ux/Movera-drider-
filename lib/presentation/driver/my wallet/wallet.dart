import 'package:flutter/material.dart';
import 'package:movera/presentation/driver/my%20wallet/components/choose_bank.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  static const Color _page = Color(0xFFF7F9F8);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _green = Color(0xFF235F49);
  static const Color _greenMid = Color(0xFF4A876F);
  static const Color _mint = Color(0xFFEAF4EF);
  static const Color _mintStrong = Color(0xFFDCEDE5);
  static const Color _blueSoft = Color(0xFFEAF1F6);
  static const Color _text = Color(0xFF26312B);
  static const Color _muted = Color(0xFF7C8982);
  static const Color _line = Color(0xFFE4EAE7);

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
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _balanceHero(context),
                    const SizedBox(height: 14),
                    _quickActions(context),
                    const SizedBox(height: 28),
                    _sectionHeader(
                      title: 'Recent payouts',
                      action: 'See all',
                    ),
                    const SizedBox(height: 12),
                    _recentPayouts(),
                    const SizedBox(height: 22),
                    _supportCard(context),
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
              color: const Color(0xFFF0F3F1),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  height: 42,
                  width: 42,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: _text,
                    size: 18,
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
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.25,
                ),
              ),
            ),
            const SizedBox(width: 42),
          ],
        ),
      ),
    );
  }

  Widget _balanceHero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF3FAF7),
            Color(0xFFE6F3ED),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD8E9E1)),
        boxShadow: [
          BoxShadow(
            color: _green.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _white.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 7,
                      height: 7,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFF55B38A),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Available',
                      style: TextStyle(
                        color: _green,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => showWithdrawAmountBottomSheet(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _white.withOpacity(0.88),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.arrow_outward_rounded,
                    color: _green,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            '2 994,80 kr',
            style: TextStyle(
              color: _text,
              fontSize: 38,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Current wallet balance',
            style: TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(13, 11, 12, 11),
            decoration: BoxDecoration(
              color: _white.withOpacity(0.78),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0ECE6)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  color: _greenMid,
                  size: 18,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Next payout',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '21 Sep',
                  style: TextStyle(
                    color: _text,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _quickAction(
            icon: Icons.south_west_rounded,
            title: 'Withdraw',
            fill: _mint,
            iconColor: _green,
            onTap: () => showWithdrawAmountBottomSheet(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickAction(
            icon: Icons.account_balance_outlined,
            title: 'Bank',
            fill: _blueSoft,
            iconColor: const Color(0xFF496C86),
            onTap: () => showWithdrawAmountBottomSheet(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickAction(
            icon: Icons.receipt_long_outlined,
            title: 'History',
            fill: const Color(0xFFF1F2EC),
            iconColor: const Color(0xFF6B7257),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Full payout history will connect to backend later.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String title,
    required Color fill,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 82,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _line),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 18,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                title,
                style: const TextStyle(
                  color: _text,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
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
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
        ),
        Text(
          action,
          style: const TextStyle(
            color: _greenMid,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _recentPayouts() {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      child: const Column(
        children: [
          _PayoutRow(
            amount: '3 072,88 kr',
            date: '14 Sep',
          ),
          Divider(
            height: 1,
            indent: 66,
            endIndent: 16,
            color: _line,
          ),
          _PayoutRow(
            amount: '4 780,29 kr',
            date: '7 Sep',
          ),
        ],
      ),
    );
  }

  Widget _supportCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _mintStrong,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              color: _green,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wallet support',
                  style: TextStyle(
                    color: _text,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Questions about payouts or your bank account',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Wallet support will connect to support backend later.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF8A9790),
            ),
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: WalletScreen._mint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.arrow_downward_rounded,
              color: WalletScreen._green,
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Sent to bank account',
                  style: TextStyle(
                    color: WalletScreen._muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                date,
                style: const TextStyle(
                  color: WalletScreen._muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
