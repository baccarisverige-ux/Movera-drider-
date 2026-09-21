import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Forces [MediaQuery.size] and child constraints to the hittable surface.
///
/// Widget tests call [TestWidgetsFlutterBinding.setSurfaceSize], which sizes
/// the [RenderView], while [MediaQuery] still reads the FlutterView physical
/// size (800x600 by default). Drawers, trays and overlays then lay out off
/// the hittable surface.
class LayoutViewport extends StatelessWidget {
  const LayoutViewport({super.key, required this.child});

  final Widget child;

  static Size sizeOf(BuildContext context) => MediaQuery.sizeOf(context);

  static Size surfaceSize(BuildContext context) {
    final views = WidgetsBinding.instance.renderViews;
    if (views.isNotEmpty) {
      final surface = views.first.size;
      if (surface.width > 0 && surface.height > 0 && surface.isFinite) {
        return surface;
      }
    }
    return MediaQuery.sizeOf(context);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);
        final renderSurface = surfaceSize(context);

        var width = renderSurface.width;
        var height = renderSurface.height;

        if (constraints.maxWidth.isFinite && constraints.maxWidth > 0) {
          width = math.min(width, constraints.maxWidth);
        }
        if (constraints.maxHeight.isFinite && constraints.maxHeight > 0) {
          height = math.min(height, constraints.maxHeight);
        }

        // When the incoming box is the test surface (setSurfaceSize) but
        // MediaQuery still reports the FlutterView, prefer the box.
        if (constraints.maxWidth.isFinite &&
            constraints.maxHeight.isFinite &&
            constraints.maxWidth > 0 &&
            constraints.maxHeight > 0 &&
            (constraints.maxWidth < media.size.width - 0.5 ||
                constraints.maxHeight > media.size.height + 0.5 ||
                constraints.maxWidth < renderSurface.width - 0.5)) {
          width = constraints.maxWidth;
          height = constraints.maxHeight;
        }

        final surface = Size(width, height);

        return MediaQuery(
          data: media.copyWith(size: surface),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: surface.width,
              height: surface.height,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
