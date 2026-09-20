import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/presentation/driver/home/components/radar_edge_dash.dart';
import 'package:movera/presentation/driver/my%20wallet/wallet.dart';
import 'package:movera/presentation/driver/support/support_inbox.dart';

/// Collapsed / expanded bottom-sheet navigation chrome for driver home.
class DriverSheetNav {
  DriverSheetNav._();

  static Widget collapsedDock({
    required BuildContext context,
    required GlobalKey<ScaffoldState> scaffoldKey,
    required bool isOnline,
    required bool hasRideOffers,
    required bool hasScheduledRideOffers,
    required AnimationController goOnlinePulseController,
    required VoidCallback onOpenScheduledRides,
  }) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        PhysicalShape(
          clipper: const RadarSheetClipper(
            notchWidth: 126,
            notchDepth: 58,
            cornerRadius: 24,
          ),
          color: const Color(0xFFFCFDFD),
          elevation: 8,
          shadowColor: const Color(0x3311181C),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF8FAFA),
                  Color(0xFFF1F4F5),
                ],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                10,
                15,
                10,
                safeBottom > 0 ? safeBottom + 4 : 9,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _dockAction(
                          asset: AppAssets.navLayoutGrid,
                          tooltip: 'Menu',
                          onTap: () => scaffoldKey.currentState?.openDrawer(),
                        ),
                        _dockAction(
                          asset: AppAssets.navCreditCard,
                          tooltip: 'Wallet',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WalletScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 126),
                  Expanded(
                    child: Row(
                      children: [
                        _dockAction(
                          asset: AppAssets.navMessagesSquare,
                          tooltip: 'Inbox',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SupportInboxScreen(),
                              ),
                            );
                          },
                        ),
                        AnimatedBuilder(
                          animation: goOnlinePulseController,
                          builder: (context, child) {
                            return _dockAction(
                              asset: AppAssets.navCalendarDays,
                              tooltip: 'Scheduled',
                              onTap: onOpenScheduledRides,
                              hasAlert: hasScheduledRideOffers,
                              pulse: goOnlinePulseController.value,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isOnline)
          Positioned.fill(
            child: IgnorePointer(
              child: RadarEdgeDash(
                notchWidth: 126,
                notchDepth: 58,
                cornerRadius: 24,
                color: hasRideOffers
                    ? const Color(0xFFFFA94D)
                    : const Color(0xFF2FBE7B),
              ),
            ),
          ),
      ],
    );
  }

  static Widget sheetQuickActionsBar({
    required BuildContext context,
    required GlobalKey<ScaffoldState> scaffoldKey,
    required bool hasScheduledRideOffers,
    required AnimationController goOnlinePulseController,
    required VoidCallback onOpenScheduledRides,
  }) {
    return Container(
      height: MediaQuery.paddingOf(context).bottom + 66,
      padding: EdgeInsets.fromLTRB(
        18,
        4,
        18,
        MediaQuery.paddingOf(context).bottom + 5,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFCFCFD),
      ),
      child: Row(
        children: [
          _sheetQuickAction(
            asset: AppAssets.navLayoutGrid,
            tooltip: 'Menu',
            onTap: () => scaffoldKey.currentState?.openDrawer(),
          ),
          _sheetQuickAction(
            asset: AppAssets.navCreditCard,
            tooltip: 'Wallet',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WalletScreen()),
              );
            },
          ),
          _sheetQuickAction(
            asset: AppAssets.navMessagesSquare,
            tooltip: 'Inbox',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportInboxScreen()),
              );
            },
          ),
          AnimatedBuilder(
            animation: goOnlinePulseController,
            builder: (context, child) {
              return _sheetQuickAction(
                asset: AppAssets.navCalendarDays,
                tooltip: 'Scheduled',
                onTap: onOpenScheduledRides,
                hasAlert: hasScheduledRideOffers,
                pulse: goOnlinePulseController.value,
              );
            },
          ),
        ],
      ),
    );
  }

  static Widget onlineEdgeDashOverlay({
    required bool isOnline,
    required bool hasRideOffers,
  }) {
    if (!isOnline) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: RadarEdgeDash(
          notchWidth: 126,
          notchDepth: 58,
          cornerRadius: 24,
          color: hasRideOffers
              ? const Color(0xFFFFA94D)
              : const Color(0xFF2FBE7B),
        ),
      ),
    );
  }

  static Widget _dockAction({
    required String asset,
    required String tooltip,
    required VoidCallback onTap,
    bool hasAlert = false,
    double pulse = 0,
  }) {
    final iconColor =
        hasAlert ? const Color(0xFF19865C) : const Color(0xFF303A3F);
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            splashColor: const Color(0xFF19865C).withOpacity(0.08),
            highlightColor: const Color(0xFF19865C).withOpacity(0.04),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: hasAlert
                      ? const Color(0xFFF0F8F4)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SvgPicture.asset(
                      asset,
                      width: 22,
                      height: 22,
                      colorFilter: ColorFilter.mode(
                        iconColor,
                        BlendMode.srcIn,
                      ),
                    ),
                    if (hasAlert)
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2FBE7B),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2FBE7B)
                                    .withOpacity(0.28 + pulse * 0.35),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _sheetQuickAction({
    required String asset,
    required String tooltip,
    required VoidCallback onTap,
    bool hasAlert = false,
    double pulse = 0,
  }) {
    final alertStrength = hasAlert ? (0.55 + (pulse * 0.45)) : 0.0;
    final iconColor =
        hasAlert ? const Color(0xFF16895B) : const Color(0xFF354047);

    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: Center(
          child: Material(
            color: hasAlert
                ? const Color(0xFFE9F7F1)
                : const Color(0xFFF1F3F4),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              splashColor: const Color(0xFF2FBE7B).withOpacity(0.12),
              child: SizedBox(
                height: 43,
                width: 43,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SvgPicture.asset(
                      asset,
                      width: 22,
                      height: 22,
                      colorFilter: ColorFilter.mode(
                        iconColor,
                        BlendMode.srcIn,
                      ),
                    ),
                    if (hasAlert)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Opacity(
                          opacity: alertStrength,
                          child: Container(
                            height: 7,
                            width: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2FBE7B),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Public copy of the radar sheet clipper so nav chrome can share the path.
class RadarSheetClipper extends CustomClipper<Path> {
  final double notchWidth;
  final double notchDepth;
  final double cornerRadius;

  const RadarSheetClipper({
    required this.notchWidth,
    required this.notchDepth,
    required this.cornerRadius,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final notchLeft = centerX - (notchWidth / 2);
    final notchRight = centerX + (notchWidth / 2);
    final radius = cornerRadius.clamp(0.0, size.width / 2).toDouble();

    path.moveTo(radius, 0);
    path.lineTo(notchLeft, 0);
    path.cubicTo(
      notchLeft + 9,
      0,
      centerX - 54,
      notchDepth,
      centerX,
      notchDepth,
    );
    path.cubicTo(
      centerX + 54,
      notchDepth,
      notchRight - 9,
      0,
      notchRight,
      0,
    );
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant RadarSheetClipper oldClipper) {
    return oldClipper.notchWidth != notchWidth ||
        oldClipper.notchDepth != notchDepth ||
        oldClipper.cornerRadius != cornerRadius;
  }
}
