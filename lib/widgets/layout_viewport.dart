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
        // RenderView.size still describes the previous frame during a resize.
        // Current layout constraints follow rotation immediately and also
        // respect setSurfaceSize when widget-test view metrics differ.
        final surface = Size(
          constraints.hasBoundedWidth ? constraints.maxWidth : media.size.width,
          constraints.hasBoundedHeight
              ? constraints.maxHeight
              : media.size.height,
        );

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
