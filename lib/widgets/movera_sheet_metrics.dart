import 'package:flutter/physics.dart';

/// Shared snap geometry and spring for Home and Active Ride sheets.
class MoveraSheetMetrics {
  const MoveraSheetMetrics._();

  static const double collapsedHeight = 108;
  static const double activeCollapsedHeight = 148;
  static const double middleFraction = 0.46;
  static const double expandedFraction = 0.90;
  static const double springMass = 1.0;
  static const double springStiffness = 320;
  static const double springDamping = 32;
  static const double flickVelocity = 280;

  static final SpringDescription spring = SpringDescription(
    mass: springMass,
    stiffness: springStiffness,
    damping: springDamping,
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
    if (span <= 0) return 0.5;
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
    if (dCollapsed <= dSnap && dCollapsed <= dExpanded) return 0;
    if (dSnap <= dExpanded) return snap;
    return 1;
  }

  static double notchDepthFor(double position) {
    const collapsed = 58.0;
    const expanded = 8.0;
    final t = position.clamp(0.0, 1.0);
    return collapsed + (expanded - collapsed) * t;
  }
}
