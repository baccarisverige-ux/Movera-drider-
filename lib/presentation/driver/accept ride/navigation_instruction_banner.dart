import 'package:flutter/material.dart';
import 'package:movera/core/routing/route_instruction.dart';

class NavigationInstructionBanner extends StatelessWidget {
  const NavigationInstructionBanner({
    super.key,
    required this.banner,
    this.etaLabel,
  });

  final NavigationBanner banner;
  final String? etaLabel;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF252E3A);
    const muted = Color(0xFF7D898F);
    final subtitle = [
      if ((banner.roadName ?? '').isNotEmpty) banner.roadName,
      if ((banner.status ?? '').isNotEmpty) banner.status,
    ].whereType<String>().where((item) => item.isNotEmpty).join(' · ');
    final pad = MediaQuery.paddingOf(context);

    return Material(
      key: const ValueKey<String>('active-ride-navigation-card'),
      color: const Color(0xFFFCFDFC),
      elevation: 10,
      shadowColor: const Color(0x33172027),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16 + pad.left,
          10 + pad.top,
          16 + pad.right,
          12,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F6),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                _iconFor(banner.symbol),
                color: ink,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner.primary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if ((etaLabel ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  etaLabel!,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(NavigationBannerSymbol symbol) {
    switch (symbol) {
      case NavigationBannerSymbol.left:
      case NavigationBannerSymbol.sharpLeft:
        return Icons.turn_left_rounded;
      case NavigationBannerSymbol.right:
      case NavigationBannerSymbol.sharpRight:
        return Icons.turn_right_rounded;
      case NavigationBannerSymbol.slightLeft:
        return Icons.turn_slight_left_rounded;
      case NavigationBannerSymbol.slightRight:
        return Icons.turn_slight_right_rounded;
      case NavigationBannerSymbol.uTurn:
        return Icons.u_turn_left_rounded;
      case NavigationBannerSymbol.roundabout:
        return Icons.roundabout_left_rounded;
      case NavigationBannerSymbol.arrive:
        return Icons.flag_rounded;
      case NavigationBannerSymbol.merge:
        return Icons.merge_rounded;
      case NavigationBannerSymbol.exit:
        return Icons.exit_to_app_rounded;
      case NavigationBannerSymbol.straight:
        return Icons.arrow_upward_rounded;
    }
  }
}
