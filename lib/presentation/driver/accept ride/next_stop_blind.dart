import 'package:flutter/material.dart';

/// Collapsed-sheet destination blind.
///
/// Sits in the white gap under the route card and reads like a bus or train
/// enseigne: the step has its own line, and the next stop scrolls in light.
class NextStopBlind extends StatefulWidget {
  const NextStopBlind({
    super.key,
    required this.eyebrow,
    required this.address,
    required this.detail,
    required this.glow,
  });

  final String eyebrow;
  final String address;
  final String detail;
  final Color glow;

  @override
  State<NextStopBlind> createState() => _NextStopBlindState();
}

class _NextStopBlindState extends State<NextStopBlind>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7200),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant NextStopBlind oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.address != widget.address ||
        oldWidget.eyebrow != widget.eyebrow) {
      _motion.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faceKey = ValueKey<String>(
      '${widget.eyebrow}|${widget.address}|${widget.detail}',
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF243140),
              Color(0xFF141B24),
            ],
          ),
          border: Border.all(color: const Color(0xFF31404F)),
          boxShadow: [
            BoxShadow(
              color: widget.glow.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: SizedBox(
            height: 64,
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _motion,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _BlindSweepPainter(
                        travel: _motion.value,
                        glow: widget.glow,
                      ),
                      child: const SizedBox.expand(),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 460),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder: (current, previous) {
                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          ...previous,
                          if (current != null) current,
                        ],
                      );
                    },
                    transitionBuilder: (child, animation) {
                      return ClipRect(
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.72),
                            end: Offset.zero,
                          ).animate(animation),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: _BlindFace(
                      key: faceKey,
                      eyebrow: widget.eyebrow,
                      address: widget.address,
                      detail: widget.detail,
                      glow: widget.glow,
                      motion: _motion,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlindFace extends StatelessWidget {
  const _BlindFace({
    super.key,
    required this.eyebrow,
    required this.address,
    required this.detail,
    required this.glow,
    required this.motion,
  });

  final String eyebrow;
  final String address;
  final String detail;
  final Color glow;
  final Animation<double> motion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _GlowDot(glow: glow, motion: motion),
            const SizedBox(width: 7),
            Text(
              eyebrow,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: glow,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.35,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFFC5D0DA),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: _ScrollingAddress(
            address: address,
            glow: glow,
            motion: motion,
          ),
        ),
      ],
    );
  }
}

class _GlowDot extends StatelessWidget {
  const _GlowDot({required this.glow, required this.motion});

  final Color glow;
  final Animation<double> motion;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: motion,
      builder: (context, _) {
        final pulse = 0.45 + 0.55 * (0.5 + 0.5 * _sine(motion.value * 2));
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: glow.withValues(alpha: pulse),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: glow.withValues(alpha: 0.85 * pulse),
                blurRadius: 8,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScrollingAddress extends StatelessWidget {
  const _ScrollingAddress({
    required this.address,
    required this.glow,
    required this.motion,
  });

  final String address;
  final Color glow;
  final Animation<double> motion;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Color(0xFFF4F7FA),
      fontSize: 18,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.3,
      height: 1.05,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: address, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout();
        final overflow = painter.width - constraints.maxWidth;
        final travel = overflow > 8 ? overflow + 28 : 0.0;

        return ClipRect(
          child: AnimatedBuilder(
            animation: motion,
            builder: (context, _) {
              final dx = -travel * _scrollPhase(motion.value);
              return Transform.translate(
                offset: Offset(dx, 0),
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (rect) {
                    final sweep = (motion.value * 1.6) % 1.0;
                    return LinearGradient(
                      begin: Alignment(-1.4 + sweep * 2.8, 0),
                      end: Alignment(-0.4 + sweep * 2.8, 0),
                      colors: [
                        glow.withValues(alpha: 0.72),
                        const Color(0xFFFFF8EC),
                        const Color(0xFFF7FBFF),
                        glow,
                      ],
                      stops: const [0, 0.42, 0.58, 1],
                    ).createShader(rect);
                  },
                  child: Text(
                    address,
                    maxLines: 1,
                    softWrap: false,
                    style: style,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _BlindSweepPainter extends CustomPainter {
  const _BlindSweepPainter({required this.travel, required this.glow});

  final double travel;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = _scrollPhase(travel);
    final band = Paint()..color = glow.withValues(alpha: 0.55);
    final width = size.width * 0.28;
    final left = -width + (size.width + width) * phase;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, size.height - 2.5, width, 2.5),
        const Radius.circular(99),
      ),
      band,
    );
  }

  @override
  bool shouldRepaint(covariant _BlindSweepPainter oldDelegate) {
    return oldDelegate.travel != travel || oldDelegate.glow != glow;
  }
}

double _scrollPhase(double t) {
  if (t < 0.14) return 0;
  if (t > 0.86) return 1;
  final u = (t - 0.14) / 0.72;
  return Curves.easeInOut.transform(u);
}

double _sine(double turns) {
  final x = (turns % 1) * 2 - 1;
  return 1 - (x * x);
}
