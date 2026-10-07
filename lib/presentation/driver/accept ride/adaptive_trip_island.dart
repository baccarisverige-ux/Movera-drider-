import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:movera/core/routing/route_instruction.dart';
import 'package:movera/presentation/driver/accept%20ride/navigation_instruction_banner.dart';
import 'package:movera/presentation/driver/accept%20ride/trip_island.dart';
import 'package:movera/presentation/driver/accept%20ride/island_morph.dart';

/// Trip information has one surface. Touch temporarily reveals the original
/// island; inactivity returns to the live face without changing trip state.
class AdaptiveTripIsland extends StatefulWidget {
  const AdaptiveTripIsland({
    super.key,
    this.banner,
    required this.status,
    required this.address,
    required this.detail,
    required this.eta,
    this.distance,
    this.arrival,
    this.arrived = false,
    required this.progress,
    this.waitingSeconds,
    required this.waitingMessage,
    this.paidWait = false,
    this.paidByCash = false,
    required this.lastTripLabel,
    this.radarVisible = false,
    this.radarOn = false,
    required this.onRadar,
    required this.onMenu,
    required this.onSearch,
    required this.onHistory,
    required this.onRoute,
    required this.onSafety,
    required this.onWait,
  });

  final NavigationBanner? banner;
  final String status, address, detail, eta, waitingMessage, lastTripLabel;
  final String? distance, arrival;
  final double progress;
  final int? waitingSeconds;
  final bool paidWait, paidByCash, arrived, radarVisible, radarOn;
  final VoidCallback onRadar,
      onMenu,
      onSearch,
      onHistory,
      onRoute,
      onSafety,
      onWait;

  @override
  State<AdaptiveTripIsland> createState() => _AdaptiveTripIslandState();
}

class _AdaptiveTripIslandState extends State<AdaptiveTripIsland> {
  Timer? _idle, _waitingCycle;
  bool _defaultFace = false, _waitingMessage = false;
  int _pointers = 0;

  @override
  void initState() {
    super.initState();
    _scheduleWaitingFace();
  }

  @override
  void didUpdateWidget(AdaptiveTripIsland oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.waitingSeconds == null) != (widget.waitingSeconds == null)) {
      _waitingMessage = false;
      _scheduleWaitingFace();
    }
  }

  void _scheduleWaitingFace() {
    _waitingCycle?.cancel();
    if (widget.waitingSeconds == null) {
      return;
    }
    // Eight seconds of timer, two seconds of rider status. GPS and timer
    // updates do not restart this cycle or interrupt the default face.
    _waitingCycle = Timer(Duration(seconds: _waitingMessage ? 2 : 8), () {
      if (!mounted) {
        return;
      }
      setState(() => _waitingMessage = !_waitingMessage);
      _scheduleWaitingFace();
    });
  }

  void _touch() {
    _idle?.cancel();
    if (!_defaultFace) {
      setState(() => _defaultFace = true);
    }
  }

  void _release() {
    _pointers = (_pointers - 1).clamp(0, 100);
    if (_pointers != 0) {
      return;
    }
    scheduleMicrotask(() {
      if (mounted) {
        _touch();
        _startIdle();
      }
    });
  }

  void _startIdle() {
    _idle?.cancel();
    _idle = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _defaultFace = false);
      }
    });
  }

  @override
  void dispose() {
    _idle?.cancel();
    _waitingCycle?.cancel();
    super.dispose();
  }

  static const _blue = Color(0xFF3785F6);
  static const _lavender = Color(0xFFD4B9EA);
  static const _muted = Color(0xFFC7C8CE);

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      12,
      MediaQuery.paddingOf(context).top + 8,
      12,
      0,
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final waiting = widget.waitingSeconds != null;
        final live = widget.banner;
        final title = waiting
            ? (_waitingMessage
                  ? widget.waitingMessage
                  : _clock(widget.waitingSeconds!))
            : widget.arrival != null
            ? (widget.arrived
                  ? 'At ${widget.arrival!.toLowerCase()}'
                  : 'Arriving soon')
            : live?.primary ?? widget.status;
        final subtitle = waiting
            ? (_waitingMessage
                  ? ''
                  : widget.paidWait
                  ? 'Paid waiting'
                  : 'Waiting time')
            : widget.arrival != null
            ? widget.address
            : [
                if ((live?.distanceLabel.isNotEmpty ?? false) &&
                    !title.contains(live!.distanceLabel))
                  live.distanceLabel,
                if (live?.roadName?.isNotEmpty ?? false) live!.roadName!,
              ].join(' · ');
        final scale = MediaQuery.textScalerOf(context);
        final heading = DefaultTextStyle.of(context).style.merge(
          TextStyle(
            color: Colors.white,
            fontSize: waiting ? (_waitingMessage ? 14 : 20) : 12.5,
            fontWeight: FontWeight.w600,
            height: 1.05,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
        // Size follows measured text. Timer ticks reserve a fixed digit width.
        final measuredTitle = waiting && !_waitingMessage
            ? '${'8' * math.max(2, (widget.waitingSeconds! ~/ 60).toString().length)}:88'
            : title;
        double measure(String text, TextStyle style) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: Directionality.of(context),
            textScaler: scale,
          )..layout();
          return painter.width;
        }

        final maximumWidth = math.min(
          available,
          TripIslandGeometry.maximumWidth,
        );
        final minWidth = math.min(maximumWidth, TripIslandGeometry.width);
        final contentInset = widget.arrival != null && !waiting ? 82.0 : 58.0;
        final desired = measure(measuredTitle, heading) + contentInset + 4;
        final width = desired.clamp(minWidth, maximumWidth).toDouble();
        final size = Size(
          _defaultFace ? math.min(available, TripIslandGeometry.width) : width,
          TripIslandGeometry.height,
        );
        final face = _defaultFace
            ? 'default'
            : waiting
            ? (_waitingMessage ? 'waiting-message' : 'waiting-timer')
            : widget.arrival != null
            ? 'arrival'
            : 'guidance-${live?.symbol.name ?? 'overview'}-${live?.roadName}-${live?.exitNumber}';
        return Align(
          alignment: Alignment.topCenter,
          heightFactor: 1,
          child: Listener(
            onPointerDown: (_) {
              _pointers++;
              _idle?.cancel();
            },
            onPointerUp: (_) => _release(),
            onPointerCancel: (_) => _release(),
            child: GestureDetector(
              onLongPress: waiting ? null : _showTools,
              child: IslandMorph(
                size: size,
                face: face,
                reducedMotion: MediaQuery.disableAnimationsOf(context),
                child: _defaultFace
                    ? TripIsland(
                        key: const ValueKey('trip-default-island'),
                        lastTripLabel: widget.lastTripLabel,
                        onMenu: widget.onMenu,
                        onSearch: widget.onSearch,
                        onHistory: widget.onHistory,
                      )
                    : Padding(
                        key: ValueKey(
                          waiting
                              ? 'trip-waiting-island'
                              : 'trip-guidance-island',
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 3,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  if (waiting)
                                    _cue(waiting, live)
                                  else
                                    Tooltip(
                                      message: 'Trip route and options',
                                      child: InkWell(
                                        onTap: widget.onRoute,
                                        borderRadius: BorderRadius.circular(22),
                                        child: SizedBox(
                                          width: 28,
                                          height: 26,
                                          child: Center(
                                            child: _cue(false, live),
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: waiting && !_waitingMessage
                                        ? InkWell(
                                            key: const ValueKey(
                                              'island-waiting-timer',
                                            ),
                                            onTap: widget.onWait,
                                            child: _message(
                                              title,
                                              subtitle,
                                              heading,
                                            ),
                                          )
                                        : KeyedSubtree(
                                            key: waiting
                                                ? const ValueKey(
                                                    'island-waiting-name',
                                                  )
                                                : null,
                                            child: _message(
                                              title,
                                              subtitle,
                                              heading,
                                            ),
                                          ),
                                  ),
                                  if (widget.arrival != null && !waiting) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.location_on_rounded,
                                      color: Color(0xFFF05B60),
                                      size: 20,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (!waiting) ...[
                              const SizedBox(height: 1),
                              _routeProgress(),
                            ],
                          ],
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _message(String title, String subtitle, TextStyle heading) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final scaler = MediaQuery.textScalerOf(context);
          final showSubtitle = subtitle.isNotEmpty && scaler.scale(1) <= 1.1;
          final titleHeight = constraints.maxHeight - (showSubtitle ? 10.5 : 0);
          // Geometry remains the default height, including large text settings.
          // Full copy remains available to screen readers and the tooltip.
          final fontSize = math.min(
            heading.fontSize!,
            titleHeight / (scaler.scale(1) * 1.05),
          );
          return Semantics(
            label: [title, if (subtitle.isNotEmpty) subtitle].join(', '),
            excludeSemantics: true,
            child: Tooltip(
              message: [title, if (subtitle.isNotEmpty) subtitle].join(' · '),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: heading.copyWith(fontSize: fontSize),
                  ),
                  if (showSubtitle) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 9,
                        height: 1.05,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );

  Widget _cue(bool waiting, NavigationBanner? live) {
    if (waiting) {
      return const Icon(Icons.timer_outlined, color: _lavender, size: 22);
    }
    final arrival = widget.arrival != null;
    final exit =
        live?.exitNumber ??
        RegExp(
          r'exit\s+(\d+)',
          caseSensitive: false,
        ).firstMatch(live?.primary ?? '')?.group(1);
    return Semantics(
      label: arrival
          ? 'Arrival'
          : '${live?.symbol.name ?? 'To destination'}${exit == null ? '' : ', exit $exit'}',
      child: arrival
          ? const Icon(
              Icons.directions_walk_rounded,
              color: Colors.white,
              size: 24,
            )
          : live == null
          ? const Icon(
              Icons.person_outline_rounded,
              color: Colors.white,
              size: 24,
            )
          : CustomPaint(
              size: const Size(24, 24),
              painter: NavigationCuePainter(
                symbol: live.symbol,
                icon: Icons.navigation_rounded,
                color: _blue,
                exitNumber: exit,
                exitAngleDegrees: live.exitAngleDegrees,
                fontFamily: DefaultTextStyle.of(context).style.fontFamily,
              ),
            ),
    );
  }

  Future<void> _showTools() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.alt_route_rounded),
              title: const Text('Trip route and options'),
              onTap: () => Navigator.pop(context, 'route'),
            ),
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Safety toolkit'),
              onTap: () => Navigator.pop(context, 'safety'),
            ),
            if (widget.radarVisible)
              ListTile(
                leading: const Icon(Icons.radar_rounded),
                title: Text(
                  widget.radarOn ? 'Turn radar off' : 'Turn radar on',
                ),
                onTap: () => Navigator.pop(context, 'radar'),
              ),
            ListTile(
              leading: Icon(
                widget.paidByCash
                    ? Icons.payments_rounded
                    : Icons.credit_card_rounded,
              ),
              title: Text(
                widget.paidByCash ? 'Cash: collect in the car' : 'Paid by card',
              ),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'route':
        widget.onRoute();
      case 'safety':
        widget.onSafety();
      case 'radar':
        widget.onRadar();
    }
  }

  /// Progress occupies one slim row. The maneuver is also the route button;
  /// secondary tools use a menu so they do not dictate capsule height.
  Widget _routeProgress() => Row(
    children: [
      SizedBox(
        width: 26,
        child: Text(
          '${(widget.progress.clamp(0, 1) * 100).round()}%',
          style: const TextStyle(
            color: _muted,
            fontSize: 7,
            height: 1,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
      Expanded(
        child: Semantics(
          label: 'Route progress',
          value: '${(widget.progress.clamp(0, 1) * 100).round()} percent',
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: widget.progress.clamp(0, 1)),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 350),
            builder: (context, progress, _) => SizedBox(
              height: 8,
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 2,
                          color: _blue,
                          backgroundColor: const Color(0xFF40434A),
                        ),
                      ),
                    ),
                    Positioned(
                      left: (constraints.maxWidth - 8) * progress,
                      bottom: 0,
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: _blue,
                        size: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  static String _clock(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
}
