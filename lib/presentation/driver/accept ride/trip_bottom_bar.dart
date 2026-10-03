import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movera/constants/appassets.dart';

/// Collapsed Active Ride bar: Ride preferences on the left, time and
/// distance to the next point in the middle, trip details on the right.
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
  });

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
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              etaLabel,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 26,
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
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.6,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              statusLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
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
