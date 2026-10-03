import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/presentation/driver/driving%20logs/driving_logs.dart';
import 'package:movera/presentation/driver/my%20wallet/wallet.dart';
import 'package:movera/presentation/driver/preferences/preferences.dart';
import 'package:movera/presentation/driver/profile/profile.dart';
import 'package:movera/presentation/driver/promotions/promotions.dart';
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
  static const Color _canvas = Colors.white;
  static const Color _gap = Color(0xFFF1F2F2);
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
                  const SizedBox(height: 10),
                  _buildPerformanceStrip(),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                key: const PageStorageKey<String>('driver-menu-list'),
                padding: const EdgeInsets.only(bottom: 14),
                physics: const BouncingScrollPhysics(),
                children: [
                  _groupGap(),
                  _sectionLabel('DRIVER'),
                  _menuCard(
                    children: [
                      _MenuAction(
                        asset: AppAssets.menuProfile,
                        title: 'Profile',
                        subtitle: 'Account, vehicle and documents',
                        onTap: () => _open(context, const DriverProfile()),
                      ),
                      _MenuAction(
                        asset: AppAssets.menuWallet,
                        title: 'Wallet',
                        subtitle: 'Earnings and weekly payouts',
                        onTap: () => _open(context, const WalletScreen()),
                      ),
                      _MenuAction(
                        asset: AppAssets.menuHistory,
                        title: 'Ride history',
                        subtitle: 'Completed and previous rides',
                        onTap: () => _open(context, const DriverRideHistory()),
                      ),
                    ],
                  ),
                  _groupGap(),
                  _sectionLabel('WORK'),
                  _menuCard(
                    children: [
                      _MenuAction(
                        asset: AppAssets.menuScheduledRide,
                        highlight: true,
                        title: 'Scheduled rides',
                        subtitle: 'Reservations and accepted trips',
                        onTap: () =>
                            _open(context, const ScheduledRidesScreen()),
                      ),
                      _MenuAction(
                        asset: AppAssets.navMenuBranch,
                        title: 'Ride preferences',
                        subtitle: 'Choose categories you want to receive',
                        onTap: () => _open(context, const Preferences()),
                      ),
                      _MenuAction(
                        asset: AppAssets.menuTag,
                        badge: 'NEW',
                        title: 'Promotions',
                        subtitle: 'Bonuses and campaign offers',
                        onTap: () => _open(context, const Promotions()),
                      ),
                      _MenuAction(
                        asset: AppAssets.menuTimer,
                        title: 'Driving logs',
                        subtitle: 'Hours online and rest rules',
                        onTap: () => _open(context, const DrivingLogs()),
                      ),
                    ],
                  ),
                  _groupGap(),
                  _sectionLabel('SUPPORT & APP'),
                  _menuCard(
                    children: [
                      _MenuAction(
                        asset: AppAssets.menuSupport,
                        title: 'Support',
                        subtitle: 'Messages and support tickets',
                        onTap: () =>
                            _open(context, const SupportInboxScreen()),
                      ),
                      _MenuAction(
                        asset: AppAssets.menuSettings,
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
                        color: _ink.withValues(alpha: 0.08),
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
                  color: statusColor.withValues(alpha: 0.10),
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
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _line),
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
      padding: const EdgeInsets.fromLTRB(24, 8, 8, 4),
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

  Widget _groupGap() {
    return Container(
      height: 8,
      margin: const EdgeInsets.only(top: 8, bottom: 6),
      color: _gap,
    );
  }

  Widget _menuCard({required List<_MenuAction> children}) {
    return Column(
      children: [for (final action in children) _buildMenuAction(action)],
    );
  }

  Widget _buildMenuAction(_MenuAction action) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 11, 18, 11),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                height: 30,
                child: action.highlight
                    // The one coloured icon: the owner's watercolour
                    // calendar, drawn a little larger than the line icons.
                    ? OverflowBox(
                        maxWidth: 40,
                        maxHeight: 40,
                        child: Image.asset(action.asset, width: 40, height: 40),
                      )
                    : Center(
                        child: SvgPicture.asset(
                          action.asset,
                          width: 25,
                          height: 25,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF3B4246),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (action.badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0474C),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    action.badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.9,
                    ),
                  ),
                ),
              ],
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
        color: _gap,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_taxi_rounded,
              color: _green,
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'Movera Driver',
              style: TextStyle(
                color: _ink,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            ready ? 'READY' : 'PENDING',
            style: TextStyle(
              color: ready ? _green : const Color(0xFFB9801F),
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
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
    this.badge,
  });

  final String asset;

  /// The one coloured icon in the menu: [asset] is a PNG drawn as is.
  final bool highlight;

  /// Small red pill after the text, e.g. "NEW".
  final String? badge;
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
