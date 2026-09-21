import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Shared top-down Movera car used on Home and the active ride map.
class MoveraVehicleMarker {
  const MoveraVehicleMarker._();

  static Future<BitmapDescriptor> createIcon() async {
    const designSize = 96.0;
    const outputSize = 48.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(outputSize / designSize);

    final shadowPaint = Paint()
      ..color = const Color(0x26000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      const Rect.fromLTWH(27, 68, 42, 10),
      shadowPaint,
    );

    final bodyRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(31, 13, 34, 66),
      const Radius.circular(14),
    );
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF1F4F2),
          Color(0xFFC9D0CD),
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(bodyRect.outerRect);
    canvas.drawRRect(bodyRect, bodyPaint);

    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = const Color(0xFF19865C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(35, 23, 26, 18),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF34464E),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(36, 51, 24, 14),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF536168),
    );

    final highlight = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      const Offset(35, 20),
      const Offset(35, 61),
      highlight,
    );

    final wheelPaint = Paint()..color = const Color(0xFF222B2F);
    for (final rect in const [
      Rect.fromLTWH(27, 28, 5, 13),
      Rect.fromLTWH(64, 28, 5, 13),
      Rect.fromLTWH(27, 53, 5, 13),
      Rect.fromLTWH(64, 53, 5, 13),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        wheelPaint,
      );
    }

    canvas.drawCircle(
      const Offset(48, 10),
      3.2,
      Paint()..color = const Color(0xFF19865C),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      outputSize.round(),
      outputSize.round(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
    return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
  }
}
