import 'dart:math' as math;

import 'package:flutter/physics.dart';

/// Shared snap geometry and spring for Home and Active Ride sheets.
class MoveraSheetMetrics {
  const MoveraSheetMetrics._();

  static const double collapsedHeight = 108;
  /// Content of the collapsed Active Ride bar.
  static const double activeCollapsedHeight = 77;

  /// Empty space under the bar's content, or the phone's own bottom safe
  /// area when that is taller; same proportions as common driver apps.
  static const double activeBottomGap = 34;

  /// Full collapsed Active Ride bar for a phone with [safeBottom].
  static double activeCollapsedTotal(double safeBottom) =>
      activeCollapsedHeight + math.max(safeBottom, activeBottomGap);

  /// Content of the middle Active Ride sheet: header, rider row and the
  /// slide action.
  static const double activeMiddleHeight = 232;

  /// Full middle Active Ride sheet for a phone with [safeBottom].
  static double activeMiddleTotal(double safeBottom) =>
      activeMiddleHeight + math.max(safeBottom, activeBottomGap);

  /// Panel position of the middle Active Ride sheet, between [collapsed]
  /// and [expanded] heights.
  static double activeSnapPoint({
    required double collapsed,
    required double middle,
    required double expanded,
  }) {
    final span = expanded - collapsed;
    if (span <= 0) { return 0.5; }
    return ((middle - collapsed) / span).clamp(0.08, 0.92);
  }
  static const double middleFraction = 0.46;
  static const double expandedFraction = 0.90;
  static const double springMass = 1.0;
  static const double springStiffness = 400;
  static const double springDampingRatio = 1.05;
  static const double flickVelocity = 240;

  static final SpringDescription spring = SpringDescription.withDampingRatio(
    mass: springMass,
    stiffness: springStiffness,
    ratio: springDampingRatio,
  );

  static double expandedHeight(double viewportHeight) =>
      viewportHeight * expandedFraction;

  static double middleHeight(double viewportHeight) =>
      viewportHeight * middleFraction;

  static double snapPoint({
    required double viewportHeight,
    double collapsed = collapsedHeight,
  }) {
    final maxH = expandedHeight(viewportHeight);
    final midH = middleHeight(viewportHeight);
    final span = maxH - collapsed;
    if (span <= 0) { return 0.5; }
    return ((midH - collapsed) / span).clamp(0.08, 0.92);
  }

  static double targetPosition({
    required double position,
    required double velocityPxPerSec,
    required double snap,
  }) {
    if (velocityPxPerSec < -flickVelocity) {
      return position < snap - 0.03 ? snap : 1.0;
    }
    if (velocityPxPerSec > flickVelocity) {
      return position > snap + 0.03 ? snap : 0.0;
    }

    final dCollapsed = position.abs();
    final dSnap = (position - snap).abs();
    final dExpanded = (1 - position).abs();
    if (dCollapsed <= dSnap && dCollapsed <= dExpanded) { return 0; }
    if (dSnap <= dExpanded) { return snap; }
    return 1;
  }

  static double notchDepthFor(double position) {
    const collapsed = 58.0;
    const expanded = 8.0;
    final t = position.clamp(0.0, 1.0);
    return collapsed + (expanded - collapsed) * t;
  }
}
