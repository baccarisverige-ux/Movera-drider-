import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Shared top-down Movera car used on Home and the active ride map: white
/// body, dark glass roof with green trim, red tail lights and two light-blue
/// headlight beams ahead that show the heading.
class MoveraVehicleMarker {
  const MoveraVehicleMarker._();

  static const double _designSize = 128;
  static const double _outputSize = 64;

  /// The car's centre in the icon (the beams sit above it); use as the
  /// marker anchor so rotation turns the car around its own middle.
  static const Offset anchor = Offset(0.5, 82 / _designSize);

  static Future<BitmapDescriptor> createIcon() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(_outputSize / _designSize);
    paintCar(canvas);
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      _outputSize.round(),
      _outputSize.round(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
    return BitmapDescriptor.bytes(data.buffer.asUint8List());
  }

  /// Draws the car facing up in a 128 x 128 box, body centred at (64, 82).
  static void paintCar(Canvas c, {bool beams = true}) {
    const cx = 64.0;
    if (beams) {
      for (final side in [-1.0, 1.0]) {
        final hx = cx + side * 10;
        final beam = Path()
          ..moveTo(hx - 3, 48)
          ..lineTo(hx + side * 6 - 13, 6)
          ..quadraticBezierTo(hx + side * 6, 1, hx + side * 6 + 13, 6)
          ..lineTo(hx + 3, 48)
          ..close();
        c.drawPath(
          beam,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xE6DDEFFF), Color(0x66DDEFFF), Color(0x00DDEFFF)],
              stops: [0, 0.6, 1],
            ).createShader(const Rect.fromLTWH(0, 0, 128, 50))
            ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 1.6),
        );
      }
    }
    // shadow
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(44, 50, 40, 74),
        const Radius.circular(16),
      ),
      Paint()
        ..color = const Color(0x40000000)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5),
    );
    // mirrors
    for (final x in [43.0, 79.0]) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 63, 6, 5),
          const Radius.circular(2.5),
        ),
        Paint()..color = const Color(0xFFE9ECEB),
      );
    }
    // body
    final body = RRect.fromRectAndCorners(
      const Rect.fromLTWH(46, 45, 36, 75),
      topLeft: const Radius.circular(15),
      topRight: const Radius.circular(15),
      bottomLeft: const Radius.circular(12),
      bottomRight: const Radius.circular(12),
    );
    c.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFDCE1DF),
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0xFFD3D9D6),
          ],
          stops: [0, 0.28, 0.72, 1],
        ).createShader(body.outerRect),
    );
    c.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFFB9C1BE),
    );
    // glass roof
    final glass = RRect.fromRectAndCorners(
      const Rect.fromLTWH(50, 61, 28, 45),
      topLeft: const Radius.circular(10),
      topRight: const Radius.circular(10),
      bottomLeft: const Radius.circular(7),
      bottomRight: const Radius.circular(7),
    );
    c.drawRRect(
      glass,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A464C), Color(0xFF151C1F), Color(0xFF263035)],
        ).createShader(glass.outerRect),
    );
    // green Movera trim along the roof
    final trim = Paint()
      ..color = const Color(0xFF1FA463)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(49, 70), const Offset(49, 98), trim);
    c.drawLine(const Offset(79, 70), const Offset(79, 98), trim);
    // windshield reflection
    c.drawLine(
      const Offset(55, 65),
      const Offset(70, 63.5),
      Paint()
        ..color = const Color(0x55FFFFFF)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
    // headlights
    final head = Paint()..color = const Color(0xFFEAF6FF);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(50, 46.5, 8, 3),
        const Radius.circular(1.5),
      ),
      head,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(70, 46.5, 8, 3),
        const Radius.circular(1.5),
      ),
      head,
    );
    // tail lights
    final tail = Paint()..color = const Color(0xFFE0362C);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(48.5, 115.5, 9, 3),
        const Radius.circular(1.5),
      ),
      tail,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(70.5, 115.5, 9, 3),
        const Radius.circular(1.5),
      ),
      tail,
    );
  }
}
