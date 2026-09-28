import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:movera/widgets/movera_modal_sheet.dart';

const int _graceSeconds = 120;
const int _noShowSeconds = 300;

/// Opens the pickup-wait screen. It reads live seconds from the active trip.
Future<void> showWaitingTimeSheet(
  BuildContext context, {
  required int Function() readSeconds,
  VoidCallback? onNoShow,
}) {
  return showMoveraModalSheet<void>(
    context: context,
    heightFactor: 0.92,
    builder: (sheetContext) {
      return WaitingTimeSheet(
        readSeconds: readSeconds,
        onNoShow: onNoShow,
      );
    },
  );
}

class WaitingTimeSheet extends StatefulWidget {
  const WaitingTimeSheet({
    super.key,
    required this.readSeconds,
    this.onNoShow,
  });

  final int Function() readSeconds;
  final VoidCallback? onNoShow;

  @override
  State<WaitingTimeSheet> createState() => _WaitingTimeSheetState();
}

class _WaitingTimeSheetState extends State<WaitingTimeSheet> {
  static const _ink = Color(0xFF1C242C);
  static const _muted = Color(0xFF7D898F);
  Timer? _tick;

  int get _seconds => widget.readSeconds();

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _seconds;
    final phase = _WaitPhase.of(seconds);

    return MoveraModalSheet(
      key: const ValueKey<String>('waiting-time-sheet'),
      heightFactor: 0.92,
      color: const Color(0xFFF6F7F8),
      radius: 28,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                _CloseMark(onTap: () => Navigator.pop(context)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Pickup wait',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              physics: const BouncingScrollPhysics(),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE6E8EA)),
                  ),
                  child: Column(
                    children: [
                      WaitingClock(
                        seconds: seconds,
                        diameter: 132,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        phase.title,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        phase.detail,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _PhaseCard(
                  title: 'Included time',
                  detail: 'The opening minutes stay inside the fare.',
                  value: '2 min',
                  state: seconds < _graceSeconds
                      ? _PhaseState.now
                      : _PhaseState.done,
                ),
                const SizedBox(height: 8),
                _PhaseCard(
                  title: 'Wait time',
                  detail: 'Added to the fare when this trip is completed.',
                  value: '12,26 kr / min',
                  tone: const Color(0xFF146B45),
                  state: seconds < _graceSeconds
                      ? _PhaseState.later
                      : _PhaseState.now,
                ),
                const SizedBox(height: 8),
                _PhaseCard(
                  title: 'No-show',
                  detail: 'Can be applied if the rider has not arrived.',
                  value: '65,00 kr',
                  tone: const Color(0xFF9E2B33),
                  state: seconds < _noShowSeconds
                      ? _PhaseState.later
                      : _PhaseState.now,
                ),
                if (seconds >= _noShowSeconds && widget.onNoShow != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      key: const ValueKey<String>('waiting-no-show-cancel'),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onNoShow?.call();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF9E2B33),
                        side: const BorderSide(color: Color(0xFF9E2B33)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Cancel for no-show',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  'Amounts can change with taxes and fees.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _ink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _PhaseState { now, done, later }

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({
    required this.title,
    required this.detail,
    required this.value,
    required this.state,
    this.tone = const Color(0xFF1C242C),
  });

  final String title;
  final String detail;
  final String value;
  final _PhaseState state;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF1C242C);
    const muted = Color(0xFF7D898F);
    final active = state == _PhaseState.now;
    final label = switch (state) {
      _PhaseState.now => 'Now',
      _PhaseState.done => 'Done',
      _PhaseState.later => 'Later',
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active ? tone : const Color(0xFFE6E8EA),
          width: active ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: state == _PhaseState.later ? muted : ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11.5,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: state == _PhaseState.later ? muted : ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: active ? tone : muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CloseMark extends StatelessWidget {
  const _CloseMark({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE6E8EA)),
          ),
          child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF1C242C)),
        ),
      ),
    );
  }
}

class _WaitPhase {
  const _WaitPhase(this.title, this.detail);

  final String title;
  final String detail;

  static _WaitPhase of(int seconds) {
    if (seconds < _graceSeconds) {
      return const _WaitPhase(
        'Included minutes',
        'These first minutes are already part of the fare.',
      );
    }
    if (seconds < _noShowSeconds) {
      return const _WaitPhase(
        'Wait time is running',
        'Each minute after the included time is added when the trip ends.',
      );
    }
    return const _WaitPhase(
      'No-show can be applied',
      'The rider is still not here. The no-show amount is now available.',
    );
  }
}

/// Round pickup clock. A quiet hand keeps moving, and the ring tracks the wait.
class WaitingClock extends StatefulWidget {
  const WaitingClock({
    super.key,
    required this.seconds,
    this.onTap,
    this.diameter = 48,
  });

  final int seconds;
  final VoidCallback? onTap;
  final double diameter;

  @override
  State<WaitingClock> createState() => _WaitingClockState();
}

class _WaitingClockState extends State<WaitingClock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hand;

  @override
  void initState() {
    super.initState();
    _hand = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _hand.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = _clockLabel(widget.seconds);
    final tone = _waitTone(widget.seconds);
    final clock = AnimatedBuilder(
      animation: _hand,
      builder: (context, _) {
        return CustomPaint(
          size: Size.square(widget.diameter),
          painter: _ClockPainter(
            seconds: widget.seconds,
            hand: _hand.value,
            tone: tone,
          ),
          child: SizedBox(
            width: widget.diameter,
            height: widget.diameter,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.92, end: 1).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  label,
                  key: ValueKey<String>(label),
                  style: TextStyle(
                    color: tone,
                    fontSize: widget.diameter * 0.24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (widget.onTap == null) return clock;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        customBorder: const CircleBorder(),
        child: clock,
      ),
    );
  }
}

String _clockLabel(int seconds) {
  final minutes = seconds ~/ 60;
  final rest = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$rest';
}

class _ClockPainter extends CustomPainter {
  _ClockPainter({
    required this.seconds,
    required this.hand,
    required this.tone,
  });

  final int seconds;
  final double hand;
  final Color tone;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width < 70 ? 2 : 3
      ..color = const Color(0xFFE6E8EA);
    canvas.drawCircle(center, radius, track);

    final window = seconds < _graceSeconds
        ? seconds / _graceSeconds
        : seconds < _noShowSeconds
            ? (seconds - _graceSeconds) / (_noShowSeconds - _graceSeconds)
            : 1.0;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width < 70 ? 2.2 : 3.2
      ..strokeCap = StrokeCap.round
      ..color = tone;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.max(0.08, window) * math.pi * 2,
      false,
      arc,
    );

    final angle = (-math.pi / 2) + hand * math.pi * 2;
    final inner = radius * 0.62;
    final outer = radius * 0.86;
    final handPaint = Paint()
      ..color = tone.withOpacity(0.9)
      ..strokeWidth = size.width < 70 ? 1.4 : 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center + Offset(math.cos(angle), math.sin(angle)) * inner,
      center + Offset(math.cos(angle), math.sin(angle)) * outer,
      handPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) =>
      oldDelegate.seconds != seconds ||
      oldDelegate.hand != hand ||
      oldDelegate.tone != tone;
}

Color _waitTone(int seconds) {
  if (seconds >= _noShowSeconds) return const Color(0xFF9E2B33);
  if (seconds >= _graceSeconds) return const Color(0xFF146B45);
  return const Color(0xFF1C242C);
}
