import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Owns only the capsule's motion, never trip state or the map camera.
/// Content is laid out at its destination size and clipped, never scaled.
class IslandMorph extends StatefulWidget {
  const IslandMorph({
    super.key,
    required this.size,
    required this.face,
    required this.child,
    this.reducedMotion = false,
  });

  final Size size;
  final Object face;
  final Widget child;
  final bool reducedMotion;

  @override
  State<IslandMorph> createState() => _IslandMorphState();
}

class _IslandMorphState extends State<IslandMorph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController.unbounded(
    vsync: this,
    value: 1,
  )..addStatusListener(_settled);
  late Size _from = widget.size;
  late Size _to = widget.size;
  Widget? _outgoing;
  Size? _outgoingSize;

  double get _phase => _motion.value.clamp(0.0, 1.0);
  Size get _visible => Size.lerp(_from, _to, _phase)!;

  void _settled(AnimationStatus status) {
    if (status == AnimationStatus.completed && _outgoing != null && mounted) {
      setState(() => _outgoing = null);
    }
  }

  @override
  void didUpdateWidget(IslandMorph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reducedMotion) {
      _motion.stop();
      _from = _to = widget.size;
      _outgoing = null;
      _motion.value = 1;
      return;
    }
    if (widget.size == _to && widget.face == oldWidget.face) return;
    final visible = _visible;
    final oldDelta = _to - _from;
    final nextDelta = widget.size - visible;
    final length =
        nextDelta.width * nextDelta.width + nextDelta.height * nextDelta.height;
    // Project the current geometric velocity onto the new target. Preserve
    // continuity without carrying excessive momentum into a short resize.
    final velocity = length < 1
        ? 0.0
        : ((_motion.velocity *
                      (oldDelta.width * nextDelta.width +
                          oldDelta.height * nextDelta.height)) /
                  length)
              .clamp(0.0, 3.0)
              .toDouble();
    _motion.stop();
    _outgoing = oldWidget.child;
    _outgoingSize = oldWidget.size;
    _from = visible;
    _to = widget.size;
    _motion.value = 0;
    _motion.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 225, damping: 30),
        0,
        1,
        velocity,
        tolerance: const Tolerance(distance: .001, velocity: .01),
      ),
    );
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  Widget _face(
    Widget child,
    Size size,
    double opacity, {
    bool outgoing = false,
  }) => Positioned.fill(
    child: IgnorePointer(
      ignoring: outgoing || opacity < .5,
      child: ExcludeSemantics(
        excluding: outgoing || opacity < .5,
        child: Opacity(
          opacity: opacity,
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minWidth: size.width,
            maxWidth: size.width,
            minHeight: size.height,
            maxHeight: size.height,
            child: SizedBox.fromSize(size: size, child: child),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _motion,
    builder: (context, _) {
      final size = _visible;
      final t = _phase;
      return RepaintBoundary(
        child: SizedBox(
          key: const ValueKey('island-morph-shell'),
          width: size.width,
          height: size.height,
          child: Material(
            color: const Color(0xFF111214),
            borderRadius: BorderRadius.circular(math.min(size.height / 2, 48)),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                if (_outgoing != null && t < .35)
                  _face(
                    _outgoing!,
                    _outgoingSize!,
                    (1 - t / .35).clamp(0, 1),
                    outgoing: true,
                  ),
                _face(
                  widget.child,
                  widget.size,
                  _outgoing == null ? 1 : ((t - .15) / .85).clamp(0, 1),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
