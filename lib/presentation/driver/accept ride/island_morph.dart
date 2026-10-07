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
  List<_IslandLayer> _outgoing = [];

  double get _incomingOpacity =>
      _outgoing.isEmpty ? 1 : ((_phase - .15) / .85).clamp(0, 1);

  double get _phase => _motion.value.clamp(0.0, 1.0);
  Size get _visible => Size.lerp(_from, _to, _phase)!;

  void _settled(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        _outgoing.isNotEmpty &&
        mounted) {
      setState(() => _outgoing = []);
    }
  }

  @override
  void didUpdateWidget(IslandMorph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reducedMotion) {
      _motion.stop();
      _from = _to = widget.size;
      _outgoing = [];
      _motion.value = 1;
      return;
    }
    if (widget.size == _to && widget.face == oldWidget.face) return;
    final visible = _visible;
    final oldDelta = Size(_to.width - _from.width, _to.height - _from.height);
    final nextDelta = Size(
      widget.size.width - visible.width,
      widget.size.height - visible.height,
    );
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
    // Capture the opacity of every visible layer as well as its geometry.
    // A rapid new instruction must not flash an only-partly-visible face.
    final fade = (1 - _phase / .35).clamp(0.0, 1.0);
    final layers = [
      for (final layer in _outgoing)
        if (layer.opacity * fade > .01)
          _IslandLayer(layer.child, layer.size, layer.opacity * fade),
      if (_incomingOpacity > .01)
        _IslandLayer(oldWidget.child, oldWidget.size, _incomingOpacity),
    ];
    _motion.stop();
    _outgoing = layers;
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
            borderRadius: BorderRadius.circular(size.height / 2),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                if (t < .35)
                  for (final layer in _outgoing)
                    _face(
                      layer.child,
                      layer.size,
                      layer.opacity * (1 - t / .35).clamp(0, 1),
                      outgoing: true,
                    ),
                _face(widget.child, widget.size, _incomingOpacity),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _IslandLayer {
  const _IslandLayer(this.child, this.size, this.opacity);
  final Widget child;
  final Size size;
  final double opacity;
}
