import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:movera/core/routing/route_instruction.dart';
import 'package:movera/presentation/driver/accept%20ride/waiting_time_sheet.dart';

/// Top ride tab. Maneuver on the first line, the next stop scrolling beneath it.
class NavigationInstructionBanner extends StatelessWidget {
  const NavigationInstructionBanner({
    super.key,
    this.banner,
    this.etaLabel,
    this.eyebrow = '',
    this.title = '',
    this.detail = '',
    this.address = '',
    this.icon = Icons.near_me_outlined,
    this.radarSwitch = false,
    this.radarOn = false,
    this.onRadarToggle,
    this.waitSeconds,
    this.onWaitTap,
  });

  /// Height under the status bar, used to keep the route out from under the tab.
  static const double belowSafeExtent = 154;

  final NavigationBanner? banner;
  final String? etaLabel;
  final String eyebrow;
  final String title;
  final String detail;
  final String address;
  final IconData icon;
  final bool radarSwitch;
  final bool radarOn;
  final VoidCallback? onRadarToggle;
  final int? waitSeconds;
  final VoidCallback? onWaitTap;

  @override
  Widget build(BuildContext context) {
    final live = banner;
    final hero = live == null || live.primary.isEmpty ? title : live.primary;
    final road = (live?.roadName ?? '').trim();
    final meta = road.isNotEmpty ? road : detail.trim();
    final eta = (etaLabel ?? '').trim();
    final pad = MediaQuery.paddingOf(context);
    final symbol = live?.symbol;

    return Material(
      key: const ValueKey<String>('active-ride-navigation-card'),
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12 + pad.left,
          8 + pad.top,
          12 + pad.right,
          0,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF050505),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0x24FFFFFF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x38000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 64,
                    height: 68,
                    child: Center(
                      child: CustomPaint(
                        size: const Size(50, 54),
                        painter: _CuePainter(symbol: symbol, icon: icon),
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (eyebrow.isNotEmpty) ...[
                          Text(
                            eyebrow.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFB9C0C5),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.35,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          hero,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.55,
                            height: 1.02,
                          ),
                        ),
                        if (meta.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFC4C9CD),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (waitSeconds != null) ...[
                    const SizedBox(width: 10),
                    WaitingClock(
                      seconds: waitSeconds!,
                      diameter: 50,
                      onTap: onWaitTap,
                    ),
                  ] else if (eta.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Container(
                      constraints: const BoxConstraints(minWidth: 58, maxWidth: 78),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF171A1D),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: const Color(0x24FFFFFF)),
                      ),
                      child: Text(
                        eta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (address.trim().isNotEmpty || radarSwitch) ...[
                const SizedBox(height: 11),
                Row(
                  children: [
                    if (address.trim().isNotEmpty)
                      Expanded(
                        child: _NextStopLine(
                          key: ValueKey<String>(address),
                          address: address.trim(),
                        ),
                      ),
                    if (address.trim().isNotEmpty && radarSwitch)
                      const SizedBox(width: 8),
                    if (radarSwitch)
                      _RadarOnOff(
                        on: radarOn,
                        onTap: onRadarToggle,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Thin navigation cue. Drawn, not a stock flag or turn glyph.
class _CuePainter extends CustomPainter {
  _CuePainter({required this.symbol, required this.icon});

  final NavigationBannerSymbol? symbol;
  final IconData icon;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 22;
    Offset p(double x, double y) => Offset(x * s, y * s);

    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.15 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    void arrowHead(Offset tip, double angle) {
      final direction = Offset(math.cos(angle), math.sin(angle));
      final perpendicular = Offset(-direction.dy, direction.dx);
      final base = tip - direction * 5.3 * s;
      final halfWidth = 3.8 * s;
      final head = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(
          (base + perpendicular * halfWidth).dx,
          (base + perpendicular * halfWidth).dy,
        )
        ..lineTo(
          (base - perpendicular * halfWidth).dx,
          (base - perpendicular * halfWidth).dy,
        )
        ..close();
      canvas.drawPath(head, fill);
    }

    void hardTurn({required bool left}) {
      final side = left ? -1.0 : 1.0;
      final path = Path()
        ..moveTo(p(11, 19).dx, p(11, 19).dy)
        ..lineTo(p(11, 12).dx, p(11, 12).dy)
        ..quadraticBezierTo(
          p(11, 7).dx,
          p(11, 7).dy,
          p(11 + 4.6 * side, 7).dx,
          p(7, 7).dy,
        )
        ..lineTo(p(11 + 6.0 * side, 7).dx, p(7, 7).dy);
      canvas.drawPath(path, stroke);
      arrowHead(
        p(11 + 8.1 * side, 7),
        left ? math.pi : 0,
      );
    }

    void slightTurn({required bool left}) {
      final side = left ? -1.0 : 1.0;
      final path = Path()
        ..moveTo(p(11, 19).dx, p(11, 19).dy)
        ..lineTo(p(11, 13).dx, p(11, 13).dy)
        ..quadraticBezierTo(
          p(11, 10).dx,
          p(11, 10).dy,
          p(11 + 2.2 * side, 8.2).dx,
          p(8.2, 8.2).dy,
        )
        ..lineTo(
          p(11 + 5.1 * side, 4.9).dx,
          p(4.9, 4.9).dy,
        );
      canvas.drawPath(path, stroke);
      arrowHead(
        p(11 + 6.25 * side, 3.55),
        left ? -2.3 : -0.84,
      );
    }

    final kind = symbol;
    if (kind == NavigationBannerSymbol.left ||
        kind == NavigationBannerSymbol.sharpLeft) {
      hardTurn(left: true);
      return;
    }
    if (kind == NavigationBannerSymbol.right ||
        kind == NavigationBannerSymbol.sharpRight) {
      hardTurn(left: false);
      return;
    }
    if (kind == NavigationBannerSymbol.slightLeft) {
      slightTurn(left: true);
      return;
    }
    if (kind == NavigationBannerSymbol.slightRight) {
      slightTurn(left: false);
      return;
    }
    if (kind == NavigationBannerSymbol.uTurn) {
      final path = Path()
        ..moveTo(p(15, 19).dx, p(15, 19).dy)
        ..lineTo(p(15, 10).dx, p(15, 10).dy)
        ..cubicTo(
          p(15, 5).dx,
          p(15, 5).dy,
          p(7, 5).dx,
          p(7, 5).dy,
          p(7, 10).dx,
          p(7, 10).dy,
        )
        ..lineTo(p(7, 12).dx, p(7, 12).dy);
      canvas.drawPath(path, stroke);
      arrowHead(p(7, 15), math.pi / 2);
      return;
    }
    if (kind == NavigationBannerSymbol.roundabout) {
      canvas.drawArc(
        Rect.fromCircle(center: p(11, 10.5), radius: 5.2 * s),
        0.6,
        math.pi * 1.55,
        false,
        stroke,
      );
      canvas.drawLine(p(11, 19), p(11, 15.7), stroke);
      arrowHead(p(16.4, 8), -0.75);
      return;
    }
    if (kind == NavigationBannerSymbol.merge) {
      canvas.drawLine(p(11, 19), p(11, 7), stroke);
      canvas.drawLine(p(5.7, 14), p(11, 9.2), stroke);
      arrowHead(p(11, 3), -math.pi / 2);
      return;
    }
    if (kind == NavigationBannerSymbol.exit) {
      canvas.drawLine(p(8, 19), p(8, 6), stroke);
      canvas.drawLine(p(8, 12), p(15, 6.5), stroke);
      arrowHead(p(17.2, 4.8), -0.67);
      return;
    }
    if (kind == NavigationBannerSymbol.arrive || icon == Icons.flag_outlined) {
      canvas.drawCircle(p(11, 10), 5.5 * s, stroke);
      canvas.drawCircle(p(11, 10), 1.7 * s, fill);
      canvas.drawLine(p(11, 15.5), p(11, 19), stroke);
      return;
    }
    if (icon == Icons.location_on_outlined) {
      canvas.drawCircle(p(11, 8.5), 3.2 * s, stroke);
      canvas.drawCircle(p(11, 8.5), 1.15 * s, fill);
      canvas.drawLine(p(11, 12), p(11, 19), stroke);
      return;
    }

    canvas.drawLine(p(11, 19), p(11, 7), stroke);
    arrowHead(p(11, 2.6), -math.pi / 2);
  }

  @override
  bool shouldRepaint(covariant _CuePainter oldDelegate) =>
      oldDelegate.symbol != symbol || oldDelegate.icon != icon;
}

class _NextStopLine extends StatefulWidget {
  const _NextStopLine({super.key, required this.address});

  final String address;

  @override
  State<_NextStopLine> createState() => _NextStopLineState();
}

class _NextStopLineState extends State<_NextStopLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7600),
    )..repeat();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Color(0xFFF7F8FA),
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    );

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3B434D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x2EFFFFFF)),
      ),
      child: Row(
        children: [
          const Text(
            'TO',
            style: TextStyle(
              color: Color(0xFFB9C0C5),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final painter = TextPainter(
                  text: TextSpan(text: widget.address, style: style),
                  maxLines: 1,
                  textDirection: TextDirection.ltr,
                )..layout();
                final overflow = painter.width - constraints.maxWidth;
                final travel = overflow > 8 ? overflow + 24 : 0.0;

                return ClipRect(
                  child: AnimatedBuilder(
                    animation: _motion,
                    builder: (context, _) {
                      final phase = _scrollPhase(_motion.value);
                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Transform.translate(
                            offset: Offset(-travel * phase, 0),
                            child: Text(
                              widget.address,
                              maxLines: 1,
                              softWrap: false,
                              style: style,
                            ),
                          ),
                          Positioned(
                            left: (constraints.maxWidth + 36) * phase - 28,
                            bottom: 0,
                            child: Container(
                              width: 28,
                              height: 1.5,
                              color: const Color(0xFFF7F8FA),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

double _scrollPhase(double t) {
  if (t < 0.16) { return 0; }
  if (t > 0.84) { return 1; }
  return Curves.easeInOut.transform((t - 0.16) / 0.68);
}

class _RadarOnOff extends StatefulWidget {
  const _RadarOnOff({required this.on, required this.onTap});

  final bool on;
  final VoidCallback? onTap;

  @override
  State<_RadarOnOff> createState() => _RadarOnOffState();
}

class _RadarOnOffState extends State<_RadarOnOff>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.on) { _pulse.repeat(); }
  }

  @override
  void didUpdateWidget(covariant _RadarOnOff oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.on && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.on && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFFF7F8FA);
    const quiet = Color(0xFFB7BFC4);
    final on = widget.on;
    return Material(
      key: const ValueKey<String>('on-trip-radar-switch'),
      color: const Color(0xFF171A1D),
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (on)
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, _) {
                          return CustomPaint(
                            size: const Size(18, 18),
                            painter: _RadarPulsePainter(_pulse.value),
                          );
                        },
                      ),
                    Icon(
                      on ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                      size: 16,
                      color: on ? ink : quiet,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 28,
                height: 16,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: on ? ink : const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Align(
                  alignment: on ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: on ? Colors.white : quiet,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadarPulsePainter extends CustomPainter {
  _RadarPulsePainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 2; i++) {
      final phase = (t + i * 0.5) % 1;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFF7F8FA).withValues(alpha: (1 - phase) * 0.55);
      canvas.drawCircle(center, 3 + phase * 7, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPulsePainter oldDelegate) =>
      oldDelegate.t != t;
}
