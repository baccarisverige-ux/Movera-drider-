import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Collapsed Active Ride route summary.
///
/// Keeps the important journey context visible together with the primary
/// slide action: pickup, optional stops and drop-off.
class CompactTripDock extends StatelessWidget {
  const CompactTripDock({
    super.key,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.stopCount,
    required this.etaLabel,
    required this.stageLabel,
  });

  final String pickupAddress;
  final String dropoffAddress;
  final int stopCount;
  final String etaLabel;
  final String stageLabel;

  static const _ink = Color(0xFF233039);
  static const _muted = Color(0xFF7D898F);
  static const _green = Color(0xFF19865C);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 7, 14, 2),
      child: Container(
        height: 57,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6ECE9)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF18392E).withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF8FBFA),
                    Color(0xFFE9F4EF),
                  ],
                ),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFFDEEAE5)),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const CustomPaint(
                    painter: _CompactRoutePainter(),
                  ),
                  Align(
                    alignment: const Alignment(-0.62, 0.56),
                    child: _routeNode(
                      'assets/icons/movera_pin.svg',
                      const Color(0xFF19865C),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0.60, -0.54),
                    child: _routeNode(
                      'assets/icons/movera_flag.svg',
                      const Color(0xFF283640),
                    ),
                  ),
                  if (stopCount > 0)
                    Align(
                      alignment: const Alignment(0.02, -0.02),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF74B99A),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF19865C).withOpacity(0.16),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            pickupAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.12,
                            ),
                          ),
                        ),
                        if (stopCount > 0) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F6F3),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '${stopCount} stop${stopCount == 1 ? '' : 's'}',
                              style: const TextStyle(
                                color: Color(0xFF5A796C),
                                fontSize: 7.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: Color(0xFF90A09A),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dropoffAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 9.5,
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
            const SizedBox(width: 7),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    etaLabel,
                    style: const TextStyle(
                      color: _green,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stageLabel,
                    style: const TextStyle(
                      color: Color(0xFF8A9599),
                      fontSize: 7.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _routeNode(String asset, Color color) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF182B24).withOpacity(0.12),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        asset,
        width: 10,
        height: 10,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}

class _CompactRoutePainter extends CustomPainter {
  const _CompactRoutePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()
      ..color = const Color(0xFF315E4D).withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final line = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF70B798),
          Color(0xFF1E7D5C),
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.72)
      ..cubicTo(
        size.width * 0.32,
        size.height * 0.32,
        size.width * 0.68,
        size.height * 0.72,
        size.width * 0.78,
        size.height * 0.27,
      );

    canvas.drawPath(path, shadow);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _CompactRoutePainter oldDelegate) => false;
}
