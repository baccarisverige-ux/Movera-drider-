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
    required this.stopAddresses,
    required this.etaLabel,
    required this.stageLabel,
    this.onArrived,
    this.riderReply,
  });

  final String pickupAddress;
  final String dropoffAddress;
  final List<String> stopAddresses;
  final String etaLabel;
  final String stageLabel;
  final VoidCallback? onArrived;
  final String? riderReply;

  static const _ink = Color(0xFF233039);
  static const _muted = Color(0xFF7D898F);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 7, 14, 2),
      child: Container(
        height: 63,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6E8EA)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF171C20).withOpacity(0.06),
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
                    Color(0xFFF7F8F9),
                    Color(0xFFEEF0F1),
                  ],
                ),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFFE4E6E8)),
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
                      _ink,
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0.60, -0.54),
                    child: _routeNode(
                      'assets/icons/movera_flag.svg',
                      _ink,
                    ),
                  ),
                  if (stopAddresses.isNotEmpty)
                    Align(
                      alignment: const Alignment(0.02, -0.02),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF252E3A),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF171C20).withOpacity(0.12),
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
                        if (stopAddresses.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F5F6),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '${stopAddresses.length} stop${stopAddresses.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 7.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (stopAddresses.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/movera_stop.svg',
                            width: 9,
                            height: 9,
                            colorFilter: const ColorFilter.mode(
                              _ink,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              stopAddresses.length == 1
                                  ? 'via ${stopAddresses.first}'
                                  : 'via ${stopAddresses.first} +${stopAddresses.length - 1}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 8.3,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 2),
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
                              fontSize: 9.3,
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
              padding: const EdgeInsets.only(right: 8),
              child: onArrived != null
                  ? Material(
                      key: const ValueKey<String>('active-ride-arrived-button'),
                      color: const Color(0xFF252E3A),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: onArrived,
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 9,
                          ),
                          child: Text(
                            "I've arrived",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.05,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          etaLabel,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          riderReply ?? stageLabel,
                          style: TextStyle(
                            color: riderReply != null
                                ? _ink
                                : const Color(0xFF8A9599),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.25,
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
      ..color = const Color(0xFF171C20).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final line = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF9AA0A6),
          Color(0xFF252E3A),
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
