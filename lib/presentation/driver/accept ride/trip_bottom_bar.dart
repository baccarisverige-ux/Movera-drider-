import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/widgets/route_mark_pins.dart';

/// Active Ride bar: the route icon on the left (Ride preferences once the
/// sheet is lifted), time and distance to the next point in the middle,
/// trip details on the right.
class TripBottomBar extends StatelessWidget {
  const TripBottomBar({
    super.key,
    required this.etaLabel,
    required this.statusLabel,
    required this.onPreferences,
    required this.onDetails,
    this.distanceLabel,
    this.stopCount = 0,
    this.onStatusTap,
    this.onArrived,
    this.arrivedEnabled = false,
    this.expanded = false,
    this.showDetailsButton = true,
    this.etaColor,
    this.statusColor,
    this.progress,
    this.nextMark,
    this.soonTitle,
    this.waitFraction,
    this.waitPaidFrom = 0.4,
    this.waitAlert = false,
  });

  /// Pickup wait as a line: share of the wait window already used, 0..1.
  /// The part before [waitPaidFrom] is free waiting (ink), the rest is paid
  /// (green, or red with [waitAlert] once a no-show is allowed).
  final double? waitFraction;
  final double waitPaidFrom;
  final bool waitAlert;

  /// Share of the way to the next point already driven, 0..1. Draws a
  /// line under the time with the car moving along it; null hides it.
  final double? progress;

  /// Mark at the end of the line and before [soonTitle].
  final RouteMarkKind? nextMark;

  /// Short headline once the next point is close, e.g. "Almost there";
  /// it replaces the time and the line.
  final String? soonTitle;

  /// Colour of the small line, e.g. green for "Pickup coming up".
  final Color? statusColor;

  /// Middle sheet hides the details button: swiping up opens details.
  final bool showDetailsButton;

  /// Colour of the big time, e.g. green once paid waiting starts.
  final Color? etaColor;

  /// Header of the open sheet: the right button closes it instead.
  final bool expanded;

  final String etaLabel;
  final String? distanceLabel;
  final String statusLabel;
  final int stopCount;
  final VoidCallback onPreferences;
  final VoidCallback onDetails;

  /// Tapping the middle; defaults to [onDetails].
  final VoidCallback? onStatusTap;

  /// "I've arrived" pill, shown in place of the details button once the
  /// driver is close enough ([arrivedEnabled]).
  final VoidCallback? onArrived;
  final bool arrivedEnabled;

  static const _ink = Color(0xFF111614);
  static const _muted = Color(0xFF5E6461);

  @override
  Widget build(BuildContext context) {
    final distance = distanceLabel;
    return SizedBox(
      height: 76,
      child: Row(
        children: [
          const SizedBox(width: 8),
          // Bar: the route icon. Once the sheet is lifted, preferences.
          if (!expanded && showDetailsButton)
            _iconButton(
              tooltip: 'Trip route',
              onTap: onDetails,
              child: const Icon(Icons.alt_route_rounded, size: 26, color: _ink),
            )
          else
            _iconButton(
              tooltip: 'Ride preferences',
              onTap: onPreferences,
              child: SvgPicture.asset(
                AppAssets.navMenuBranch,
                width: 26,
                height: 26,
                colorFilter: const ColorFilter.mode(_ink, BlendMode.srcIn),
              ),
            ),
          Expanded(
            child: Semantics(
              button: true,
              child: InkWell(
                onTap: onStatusTap ?? onDetails,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (soonTitle != null)
                        _soonHeadline(soonTitle!)
                      else
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              etaLabel,
                              style: TextStyle(
                                color: etaColor ?? _ink,
                                fontSize: _etaSize,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.6,
                              ),
                            ),
                            if (distance != null) ...[
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2FBE7B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                distance,
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: _etaSize,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.6,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (soonTitle == null && progress != null) ...[
                        const SizedBox(height: 3),
                        _track(progress!),
                      ] else if (waitFraction != null) ...[
                        const SizedBox(height: 5),
                        _waitTrack(waitFraction!),
                        const SizedBox(height: 3),
                      ],
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              statusLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: statusColor ?? _muted,
                                fontSize: 14.5,
                                fontWeight: statusColor == null
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                              ),
                            ),
                          ),
                          if (stopCount > 0) ...[
                            const Text(
                              ' · ',
                              style: TextStyle(color: _muted, fontSize: 14.5),
                            ),
                            Flexible(
                              child: Text(
                                '$stopCount stop${stopCount == 1 ? '' : 's'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (onArrived != null && arrivedEnabled)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: FilledButton(
                key: const ValueKey<String>('active-ride-arrived-button'),
                onPressed: onArrived,
                style: FilledButton.styleFrom(
                  backgroundColor: _ink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "I've arrived",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            )
          else if (!showDetailsButton)
            const SizedBox(width: 52)
          else
            _iconButton(
              tooltip: expanded ? 'Hide trip details' : 'Trip details',
              onTap: onDetails,
              child: Icon(
                expanded
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.format_list_bulleted_rounded,
                size: expanded ? 32 : 28,
                color: _ink,
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  /// Smaller time while the line sits under it.
  double get _etaSize =>
      progress != null || waitFraction != null ? 22 : 26;

  /// Wait window: free part, then paid part, with a tick where paid starts.
  Widget _waitTrack(double fraction) {
    const paid = Color(0xFF19865C);
    const alert = Color(0xFF9E2B33);
    return Padding(
      key: const ValueKey<String>('trip-wait-line'),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: 10,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final f = fraction.clamp(0.0, 1.0);
            final free = math.min(f, waitPaidFrom);
            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3E6E8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Positioned(
                  left: 0,
                  width: w * free,
                  child: Container(height: 4, color: _ink),
                ),
                if (f > waitPaidFrom)
                  Positioned(
                    left: w * waitPaidFrom,
                    width: w * (f - waitPaidFrom),
                    child: Container(height: 4, color: waitAlert ? alert : paid),
                  ),
                Positioned(
                  left: w * waitPaidFrom - 1,
                  child: Container(
                    width: 2,
                    height: 10,
                    color: const Color(0xFF9AA4A9),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _soonHeadline(String title) {
    final mark = nextMark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (mark != null) ...[
          RouteMarkIcon(mark, size: 20),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }

  /// Line to the next point: driven part in ink, the car at its tip and
  /// the next point's mark at the end.
  Widget _track(double fraction) {
    const car = 18.0;
    final mark = nextMark;
    return Padding(
      key: const ValueKey<String>('trip-progress-line'),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: car,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final travel = constraints.maxWidth - car - RouteMarkPins.markSize / 2;
            final x = travel * fraction.clamp(0.0, 1.0);
            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned(
                  left: car / 2,
                  right: RouteMarkPins.markSize / 2,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3E6E8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Positioned(
                  left: car / 2,
                  width: x,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: _ink,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (mark != null) Positioned(right: 0, child: RouteMarkIcon(mark)),
                Positioned(
                  left: x,
                  child: Container(
                    width: car,
                    height: car,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B7DD8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Color(0x33000000), blurRadius: 4),
                      ],
                    ),
                    child: const RotatedBox(
                      quarterTurns: 1,
                      child: Icon(
                        Icons.navigation_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static Widget _iconButton({
    required String tooltip,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(width: 52, height: 52, child: Center(child: child)),
        ),
      ),
    );
  }
}
