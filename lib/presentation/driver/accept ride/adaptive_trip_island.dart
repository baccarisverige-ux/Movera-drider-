import 'dart:async';

import 'package:flutter/material.dart';
import 'package:movera/core/routing/route_instruction.dart';
import 'package:movera/presentation/driver/accept%20ride/navigation_instruction_banner.dart';
import 'package:movera/presentation/driver/accept%20ride/trip_island.dart';

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

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final duration = reduced
        ? Duration.zero
        : const Duration(milliseconds: 360);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        MediaQuery.paddingOf(context).top + 8,
        12,
        0,
      ),
      child: Listener(
        onPointerDown: (_) {
          _pointers++;
          _idle?.cancel();
        },
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _release(),
        child: AnimatedSize(
          duration: duration,
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: duration,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [
                ...previous.map(
                  (child) =>
                      Positioned.fill(child: IgnorePointer(child: child)),
                ),
                ?current,
              ],
            ),
            child: _defaultFace
                ? TripIsland(
                    key: const ValueKey('trip-default-island'),
                    lastTripLabel: widget.lastTripLabel,
                    onMenu: widget.onMenu,
                    onSearch: widget.onSearch,
                    onHistory: widget.onHistory,
                  )
                : Material(
                    key: ValueKey(
                      widget.waitingSeconds == null
                          ? 'trip-guidance-island'
                          : 'trip-waiting-island',
                    ),
                    color: const Color(0xFF050505),
                    borderRadius: BorderRadius.circular(32),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          widget.waitingSeconds == null
                              ? _guidance()
                              : _waiting(duration),
                          const SizedBox(height: 8),
                          _routeRow(),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _guidance() {
    final live = widget.banner;
    final symbol = widget.arrival != null
        ? NavigationBannerSymbol.arrive
        : live?.symbol;
    final exit = RegExp(
      r'exit\s+(\d+)',
      caseSensitive: false,
    ).firstMatch(live?.primary ?? '')?.group(1);
    return Row(
      children: [
        Semantics(
          label:
              '${symbol?.name ?? 'Direction'}${exit == null ? '' : ', exit $exit'}',
          child: Container(
            width: 54,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF132D27),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomPaint(
                  size: const Size(34, 37),
                  painter: NavigationCuePainter(
                    symbol: symbol,
                    icon: Icons.near_me_outlined,
                    color: const Color(0xFF54D8AC),
                  ),
                ),
                if (exit != null)
                  Text(
                    exit,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.arrival ?? live?.primary ?? widget.status,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  if (live != null && live.distanceLabel.isNotEmpty)
                    live.distanceLabel,
                  if (widget.arrived)
                    'Arrived'
                  else if (live?.roadName?.isNotEmpty ?? false)
                    live!.roadName!
                  else
                    widget.detail,
                ].where((text) => text.isNotEmpty).join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFC3CAC7), fontSize: 12),
              ),
              if (widget.status.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    widget.status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF54D8AC),
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _waiting(Duration duration) => SizedBox(
    height: 64,
    child: Center(
      child: AnimatedSwitcher(
        duration: duration,
        child: _waitingMessage
            ? Text(
                widget.waitingMessage,
                key: const ValueKey('island-waiting-name'),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              )
            : InkWell(
                key: const ValueKey('island-waiting-timer'),
                onTap: widget.onWait,
                borderRadius: BorderRadius.circular(32),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF132D27),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: Color(0xFF54D8AC),
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _clock(widget.waitingSeconds!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            widget.paidWait ? 'Paid waiting' : 'Waiting time',
                            style: const TextStyle(
                              color: Color(0xFF54D8AC),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    ),
  );

  Widget _routeRow() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (widget.waitingSeconds == null && widget.address.isNotEmpty)
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: Color(0xFF54D8AC),
              size: 16,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFC3CAC7), fontSize: 12),
              ),
            ),
          ],
        ),
      if (widget.waitingSeconds == null)
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Row(
            children: [
              const Icon(
                Icons.navigation_rounded,
                color: Color(0xFF559EF0),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: widget.progress.clamp(0, 1),
                    minHeight: 3,
                    color: const Color(0xFF559EF0),
                    backgroundColor: const Color(0xFF38403D),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                [
                  widget.eta,
                  if (widget.distance != null) widget.distance!,
                ].join(' · '),
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
        ),
      Row(
        children: [
          _button(
            'Trip route and options',
            Icons.alt_route_rounded,
            widget.onRoute,
          ),
          _button('Safety toolkit', Icons.shield_outlined, widget.onSafety),
          Tooltip(
            message: widget.paidByCash
                ? 'Cash: collect in the car'
                : 'Paid by card',
            child: Icon(
              widget.paidByCash
                  ? Icons.payments_rounded
                  : Icons.credit_card_rounded,
              size: 18,
              color: const Color(0xFFC3CAC7),
            ),
          ),
          const Spacer(),
          if (widget.radarVisible)
            _button(
              widget.radarOn ? 'Turn radar off' : 'Turn radar on',
              Icons.radar_rounded,
              widget.onRadar,
              active: widget.radarOn,
            ),
        ],
      ),
    ],
  );

  Widget _button(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool active = false,
  }) => IconButton(
    tooltip: label,
    onPressed: onTap,
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    icon: Icon(
      icon,
      size: 20,
      color: active ? const Color(0xFF54D8AC) : Colors.white,
    ),
  );

  static String _clock(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
}
