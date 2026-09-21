import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:movera/widgets/movera_sheet_metrics.dart';

/// UI-aware map padding so fitted routes stay in the unobstructed viewport.
class MapOverlayInsets {
  const MapOverlayInsets({
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
  });

  final double top;
  final double bottom;
  final double left;
  final double right;

  EdgeInsets get edgeInsets =>
      EdgeInsets.fromLTRB(left, top, right, bottom);

  double get boundsPadding {
    final shortest = [top, bottom, left, right].reduce(math.min);
    return shortest.clamp(36.0, 72.0);
  }

  factory MapOverlayInsets.forHome({
    required double safeTop,
    required double obscuredBottom,
    bool hasTopBanner = false,
  }) {
    return MapOverlayInsets(
      top: safeTop + (hasTopBanner ? 68 : 16),
      bottom: obscuredBottom + 18,
      left: 36,
      right: 72,
    );
  }

  factory MapOverlayInsets.forActiveRide({
    required double safeTop,
    double collapsedSheet = MoveraSheetMetrics.activeCollapsedHeight,
  }) {
    return MapOverlayInsets(
      top: safeTop + 76,
      bottom: collapsedSheet + 10,
      left: 32,
      right: 56,
    );
  }
}
