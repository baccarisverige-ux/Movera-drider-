import 'package:flutter/material.dart';

/// Round floating map button shared by Home and Active Ride: a white disc,
/// or a white ring around a [fill] disc (Google, recenter).
class MapControlButton extends StatelessWidget {
  const MapControlButton({
    super.key,
    required this.tooltip,
    required this.onTap,
    required this.child,
    this.size = 52,
    this.fill = Colors.white,
  });

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;
  final double size;
  final Color fill;

  static const Color recenterBlue = Color(0xFF3F78BF);
  static const Color googleGrey = Color(0xFFE4E7EA);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 5,
        shadowColor: const Color(0xFF172027).withValues(alpha: 0.22),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Padding(
              padding: EdgeInsets.all(fill == Colors.white ? 0 : 4),
              child: DecoratedBox(
                decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
