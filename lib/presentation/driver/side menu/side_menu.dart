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
  const DriverSideMenu({
    super.key,
    this.isOnline = false,
    this.accountActive = true,
  });

  final bool isOnline;
  final bool accountActive;

  static const Color _ink = Color(0xFF252E3A);
  static const Color _muted = Color(0xFF7D898F);
  static const Color _green = Color(0xFF19865C);
  static const Color _canvas = Color(0xFFF3F5F6);
  static const Color _line = Color(0xFFE3E8E6);

  // Deliberately keep the Drawer open under the destination route.
  // When the driver presses Back, Flutter reveals the menu again instead of
  // dropping them directly onto the map.
  //
  // Uses a non-[PageRoute] so [HeroController] cannot park the page offstage
  // (which would make Back / [Navigator.pop] a no-op in widget tests).
  void _open(BuildContext context, Widget page) {
    Navigator.of(context, rootNavigator: true).push(
      _DriverMenuRoute(page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Drawer(
      key: const ValueKey<String>('driver-side-menu'),
      width: width * 0.90,
      elevation: 0,
      backgroundColor: _canvas,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      child: ColoredBox(
        color: _canvas,
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 12),
                  _buildPerformanceStrip(),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                key: const PageStorageKey<String>('driver-menu-list'),
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
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
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(14, 0, 14, bottomInset + 12),
              child: _buildMoveraFooter(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final statusColor = isOnline
        ? const Color(0xFF2FBE7B)
        : const Color(0xFF9AA4A9);
    final statusText = isOnline ? 'ONLINE' : 'OFFLINE';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 310;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 14 : 18,
            16,
            compact ? 10 : 14,
            0,
          ),
          child: Row(
            children: [
              InkWell(
                key: const ValueKey<String>('menu-profile-avatar'),
                onTap: () => _open(context, const DriverProfile()),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  height: compact ? 50 : 58,
                  width: compact ? 50 : 58,
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
              SizedBox(width: compact ? 8 : 12),
              Expanded(
                child: InkWell(
                  key: const ValueKey<String>('menu-profile-header'),
                  onTap: () => _open(context, const DriverProfile()),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Movera Driver',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _ink,
                            fontSize: compact ? 16 : 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.35,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              height: 7,
                              width: 7,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                isOnline
                                    ? 'Available for trips'
                                    : 'Driver profile',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: compact ? 6 : 8),
              Container(
                key: const ValueKey<String>('menu-live-status'),
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 7 : 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  compact
                      ? (isOnline ? 'ON' : 'OFF')
                      : statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: compact ? 0.35 : 0.8,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
          boxShadow: [
            BoxShadow(
              color: _ink.withOpacity(0.035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Expanded(
              child: _MetricTile(
                icon: Icons.star_rounded,
                value: '4.88',
                label: 'Rating',
                accent: Color(0xFFD99B24),
              ),
            ),
            const SizedBox(
              height: 48,
              child: VerticalDivider(width: 1, color: _line),
            ),
            Expanded(
              child: _MetricTile(
                icon: accountActive
                    ? Icons.verified_outlined
                    : Icons.pending_outlined,
                value: accountActive ? 'Active' : 'Pending',
                label: 'Account',
                accent: accountActive
                    ? _green
                    : const Color(0xFFB9801F),
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
        borderRadius: BorderRadius.circular(22),
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
          padding: const EdgeInsets.fromLTRB(13, 11, 11, 11),
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
    final ready = accountActive;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      decoration: BoxDecoration(
        color: const Color(0xFF26343A),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_taxi_rounded,
              color: Color(0xFF75D7B0),
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          const Expanded(
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
            ready ? 'READY' : 'PENDING',
            style: TextStyle(
              color: ready
                  ? const Color(0xFF75D7B0)
                  : const Color(0xFFFFD28A),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
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

class _DriverMenuRoute extends ModalRoute<void> {
  _DriverMenuRoute(this.page);

  final Widget page;

  @override
  bool get opaque => true;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 280);

  @override
  Duration get reverseTransitionDuration =>
      const Duration(milliseconds: 220);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return page;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    );
  }
}
