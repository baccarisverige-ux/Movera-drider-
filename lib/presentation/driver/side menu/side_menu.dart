import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/presentation/driver/my%20wallet/wallet.dart';
import 'package:movera/presentation/driver/preferences/preferences.dart';
import 'package:movera/presentation/driver/profile/profile.dart';
import 'package:movera/presentation/driver/ride%20history/ride_history.dart';
import 'package:movera/presentation/driver/scheduled%20rides/scheduled_rides.dart';
import 'package:movera/presentation/driver/settings/settings.dart';
import 'package:movera/presentation/driver/support/support_inbox.dart';

class DriverSideMenu extends StatelessWidget {
  const DriverSideMenu({super.key});

  static const Color _ink = Color(0xFF252E3A);
  static const Color _muted = Color(0xFF7D898F);
  static const Color _green = Color(0xFF19865C);
  static const Color _canvas = Color(0xFFF3F5F6);
  static const Color _line = Color(0xFFE3E8E6);

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Drawer(
      width: width * 0.88,
      elevation: 0,
      backgroundColor: _canvas,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            _buildPerformanceStrip(),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                physics: const BouncingScrollPhysics(),
                children: [
                  _sectionLabel('DRIVER'),
                  _menuCard(
                    children: [
                      _MenuAction(
                        icon: Icons.account_circle_outlined,
                        title: 'Profile',
                        subtitle: 'Account, vehicle and documents',
                        onTap: () => _open(context, const DriverProfile()),
                      ),
                      _MenuAction(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Wallet',
                        subtitle: 'Earnings and weekly payouts',
                        onTap: () => _open(context, const WalletScreen()),
                      ),
                      _MenuAction(
                        icon: Icons.history_rounded,
                        title: 'Ride history',
                        subtitle: 'Completed and previous rides',
                        onTap: () => _open(context, const DriverRideHistory()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _sectionLabel('WORK'),
                  _menuCard(
                    children: [
                      _MenuAction(
                        icon: Icons.calendar_month_outlined,
                        title: 'Scheduled rides',
                        subtitle: 'Reservations and accepted trips',
                        onTap: () =>
                            _open(context, const ScheduledRidesScreen()),
                      ),
                      _MenuAction(
                        icon: Icons.tune_rounded,
                        title: 'Ride preferences',
                        subtitle: 'Choose categories you want to receive',
                        onTap: () => _open(context, const Preferences()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _sectionLabel('SUPPORT & APP'),
                  _menuCard(
                    children: [
                      _MenuAction(
                        icon: Icons.support_agent_rounded,
                        title: 'Support',
                        subtitle: 'Messages and support tickets',
                        badge: '2',
                        onTap: () =>
                            _open(context, const SupportInboxScreen()),
                      ),
                      _MenuAction(
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        subtitle: 'App and driver settings',
                        onTap: () => _open(context, const Settings()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildMoveraFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 16, 0),
      child: Row(
        children: [
          InkWell(
            key: const ValueKey<String>('menu-profile-avatar'),
            onTap: () => _open(context, const DriverProfile()),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              height: 58,
              width: 58,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDCE4E0)),
                boxShadow: [
                  BoxShadow(
                    color: _ink.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const CircleAvatar(
                backgroundImage: AssetImage(AppAssets.profileImg),
                backgroundColor: Color(0xFFE9EEEC),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => _open(context, const DriverProfile()),
              borderRadius: BorderRadius.circular(14),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Movera Driver',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.35,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        _OnlineDot(),
                        SizedBox(width: 6),
                        Text(
                          'Driver profile',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close menu',
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _ink,
            ),
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceStrip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _line),
        ),
        child: const Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.star_rounded,
                value: '4.88',
                label: 'Rating',
                accent: Color(0xFFD99B24),
              ),
            ),
            SizedBox(
              height: 48,
              child: VerticalDivider(width: 1, color: _line),
            ),
            Expanded(
              child: _MetricTile(
                icon: Icons.check_circle_outline_rounded,
                value: 'Active',
                label: 'Account',
                accent: _green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 7),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF9AA4A9),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.15,
        ),
      ),
    );
  }

  Widget _menuCard({required List<_MenuAction> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            _buildMenuAction(children[index]),
            if (index != children.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 64),
                child: Divider(height: 1, color: _line),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuAction(_MenuAction action) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 12, 11, 12),
          child: Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5F2),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  action.icon,
                  color: const Color(0xFF315E4D),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      action.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (action.badge != null) ...[
                Container(
                  height: 22,
                  constraints: const BoxConstraints(minWidth: 22),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE9E9),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    action.badge!,
                    style: const TextStyle(
                      color: Color(0xFFB94C50),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFA7B0B4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoveraFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF26343A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.local_taxi_rounded,
            color: Color(0xFF75D7B0),
            size: 19,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Movera Driver',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            'READY',
            style: TextStyle(
              color: Color(0xFF75D7B0),
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuAction {
  const _MenuAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 7,
      width: 7,
      decoration: const BoxDecoration(
        color: Color(0xFF2FBE7B),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 7),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DriverSideMenu._ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: const TextStyle(
                    color: DriverSideMenu._muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
