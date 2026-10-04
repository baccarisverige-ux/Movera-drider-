import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/widgets/route_mark_pins.dart';

/// Active Ride bar: the route icon on the left (Ride preferences once the
/// sheet is lifted); in the middle the line to the next point and one line
/// of text: time, distance, the next address and how the rider pays.
/// "I've arrived" on the right once the driver is close.
class TripBottomBar extends StatelessWidget {
  const TripBottomBar({
    super.key,
    required this.etaLabel,
    required this.statusLabel,
    required this.onPreferences,
    required this.onDetails,
    this.distanceLabel,
    this.nextAddress,
    this.paidByCash = false,
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

  /// Address of the next point: pickup, stop or drop-off.
  final String? nextAddress;

  /// Cash in the car; otherwise paid by card.
  final bool paidByCash;
  final VoidCallback onPreferences;
  final VoidCallback onDetails;

  /// Tapping the middle; defaults to [onDetails].
  final VoidCallback? onStatusTap;

  /// "I've arrived" pill, shown in place of the details button once the
  /// driver is close enough ([arrivedEnabled]).
  final VoidCallback? onArrived;
  final bool arrivedEnabled;

  static const _ink = Color(0xFF111614);

  @override
  Widget build(BuildContext context) {
    final arrived = onArrived != null && arrivedEnabled;
    final soon = soonTitle;
    final wait = waitFraction;
    return SizedBox(
      height: 76,
      child: Row(
        children: [
          const SizedBox(width: 4),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: RouteMarkPins.markSize,
                        child: wait != null
                            ? Center(child: _waitTrack(wait))
                            : _track(progress ?? 0),
                      ),
                      const SizedBox(height: 7),
                      _infoLine(
                        // Close by, the distance gives way to the address.
                        distance: arrived || soon != null
                            ? null
                            : distanceLabel,
                        lead: soon ?? etaLabel,
                        leadColor: soon != null
                            ? (statusColor ?? const Color(0xFF19865C))
                            : (etaColor ?? _ink),
                        // Waiting: the wait, not an address.
                        waiting: wait != null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (arrived)
            Padding(
              padding: const EdgeInsets.only(left: 6, right: 12),
              child: FilledButton(
                key: const ValueKey<String>('active-ride-arrived-button'),
                onPressed: onArrived,
                style: FilledButton.styleFrom(
                  backgroundColor: _ink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "I've arrived",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            )
          else if (expanded)
            _iconButton(
              tooltip: 'Hide trip details',
              onTap: onDetails,
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 32,
                color: _ink,
              ),
            )
          else
            const SizedBox(width: 14),
        ],
      ),
    );
  }

  /// "42 min • 37.3 km • ◆ Sveavägen 20 [card]" on one line; the address
  /// shortens first when space runs out.
  Widget _infoLine({
    required String? distance,
    required String lead,
    required Color leadColor,
    required bool waiting,
  }) {
    Widget dot() => Container(
      width: 4.5,
      height: 4.5,
      margin: const EdgeInsets.symmetric(horizontal: 7),
      decoration: const BoxDecoration(
        color: Color(0xFF2FBE7B),
        shape: BoxShape.circle,
      ),
    );
    const strong = TextStyle(
      color: _ink,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    );
    // The bar names the next address; the open sheet's header names the
    // step ("Heading to pickup"), the address is in the sheet below it.
    final header = expanded || !showDetailsButton;
    final named = waiting || header || nextAddress == null;
    final mark = named ? null : nextMark;
    final address = named ? statusLabel : nextAddress!;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Very narrow (small phone with "I've arrived"): time and words only.
        final tight = constraints.maxWidth < 150;
        return Row(
          children: [
            // Long words like "Route unavailable" shorten too, never overflow.
            Flexible(
              flex: 2,
              child: Text(
                lead,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: strong.copyWith(color: leadColor),
              ),
            ),
            if (distance != null && !tight) ...[
              dot(),
              Flexible(
                child: Text(
                  distance,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: strong.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
            dot(),
            if (mark != null) ...[
              RouteMarkIcon(mark, size: 14),
              const SizedBox(width: 5),
            ],
            Flexible(
              flex: 3,
              child: Text(
                address,
                key: const ValueKey<String>('trip-bar-next-address'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF3D4543),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            if (!tight) ...[const SizedBox(width: 7), _paymentLogo()],
          ],
        );
      },
    );
  }

  Widget _paymentLogo() {
    final cash = paidByCash;
    return Tooltip(
      message: cash ? 'Cash: collect in the car' : 'Paid by card',
      child: Container(
        key: ValueKey<String>(cash ? 'trip-pay-cash' : 'trip-pay-card'),
        width: 26,
        height: 19,
        decoration: BoxDecoration(
          color: cash ? const Color(0xFFE7F6EE) : const Color(0xFFF1F3F4),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: cash ? const Color(0x5519865C) : const Color(0xFFDDE1E3),
          ),
        ),
        child: Icon(
          cash ? Icons.payments_rounded : Icons.credit_card_rounded,
          size: 13,
          color: cash ? const Color(0xFF19865C) : const Color(0xFF4A5452),
        ),
      ),
    );
  }

  /// Wait window: free part, then paid part, with a tick where paid starts.
  Widget _waitTrack(double fraction) {
    const paid = Color(0xFF19865C);
    const alert = Color(0xFF9E2B33);
    return Padding(
      key: const ValueKey<String>('trip-wait-line'),
      padding: const EdgeInsets.only(right: 4),
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
                    child: Container(
                      height: 4,
                      color: waitAlert ? alert : paid,
                    ),
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

  /// Line to the next point: driven part in ink, the car at its tip and
  /// the next point's mark at the end.
  Widget _track(double fraction) {
    const car = 18.0;
    final mark = nextMark;
    return Padding(
      key: const ValueKey<String>('trip-progress-line'),
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: car,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final travel =
                constraints.maxWidth - car - RouteMarkPins.markSize / 2;
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
                if (mark != null)
                  Positioned(right: 0, child: RouteMarkIcon(mark)),
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
