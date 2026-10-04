import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum RouteMarkKind { pickup, stop, dropoff }

/// One route mark as a widget, e.g. in the trip bar or the top card.
class RouteMarkIcon extends StatelessWidget {
  const RouteMarkIcon(this.kind, {super.key, this.size = RouteMarkPins.markSize});

  final RouteMarkKind kind;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _RouteMarkPainter(kind)),
  );
}

class _RouteMarkPainter extends CustomPainter {
  const _RouteMarkPainter(this.kind);

  final RouteMarkKind kind;

  @override
  void paint(Canvas canvas, Size size) =>
      RouteMarkPins.paintMark(canvas, size.center(Offset.zero), kind);

  @override
  bool shouldRepaint(covariant _RouteMarkPainter oldDelegate) =>
      oldDelegate.kind != kind;
}

/// Classic route marks for Google Maps markers: a black dot for pickup, a
/// grey dot for a stop and a black square for drop-off, each with a white
/// centre. [RouteMarkPins.labelled] adds a bubble above the mark with a
/// title and a time, e.g. "Pickup" / "07:40".
class RouteMarkPins {
  const RouteMarkPins._();

  static const Color ink = Color(0xFF111614);
  static const Color stopGrey = Color(0xFF8A9195);
  static const double _ratio = 3;

  /// Size of a bare mark, in logical pixels.
  static const double markSize = 18;

  /// Font for the bubble text; null uses the platform font, as the app does.
  @visibleForTesting
  static String? debugFontFamily;

  /// Logical size of a labelled pin for [title] and [time].
  static Size labelledSize(String title, String? time) {
    final bubble = _bubbleSize(title, time);
    return Size(bubble.width + 4, bubble.height + _gap + markSize + 4);
  }

  /// Where the mark's centre sits inside a labelled pin, as a marker anchor.
  static Offset labelledAnchor(String title, String? time) {
    final size = labelledSize(title, time);
    return Offset(0.5, (size.height - 2 - markSize / 2) / size.height);
  }

  static Future<BitmapDescriptor> mark(RouteMarkKind kind) {
    return _toBitmap(
      const Size(markSize, markSize),
      (canvas, size) => paintMark(canvas, size.center(Offset.zero), kind),
    );
  }

  static Future<BitmapDescriptor> labelled(
    RouteMarkKind kind,
    String title,
    String? time,
  ) {
    return _toBitmap(
      labelledSize(title, time),
      (canvas, size) => paintLabelled(canvas, size, kind, title, time),
    );
  }

  /// Draws one mark centred on [center].
  static void paintMark(Canvas canvas, Offset center, RouteMarkKind kind) {
    final stop = kind == RouteMarkKind.stop;
    final square = kind == RouteMarkKind.dropoff;
    final outer = stop ? 13.0 : 16.0;
    final inner = stop ? 5.0 : 6.0;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 1.5);
    final fill = Paint()..color = stop ? stopGrey : ink;
    final ring = Paint()..color = Colors.white;
    final dot = Paint()..color = Colors.white;
    if (square) {
      final r = Rect.fromCenter(center: center, width: outer, height: outer);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          r.inflate(1.5).shift(const Offset(0, 0.8)),
          const Radius.circular(4),
        ),
        shadow,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(r.inflate(1.5), const Radius.circular(4)),
        ring,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(3)),
        fill,
      );
      canvas.drawRect(
        Rect.fromCenter(center: center, width: inner, height: inner),
        dot,
      );
    } else {
      canvas.drawCircle(center.translate(0, 0.8), outer / 2 + 1.5, shadow);
      canvas.drawCircle(center, outer / 2 + 1.5, ring);
      canvas.drawCircle(center, outer / 2, fill);
      canvas.drawCircle(center, inner / 2, dot);
    }
  }

  /// Bubble with [title] (small) and [time] (bold) above the mark.
  static void paintLabelled(
    Canvas canvas,
    Size size,
    RouteMarkKind kind,
    String title,
    String? time,
  ) {
    final dark = kind != RouteMarkKind.stop;
    final bubble = _bubbleSize(title, time);
    final rect = Rect.fromLTWH(
      (size.width - bubble.width) / 2,
      2,
      bubble.width,
      bubble.height,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    canvas.drawRRect(
      rrect.shift(const Offset(0, 1.5)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.5),
    );
    final bg = Paint()..color = dark ? ink : Colors.white;
    canvas.drawRRect(rrect, bg);
    // Small pointer from the bubble down to the mark.
    final cx = size.width / 2;
    canvas.drawPath(
      Path()
        ..moveTo(cx - 6, rect.bottom - 1)
        ..lineTo(cx, rect.bottom + 6)
        ..lineTo(cx + 6, rect.bottom - 1)
        ..close(),
      bg,
    );
    final titlePainter = _text(
      title,
      dark ? const Color(0xFFB4BCC0) : const Color(0xFF5E6461),
      10.5,
      FontWeight.w500,
    );
    final timePainter = time == null
        ? null
        : _text(time, dark ? Colors.white : ink, 14, FontWeight.w800);
    var y = rect.top + _padV;
    if (timePainter != null) {
      titlePainter.paint(canvas, Offset(cx - titlePainter.width / 2, y));
      y += titlePainter.height;
      timePainter.paint(canvas, Offset(cx - timePainter.width / 2, y));
    } else {
      final big = _text(
        title,
        dark ? Colors.white : ink,
        12.5,
        FontWeight.w700,
      );
      big.paint(
        canvas,
        Offset(cx - big.width / 2, rect.center.dy - big.height / 2),
      );
    }
    paintMark(canvas, Offset(cx, size.height - 2 - markSize / 2), kind);
  }

  static const double _padH = 10;
  static const double _padV = 5;
  static const double _gap = 8;

  static Size _bubbleSize(String title, String? time) {
    if (time == null) {
      final big = _text(title, ink, 12.5, FontWeight.w700);
      return Size(big.width + _padH * 2, big.height + _padV * 2 + 2);
    }
    final t = _text(title, ink, 10.5, FontWeight.w500);
    final v = _text(time, ink, 14, FontWeight.w800);
    final w = (t.width > v.width ? t.width : v.width) + _padH * 2;
    return Size(w < 52 ? 52 : w, t.height + v.height + _padV * 2);
  }

  static TextPainter _text(String s, Color c, double size, FontWeight w) {
    return TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: c,
          fontSize: size,
          fontWeight: w,
          height: 1.15,
          fontFamily: debugFontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  static Future<BitmapDescriptor> _toBitmap(
    Size size,
    void Function(Canvas canvas, Size size) paint,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(_ratio);
    paint(canvas, size);
    final image = await recorder.endRecording().toImage(
      (size.width * _ratio).ceil(),
      (size.height * _ratio).ceil(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      return BitmapDescriptor.defaultMarker;
    }
    return BitmapDescriptor.bytes(
      data.buffer.asUint8List(),
      imagePixelRatio: _ratio,
    );
  }
}
