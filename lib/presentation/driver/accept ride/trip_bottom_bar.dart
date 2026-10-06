import 'package:flutter/material.dart';
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
    final waiting = waitFraction != null;
    return SizedBox(
      height: 76,
      child: Row(
        children: [
          _iconButton(
            tooltip: 'Ride preferences',
            onTap: onPreferences,
            child: const Icon(Icons.tune_rounded, size: 26, color: _ink),
          ),
          Expanded(
            child: InkWell(
              onTap: onStatusTap ?? onDetails,
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (waiting)
                    Container(
                      key: const ValueKey('trip-sheet-waiting-timer'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F3EC),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: etaColor ?? _ink,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            etaLabel,
                            style: TextStyle(
                              color: etaColor ?? _ink,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            etaLabel,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: CircleAvatar(
                              radius: 13,
                              backgroundColor: Color(0xFF147749),
                              child: Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          if (distanceLabel != null)
                            Text(
                              distanceLabel!,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 3),
                  Text(
                    statusLabel,
                    key: const ValueKey('trip-bar-next-address'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: statusColor ?? const Color(0xFF3D4543),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _iconButton(
            tooltip: expanded ? 'Hide trip details' : 'Trip details',
            onTap: onDetails,
            child: Icon(
              expanded
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.format_list_bulleted_rounded,
              size: 26,
              color: _ink,
            ),
          ),
        ],
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
