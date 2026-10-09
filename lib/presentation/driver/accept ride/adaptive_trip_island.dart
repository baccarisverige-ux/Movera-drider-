import 'package:movera/widgets/owned_route_exit.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:movera/core/island/trip_island_controller.dart';

import 'island_waiting_motion.dart';

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
    this.paidSeconds,
    this.waitingAtStop = false,
    this.navigationStatus,
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
  final int? waitingSeconds, paidSeconds;
  final bool waitingAtStop;
  final String? navigationStatus;
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
  late final TripIslandController _controller;
  TripIslandInput get _input => TripIslandInput(
    status: widget.status,
    address: widget.address,
    waitingMessage: widget.waitingMessage,
    banner: widget.banner,
    arrival: widget.arrival,
    arrived: widget.arrived,
    waitingSeconds: widget.waitingSeconds,
    paidSeconds: widget.paidSeconds,
    paidWait: widget.paidWait,
    waitingAtStop: widget.waitingAtStop,
    navigationStatus: widget.navigationStatus,
  );
  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _controller = TripIslandController(_input)..addListener(_changed);
  }

  @override
  void didUpdateWidget(AdaptiveTripIsland oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.update(_input);
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _controller.dispose();
    super.dispose();
  }

  static const _blue = Color(0xFF58A6FF);
  static const _lavender = Color(0xFFBDA6F5);
  static const _muted = Color(0xFFB8C0CC);

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
        final presentation = _controller.face;
        final waiting =
            presentation.kind == TripIslandKind.waitingTimer ||
            presentation.kind == TripIslandKind.waitingMessage;
        final waitingMessage =
            presentation.kind == TripIslandKind.waitingMessage;
        final live = widget.banner;
        final title = presentation.title;
        final subtitle = presentation.subtitle;
        final accent = presentation.kind == TripIslandKind.status
            ? const Color(0xFFF2B86B)
            : waiting
            ? (widget.waitingAtStop ? const Color(0xFFF2B86B) : _lavender)
            : presentation.kind == TripIslandKind.arrival
            ? const Color(0xFFFF818B)
            : _blue;
        final scale = MediaQuery.textScalerOf(context);
        final heading = DefaultTextStyle.of(context).style.merge(
          TextStyle(
            color: Colors.white,
            fontSize: waiting ? (waitingMessage ? 12.5 : 18) : 12.5,
            fontWeight: FontWeight.w600,
            height: 1.05,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
        // Size follows measured text. Timer ticks reserve a fixed digit width.
        final measuredTitle = waiting && !waitingMessage
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
        final desired =
            math.max(
              measure(measuredTitle, heading),
              measure(subtitle, const TextStyle(fontSize: 9)),
            ) +
            84;
        final width = desired.clamp(minWidth, maximumWidth).toDouble();
        final size = Size(
          _controller.defaultFace
              ? math.min(available, TripIslandGeometry.width)
              : width,
          TripIslandGeometry.height,
        );
        final face = _controller.defaultFace
            ? 'default'
            : presentation.identity;
        return Align(
          alignment: Alignment.topCenter,
          heightFactor: 1,
          child: Listener(
            onPointerDown: (_) => _controller.hold(),
            onPointerUp: (_) => _controller.release(),
            onPointerCancel: (_) => _controller.release(),
            child: GestureDetector(
              onLongPress: waiting ? null : _showTools,
              child: IslandMorph(
                size: size,
                face: face,
                reducedMotion: MediaQuery.disableAnimationsOf(context),
                child: _controller.defaultFace
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
                                  SizedBox(
                                    width: 24,
                                    child: waiting
                                        ? Icon(
                                            Icons.timer_outlined,
                                            color: accent,
                                            size: 22,
                                          )
                                        : Tooltip(
                                            message: 'Trip route and options',
                                            child: InkWell(
                                              onTap: widget.onRoute,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: SizedBox(
                                                height: 28,
                                                child: Center(
                                                  child:
                                                      presentation.kind ==
                                                          TripIslandKind.status
                                                      ? Icon(
                                                          Icons
                                                              .info_outline_rounded,
                                                          color: accent,
                                                          size: 22,
                                                        )
                                                      : _cue(
                                                          presentation,
                                                          live,
                                                          accent,
                                                        ),
                                                ),
                                              ),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: waiting && !waitingMessage
                                        ? InkWell(
                                            key: const ValueKey(
                                              'island-waiting-timer',
                                            ),
                                            onTap: widget.onWait,
                                            child: _message(
                                              title,
                                              subtitle,
                                              heading,
                                              clock: true,
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
                                  // Symmetric slots keep text at the island's true center.
                                  const SizedBox(width: 6),
                                  const SizedBox(width: 24),
                                ],
                              ),
                            ),
                            const SizedBox(height: 1),
                            if (waiting)
                              IslandWaitingLane(color: accent)
                            else
                              _routeProgress(
                                accent,
                                presentation.kind != TripIslandKind.status,
                              ),
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

  Widget _message(
    String title,
    String subtitle,
    TextStyle heading, {
    bool clock = false,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      final scaler = MediaQuery.textScalerOf(context);
      final showSubtitle = subtitle.isNotEmpty && scaler.scale(1) <= 1.1;
      final titleHeight = constraints.maxHeight - (showSubtitle ? 10.5 : 0);
      // Geometry remains the default height, including large text settings.
      // Full copy remains available to screen readers and the tooltip.
      var fontSize = math.min(
        heading.fontSize!,
        titleHeight / (scaler.scale(1) * 1.05),
      );
      if (clock) {
        final metrics = TextPainter(
          text: TextSpan(
            text: title,
            style: heading.copyWith(fontSize: fontSize),
          ),
          textDirection: Directionality.of(context),
          textScaler: scaler,
        )..layout();
        if (metrics.width > constraints.maxWidth - 2) {
          fontSize *= math.max(0.0, constraints.maxWidth - 2) / metrics.width;
        }
      }
      return Semantics(
        label: [title, if (subtitle.isNotEmpty) subtitle].join(', '),
        excludeSemantics: true,
        child: Tooltip(
          message: [title, if (subtitle.isNotEmpty) subtitle].join(' · '),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (clock)
                IslandRollingClock(
                  text: title,
                  style: heading.copyWith(fontSize: fontSize),
                )
              else
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: heading.copyWith(fontSize: fontSize),
                ),
              if (showSubtitle) ...[
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
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

  Widget _cue(TripIslandFace face, NavigationBanner? live, Color accent) {
    final arrival = face.kind == TripIslandKind.arrival;
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
              Icons.location_on_rounded,
              color: Color(0xFFFF818B),
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
                color: accent,
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
              onTap: () => popOwned(context, 'route'),
            ),
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Safety toolkit'),
              onTap: () => popOwned(context, 'safety'),
            ),
            if (widget.radarVisible)
              ListTile(
                leading: const Icon(Icons.radar_rounded),
                title: Text(
                  widget.radarOn ? 'Turn radar off' : 'Turn radar on',
                ),
                onTap: () => popOwned(context, 'radar'),
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

  /// Route fraction belongs to the active leg. Waiting uses its own activity lane.
  Widget _routeProgress(Color accent, bool available) => Semantics(
    label: 'Route progress',
    value: available
        ? '${(widget.progress.clamp(0, 1) * 100).round()} percent'
        : 'Unavailable',
    child: TweenAnimationBuilder<double>(
      tween: Tween<double>(end: available ? widget.progress.clamp(0, 1) : 0),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 350),
      builder: (context, progress, _) => ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 3,
          color: accent,
          backgroundColor: const Color(0xFF353C46),
        ),
      ),
    ),
  );
}
