import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Top lip of the radar sheet (left corner → notch cradle → right corner),
/// matching [RadarSheetClipper].
Path radarSheetTopEdge(
  Size size, {
  required double notchWidth,
  required double notchDepth,
  required double cornerRadius,
  bool includeCorners = false,
}) {
  final path = Path();
  final centerX = size.width / 2;
  final notchLeft = centerX - (notchWidth / 2);
  final notchRight = centerX + (notchWidth / 2);
  final radius = cornerRadius.clamp(0.0, size.width / 2).toDouble();

  if (includeCorners) {
    path.moveTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);
  } else {
    path.moveTo(radius, 0);
  }
  path.lineTo(notchLeft, 0);
  path.cubicTo(notchLeft + 9, 0, centerX - 54, notchDepth, centerX, notchDepth);
  path.cubicTo(centerX + 54, notchDepth, notchRight - 9, 0, notchRight, 0);
  path.lineTo(size.width - radius, 0);
  if (includeCorners) {
    path.quadraticBezierTo(size.width, 0, size.width, radius);
  }
  return path;
}

/// Fine grey contour along the top lip of the radar sheet.
class RadarSheetOutline extends StatelessWidget {
  final double notchWidth;
  final double notchDepth;
  final double cornerRadius;
  final Color color;

  const RadarSheetOutline({
    super.key,
    this.notchWidth = 126,
    this.notchDepth = 58,
    this.cornerRadius = 24,
    this.color = const Color(0xFFCDD2D6),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RadarSheetOutlinePainter(
        notchWidth: notchWidth,
        notchDepth: notchDepth,
        cornerRadius: cornerRadius,
        color: color,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _RadarSheetOutlinePainter extends CustomPainter {
  final double notchWidth;
  final double notchDepth;
  final double cornerRadius;
  final Color color;

  const _RadarSheetOutlinePainter({
    required this.notchWidth,
    required this.notchDepth,
    required this.cornerRadius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) { return; }
    final edge = radarSheetTopEdge(
      size,
      notchWidth: notchWidth,
      notchDepth: notchDepth,
      cornerRadius: cornerRadius,
      includeCorners: true,
    );
    // Half a pixel inside the sheet so the clip does not cut the line.
    canvas.translate(0, 0.5);
    canvas.drawPath(
      edge,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarSheetOutlinePainter oldDelegate) {
    return oldDelegate.notchWidth != notchWidth ||
        oldDelegate.notchDepth != notchDepth ||
        oldDelegate.cornerRadius != cornerRadius ||
        oldDelegate.color != color;
  }
}

/// Laser beam that sweeps ping-pong along the top lip of the radar sheet,
/// with a bright head and a fading tail. Visible only when the caller
/// mounts it (Trip radar ON).
class RadarEdgeDash extends StatefulWidget {
  final double notchWidth;
  final double notchDepth;
  final double cornerRadius;
  final Color color;
  final double dashLength;
  final double strokeWidth;
  final Duration duration;

  const RadarEdgeDash({
    super.key,
    this.notchWidth = 126,
    this.notchDepth = 58,
    this.cornerRadius = 24,
    this.color = const Color(0xFF2FBE7B),
    this.dashLength = 120,
    this.strokeWidth = 3,
    this.duration = const Duration(milliseconds: 1700),
  });

  @override
  State<RadarEdgeDash> createState() => _RadarEdgeDashState();
}

class _RadarEdgeDashState extends State<RadarEdgeDash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _RadarEdgeDashPainter(
            progress: Curves.easeInOutSine.transform(_controller.value),
            forward: _controller.status != AnimationStatus.reverse,
            notchWidth: widget.notchWidth,
            notchDepth: widget.notchDepth,
            cornerRadius: widget.cornerRadius,
            color: widget.color,
            dashLength: widget.dashLength,
            strokeWidth: widget.strokeWidth,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _RadarEdgeDashPainter extends CustomPainter {
  final double progress;
  final bool forward;
  final double notchWidth;
  final double notchDepth;
  final double cornerRadius;
  final Color color;
  final double dashLength;
  final double strokeWidth;

  const _RadarEdgeDashPainter({
    required this.progress,
    required this.forward,
    required this.notchWidth,
    required this.notchDepth,
    required this.cornerRadius,
    required this.color,
    required this.dashLength,
    required this.strokeWidth,
  });

  static const int _tailSegments = 16;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) { return; }

    final edge = radarSheetTopEdge(
      size,
      notchWidth: notchWidth,
      notchDepth: notchDepth,
      cornerRadius: cornerRadius,
    );
    final metrics = edge.computeMetrics().toList();
    if (metrics.isEmpty) { return; }
    final metric = metrics.first;
    final total = metric.length;
    if (total <= 0) { return; }

    // Faint track so the beam reads as running along a rail.
    canvas.drawPath(
      edge,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    final head = progress.clamp(0.0, 1.0) * total;
    // The tail trails behind the direction of travel.
    final tailEnd = forward ? head - dashLength : head + dashLength;
    final from = tailEnd.clamp(0.0, total);
    final to = head.clamp(0.0, total);
    final lo = from < to ? from : to;
    final hi = from < to ? to : from;
    if (hi - lo < 0.5) { return; }

    // Wide soft glow under the whole beam.
    canvas.drawPath(
      metric.extractPath(lo, hi),
      Paint()
        ..color = color.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 7),
    );

    // Tail fades from transparent to full colour at the head.
    final step = (to - from) / _tailSegments;
    for (var i = 0; i < _tailSegments; i++) {
      final a = from + step * i;
      final b = from + step * (i + 1);
      final s = a < b ? a : b;
      final e = a < b ? b : a;
      if (e - s < 0.1) { continue; }
      final t = (i + 1) / _tailSegments;
      canvas.drawPath(
        metric.extractPath(s, e + 0.6),
        Paint()
          ..color = color.withValues(alpha: t)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * (0.45 + 0.55 * t)
          ..strokeCap = StrokeCap.butt,
      );
    }

    // Hot white core near the head.
    final coreLen = dashLength * 0.28;
    final coreFrom = (forward ? head - coreLen : head + coreLen).clamp(0.0, total);
    final cs = coreFrom < to ? coreFrom : to;
    final ce = coreFrom < to ? to : coreFrom;
    if (ce - cs > 0.5) {
      canvas.drawPath(
        metric.extractPath(cs, ce),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 0.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Glowing tip.
    final tangent = metric.getTangentForOffset(to);
    if (tangent != null) {
      canvas.drawCircle(
        tangent.position,
        strokeWidth * 2.6,
        Paint()
          ..color = color.withValues(alpha: 0.8)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5),
      );
      canvas.drawCircle(
        tangent.position,
        strokeWidth * 0.75,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarEdgeDashPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.forward != forward ||
        oldDelegate.notchWidth != notchWidth ||
        oldDelegate.notchDepth != notchDepth ||
        oldDelegate.cornerRadius != cornerRadius ||
        oldDelegate.color != color ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
