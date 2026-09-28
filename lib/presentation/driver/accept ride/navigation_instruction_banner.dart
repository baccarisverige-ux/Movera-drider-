import 'package:flutter/material.dart';
import 'package:movera/core/routing/route_instruction.dart';

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
  });

  /// Height under the status bar, used to keep the route out from under the tab.
  static const double belowSafeExtent = 118;

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

  static const _ink = Color(0xFF1C242C);
  static const _muted = Color(0xFF7D898F);
  static const _line = Color(0xFFE6E8EA);

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
      color: Colors.white,
      elevation: 8,
      shadowColor: const Color(0x1A172027),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16 + pad.left,
          8 + pad.top,
          16 + pad.right,
          10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _line),
                  ),
                  child: Icon(
                    symbol == null ? icon : _iconFor(symbol),
                    color: _ink,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (eyebrow.isNotEmpty)
                        Text(
                          eyebrow,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.25,
                          ),
                        ),
                      Text(
                        hero,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.35,
                          height: 1.2,
                        ),
                      ),
                      if (meta.isNotEmpty)
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                    ],
                  ),
                ),
                if (radarSwitch) ...[
                  const SizedBox(width: 8),
                  _RadarOnOff(
                    on: radarOn,
                    onTap: onRadarToggle,
                  ),
                ],
                if (eta.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 88),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _line),
                      ),
                      child: Text(
                        eta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (address.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              _NextStopLine(
                key: ValueKey<String>(address),
                address: address.trim(),
              ),
            ],
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
      color: Color(0xFF1C242C),
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    );

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F8),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE6E8EA)),
      ),
      child: Row(
        children: [
          const Text(
            'TO',
            style: TextStyle(
              color: Color(0xFF1C242C),
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
                              color: const Color(0xFF1C242C),
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
  if (t < 0.16) return 0;
  if (t > 0.84) return 1;
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
    if (widget.on) _pulse.repeat();
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
    const ink = Color(0xFF1C242C);
    const quiet = Color(0xFFB7BFC4);
    final on = widget.on;
    return Material(
      key: const ValueKey<String>('on-trip-radar-switch'),
      color: Colors.white,
      elevation: 3,
      shadowColor: const Color(0x1F172027),
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
                  color: on ? ink : const Color(0xFFE6E8EA),
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
        ..color = const Color(0xFF1C242C).withOpacity((1 - phase) * 0.55);
      canvas.drawCircle(center, 3 + phase * 7, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPulsePainter oldDelegate) =>
      oldDelegate.t != t;
}
