import 'package:flutter/material.dart';

/// Collapsed Active Ride dock: stage, ETA, short address. Slide stays outside.
class CompactTripDock extends StatelessWidget {
  const CompactTripDock({
    super.key,
    required this.title,
    required this.detail,
    required this.etaLabel,
  });

  final String title;
  final String detail;
  final String etaLabel;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF252E3A);
    const muted = Color(0xFF7D898F);
    const green = Color(0xFF19865C);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            etaLabel,
            style: const TextStyle(
              color: green,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
