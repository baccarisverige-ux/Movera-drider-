import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movera/constants/appassets.dart';

/// Compact journey overview. Waiting clocks belong exclusively to the island.
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
    this.stopCount = 0,
    this.nextPointIndex = 0,
    this.legFraction = 0,
  });
  final String etaLabel, statusLabel;
  final String? distanceLabel;
  final VoidCallback onPreferences, onDetails;
  final VoidCallback? onStatusTap;
  final bool expanded, waiting;
  final int stopCount, nextPointIndex;
  final double legFraction;
  static const _ink = Color(0xFF303A3F);

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 76,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
          child: TripJourneyLane(
            stopCount: stopCount,
            nextPointIndex: nextPointIndex,
            legFraction: legFraction,
            waiting: waiting,
          ),
        ),
        Expanded(
          child: Row(
            children: [
              _button(
                'Ride preferences',
                onPreferences,
                SvgPicture.asset(
                  AppAssets.navMenuBranch,
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(_ink, BlendMode.srcIn),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: onStatusTap ?? onDetails,
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!waiting) ...[
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            distanceLabel == null
                                ? etaLabel
                                : '$etaLabel · $distanceLabel',
                            key: const ValueKey('trip-sheet-next-point-eta'),
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Tooltip(
                        message: statusLabel,
                        child: Text(
                          statusLabel,
                          key: const ValueKey('trip-bar-next-address'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _ink,
                            fontSize: waiting ? 15 : 12,
                            fontWeight: waiting
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _button(
                expanded ? 'Hide trip details' : 'Trip details',
                onDetails,
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.format_list_bulleted_rounded,
                  size: 24,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  static Widget _button(String tooltip, VoidCallback onTap, Widget child) =>
      Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(width: 48, height: 48, child: Center(child: child)),
          ),
        ),
      );
}

/// Ordered milestones, not a distance-proportional route diagram.
/// Endpoint icons sit outside the two-pixel track; every real stop is retained.
class TripJourneyLane extends StatelessWidget {
  const TripJourneyLane({
    super.key,
    required this.stopCount,
    required this.nextPointIndex,
    required this.legFraction,
    required this.waiting,
  });
  final int stopCount, nextPointIndex;
  final double legFraction;
  final bool waiting;
  static const blue = Color(0xFF58A6FF), ink = Color(0xFF303A3F);
  @override
  Widget build(BuildContext context) {
    final count = stopCount < 0 ? 0 : stopCount;
    final target = nextPointIndex.clamp(0, count + 1);
    final fraction = legFraction.isFinite ? legFraction.clamp(0.0, 1.0) : 0.0;
    final progress = ((target + (waiting ? 1 : fraction)) / (count + 2)).clamp(
      0.0,
      1.0,
    );
    return Semantics(
      label:
          'Journey: pickup, $count stops, destination. Next point ${target + 1}',
      child: SizedBox(
        key: const ValueKey('trip-journey-lane'),
        height: 20,
        child: Row(
          children: [
            Icon(
              Icons.person_rounded,
              size: 18,
              color: target == 0 ? blue : ink,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: progress),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => CustomPaint(
                  key: const ValueKey('trip-progress-line'),
                  size: const Size(double.infinity, 20),
                  painter: JourneyLanePainter(
                    stopCount: count,
                    target: target,
                    progress: value,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.location_on_rounded,
              size: 18,
              color: target == count + 1 ? blue : ink,
            ),
          ],
        ),
      ),
    );
  }
}

class JourneyLanePainter extends CustomPainter {
  const JourneyLanePainter({
    required this.stopCount,
    required this.target,
    required this.progress,
  });
  final int stopCount, target;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final pen = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = TripJourneyLane.ink;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), pen);
    final x = size.width * progress;
    if (x > 0) {
      canvas.drawLine(
        Offset(0, y),
        Offset(x, y),
        pen..color = TripJourneyLane.blue,
      );
    }
    for (var i = 0; i <= stopCount; i++) {
      final center = Offset(size.width * (i + 1) / (stopCount + 2), y);
      canvas.drawCircle(center, 4, Paint()..color = Colors.white);
      canvas.drawCircle(
        center,
        2.5,
        Paint()
          ..color = i == target ? TripJourneyLane.blue : TripJourneyLane.ink,
      );
    }
    final arrow = Path()
      ..moveTo(x, y - 7)
      ..lineTo(x + 5, y + 4)
      ..lineTo(x, y + 1)
      ..lineTo(x - 5, y + 4)
      ..close();
    canvas.drawPath(
      arrow,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(arrow, Paint()..color = TripJourneyLane.blue);
  }

  @override
  bool shouldRepaint(JourneyLanePainter oldDelegate) =>
      oldDelegate.stopCount != stopCount ||
      oldDelegate.target != target ||
      oldDelegate.progress != progress;
}
