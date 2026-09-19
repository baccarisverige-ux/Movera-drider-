import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Small dash that travels ping-pong along the top lip of the radar sheet.
/// Visible only when the caller mounts it (Trip radar ON).
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
    this.dashLength = 28,
    this.strokeWidth = 2.5,
    this.duration = const Duration(milliseconds: 2400),
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
            progress: _controller.value,
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
  final double notchWidth;
  final double notchDepth;
  final double cornerRadius;
  final Color color;
  final double dashLength;
  final double strokeWidth;

  const _RadarEdgeDashPainter({
    required this.progress,
    required this.notchWidth,
    required this.notchDepth,
    required this.cornerRadius,
    required this.color,
    required this.dashLength,
    required this.strokeWidth,
  });

  Path _topEdgePath(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final notchLeft = centerX - (notchWidth / 2);
    final notchRight = centerX + (notchWidth / 2);
    final radius = cornerRadius.clamp(0.0, size.width / 2).toDouble();

    // Match [_RadarSheetClipper] top lip (left corner → notch cradle → right).
    path.moveTo(radius, 0);
    path.lineTo(notchLeft, 0);
    path.cubicTo(
      notchLeft + 9,
      0,
      centerX - 54,
      notchDepth,
      centerX,
      notchDepth,
    );
    path.cubicTo(
      centerX + 54,
      notchDepth,
      notchRight - 9,
      0,
      notchRight,
      0,
    );
    path.lineTo(size.width - radius, 0);
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final edge = _topEdgePath(size);
    final metrics = edge.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final total = metric.length;
    if (total <= 0) return;

    final half = dashLength / 2;
    final center = progress.clamp(0.0, 1.0) * total;
    final start = (center - half).clamp(0.0, total);
    final end = (center + half).clamp(0.0, total);
    if (end <= start) return;

    final dash = metric.extractPath(start, end);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // Soft glow under the tiret.
    final glow = Paint()
      ..color = color.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 3.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);

    canvas.drawPath(dash, glow);
    canvas.drawPath(dash, paint);
  }

  @override
  bool shouldRepaint(covariant _RadarEdgeDashPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.notchWidth != notchWidth ||
        oldDelegate.notchDepth != notchDepth ||
        oldDelegate.cornerRadius != cornerRadius ||
        oldDelegate.color != color ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
