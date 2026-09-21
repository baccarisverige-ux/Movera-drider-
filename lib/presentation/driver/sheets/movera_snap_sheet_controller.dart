import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:movera/widgets/movera_sheet_metrics.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

/// Shared finger-follow + SpringSimulation snap for Home and Active Ride.
class MoveraSnapSheetController {
  MoveraSnapSheetController({
    required this.panel,
    required TickerProvider vsync,
  }) : _vsync = vsync;

  final PanelController panel;
  final TickerProvider _vsync;
  double rangePx = 1;
  AnimationController? _spring;

  double get position => panel.isAttached ? panel.panelPosition : 0;

  bool get isAttached => panel.isAttached;

  void stopSpring() {
    _spring?.dispose();
    _spring = null;
  }

  /// SlidingUpPanel still starts a 410ms decelerate fling when
  /// `panelSnapping` is false. Assigning position stops that controller
  /// so our spring owns the settle.
  void stopPanelAnimation() {
    if (!panel.isAttached) return;
    panel.panelPosition = panel.panelPosition.clamp(0.0, 1.0);
  }

  Future<void> springTo(
    double target, {
    double velocityPxPerSec = 0,
  }) async {
    if (!panel.isAttached) return;
    stopPanelAnimation();
    final start = panel.panelPosition;
    if ((start - target).abs() < 0.003) {
      panel.panelPosition = target;
      return;
    }

    stopSpring();
    final controller = AnimationController.unbounded(vsync: _vsync);
    _spring = controller;
    final velocity = rangePx <= 0 ? 0.0 : -velocityPxPerSec / rangePx;
    final simulation = SpringSimulation(
      MoveraSheetMetrics.spring,
      start,
      target,
      velocity,
    );
    controller.addListener(() {
      if (!panel.isAttached) return;
      panel.panelPosition = controller.value.clamp(0.0, 1.0);
    });
    try {
      await controller.animateWith(simulation);
    } finally {
      if (identical(_spring, controller)) {
        controller.dispose();
        _spring = null;
      }
    }
  }

  Future<void> snapToNearest({
    required double snapPoint,
    required double velocityPxPerSec,
  }) {
    final target = MoveraSheetMetrics.targetPosition(
      position: position,
      velocityPxPerSec: velocityPxPerSec,
      snap: snapPoint,
    );
    return springTo(target, velocityPxPerSec: velocityPxPerSec);
  }

  void dispose() => stopSpring();
}
