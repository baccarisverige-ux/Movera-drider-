import 'package:flutter/material.dart';

/// Persistent rider summary. Trip actions live in the expanded sheet;
/// route progress and payment controls live in the top island.
class TripBottomBar extends StatelessWidget {
  const TripBottomBar({
    super.key,
    required this.etaLabel,
    required this.statusLabel,
    required this.onPreferences,
    required this.onDetails,
    this.distanceLabel,
    this.onStatusTap,
    this.expanded = false,
    this.waiting = false,
    this.etaColor,
    this.statusColor,
  });

  final String etaLabel, statusLabel;
  final String? distanceLabel;
  final VoidCallback onPreferences, onDetails;
  final VoidCallback? onStatusTap;
  final bool expanded, waiting;
  final Color? etaColor, statusColor;
  static const _ink = Color(0xFF111614);

  @override
  Widget build(BuildContext context) {
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
