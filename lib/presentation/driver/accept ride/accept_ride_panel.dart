part of 'accept_ride.dart';

// Sheet, panel, and rider-contact presentation for AcceptRide.
// Trip lifecycle stays in the trip extension. This file does not change geometry.

extension _AcceptRidePanel on _AcceptRideState {
    void _setMapGesturesBlocked(bool value) {
      if (!mounted || _blockMapGestures == value) { return; }
      _rebuild(() {
        _blockMapGestures = value;
      });
    }
    Widget _mapOverlay({required Widget child}) {
      return PointerInterceptor(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => _setMapGesturesBlocked(true),
          onPointerUp: (_) => _setMapGesturesBlocked(false),
          onPointerCancel: (_) => _setMapGesturesBlocked(false),
          child: child,
        ),
      );
    }
    void _onRideSheetPointerDown(PointerDownEvent event) {
      _sheetTrace.down();
      _ridePointerActive = true;
      _ridePointerLastY = event.position.dy;
      _ridePointerLastMs = DateTime.now().millisecondsSinceEpoch;
      _ridePointerVelocity = 0;
      _snapSheet.stopSpring();
      _setMapGesturesBlocked(true);
    }
    void _onRideSheetPointerMove(PointerEvent event) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (_ridePointerLastMs != 0) {
        final dt = math.max(1, now - _ridePointerLastMs);
        _ridePointerVelocity =
            (event.position.dy - _ridePointerLastY) / dt * 1000;
      }
      _ridePointerLastY = event.position.dy;
      _ridePointerLastMs = now;
    }
    void _onRideSheetPointerEnd(PointerEvent event) {
      _sheetTrace.up(_ridePointerVelocity);
      _onRideSheetPointerMove(event);
      _ridePointerActive = false;
      _scheduleRideSheetPositionGuard(
        delay: const Duration(milliseconds: 460),
      );
    }
    void _scheduleRideSheetPositionGuard({
      Duration delay = const Duration(milliseconds: 180),
    }) {
      _rideSheetPositionGuardTimer?.cancel();
      _rideSheetPositionGuardTimer = Timer(delay, () {
        if (!mounted ||
            _ridePointerActive ||
            !_ridePanelController.isAttached) {
          return;
        }

        final viewport = MediaQuery.sizeOf(context).height;
        final collapsed = MoveraSheetMetrics.activeCollapsedHeight +
            MediaQuery.paddingOf(context).bottom;
        final snap = MoveraSheetMetrics.snapPoint(
          viewportHeight: viewport,
          collapsed: collapsed,
        );
        final position = _ridePanelController.panelPosition.clamp(0.0, 1.0);
        final nearestDistance = math.min(
          position.abs(),
          math.min((position - snap).abs(), (1 - position).abs()),
        );
        if (nearestDistance <= 0.025) { return; }
        unawaited(_snapRideSheet(velocity: 0));
      });
    }
    double _rideExpandedHeight(BuildContext context) {
      final viewport = MediaQuery.sizeOf(context).height;
      final collapsed = MoveraSheetMetrics.activeCollapsedHeight +
          MediaQuery.paddingOf(context).bottom;
      final bannerReserve = MediaQuery.paddingOf(context).top + 130;
      return math.min(
        MoveraSheetMetrics.expandedHeight(viewport),
        math.max(collapsed + 160, viewport - bannerReserve),
      );
    }
    Future<void> _snapRideSheet({double? velocity}) async {
      if (!_ridePanelController.isAttached) { return; }
      final viewport = MediaQuery.sizeOf(context).height;
      final collapsed = MoveraSheetMetrics.activeCollapsedHeight +
          MediaQuery.paddingOf(context).bottom;
      _snapSheet.rangePx = _rideExpandedHeight(context) - collapsed;
      await _snapSheet.snapToNearest(
        snapPoint: MoveraSheetMetrics.snapPoint(
          viewportHeight: viewport,
          collapsed: collapsed,
        ),
        velocityPxPerSec: velocity ?? _ridePointerVelocity,
      );
    }
    Widget _buildIncomingRideCard() {
      final offer = _nextTripRadarOffer;
      if (offer == null) { return const SizedBox.shrink(); }
      const alertCoral = Color(0xFFFF765C);

      return Material(
        key: const ValueKey<String>('on-trip-radar-offer-button'),
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: alertCoral.withValues(alpha: 0.55), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: alertCoral.withValues(alpha: 0.12),
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: const Color(0xFF11181C).withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EEF1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      offer.category,
                      style: const TextStyle(
                        color: _AcceptRideState._ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (widget.destinationModeActive) ...[
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: _AcceptRideState._ink,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Text(
                        'On your way',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 7),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                      decoration: BoxDecoration(
                        color: alertCoral.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Text(
                        'After this drop-off',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFB84F3D),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      offer.fare,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AcceptRideState._ink,
                        fontSize: 30,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.9,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const MoveraLineIcon(
                    mark: MoveraMark.star,
                    color: Color(0xFFD7A02C),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    offer.rating.toStringAsFixed(2),
                    style: const TextStyle(
                      color: Color(0xFF6F7B82),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Text(
                'Available after your current drop-off',
                style: TextStyle(
                  color: _AcceptRideState._muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                key: ValueKey<String>('on-trip-offer-${offer.id}'),
                tween: Tween<double>(begin: 1, end: 0),
                duration: _AcceptRideState._onTripOfferLifetime,
                builder: (context, remaining, _) {
                  final seconds =
                      (remaining * (_AcceptRideState._onTripOfferLifetime.inMilliseconds / 1000))
                          .ceil();
                  return Column(
                    children: [
                      Row(
                        children: [
                          const MoveraLineIcon(
                            mark: MoveraMark.timer,
                            color: _AcceptRideState._ink,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Exclusive offer · ${seconds}s',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _AcceptRideState._ink,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'On this ride',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF8A9499),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          value: remaining,
                          backgroundColor: const Color(0xFFF0E8E5),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(alertCoral),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE4E8EA)),
              const SizedBox(height: 11),
              _offerLocationRow(
                color: const Color(0xFF215277),
                title: '${offer.pickupMinutes} min away',
                subtitle: offer.pickup,
              ),
              const SizedBox(height: 9),
              _offerLocationRow(
                color: _AcceptRideState._ink,
                title: '${offer.tripMinutes} min trip',
                subtitle: offer.dropoff,
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey<String>('on-trip-radar-deny'),
                      onPressed: _AcceptRideTrip(this)._denyNextTripRadar,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _AcceptRideState._ink,
                        side: const BorderSide(color: Color(0xFFD5DCDF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        minimumSize: const Size(0, 42),
                      ),
                      child: const Text(
                        'Deny',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey<String>('on-trip-radar-match-next'),
                      onPressed: _AcceptRideTrip(this)._acceptNextTripRadar,
                      style: FilledButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF252E3A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        minimumSize: const Size(0, 42),
                      ),
                      child: const Text(
                        'Accept',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    Widget _offerLocationRow({
      required Color color,
      required String title,
      required String subtitle,
    }) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2.5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AcceptRideState._ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AcceptRideState._muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    Widget _buildSecuredNextTripDetails() {
      final offer = _nextTripRadarOffer;
      if (_stage != ActiveRideStage.onTrip ||
          _onTripRadarState != _OnTripRadarState.secured ||
          offer == null) {
        return const SizedBox.shrink();
      }

      return Container(
        key: const ValueKey<String>('secured-next-trip-details'),
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAF9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDDE8E3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Next trip secured',
                    style: TextStyle(
                      color: _AcceptRideState._ink,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  offer.fare,
                  style: const TextStyle(
                    color: _AcceptRideState._ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            _nextTripLocationRow(
              color: _AcceptRideState._green,
              label: 'Pickup · ${offer.pickupMinutes} min',
              address: offer.pickup,
            ),
            const SizedBox(height: 9),
            _nextTripLocationRow(
              color: _AcceptRideState._ink,
              label: 'Drop-off · ${offer.tripMinutes} min trip',
              address: offer.dropoff,
            ),
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${offer.category} · ${offer.riderName}',
                    style: const TextStyle(
                      color: _AcceptRideState._muted,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  key: const ValueKey<String>('next-trip-waybill'),
                  onPressed: () {
                    final record = _waybills.next;
                    if (record != null) {
                      showMoveraWaybillSheet(
                        context,
                        record,
                        title: 'Next trip waybill',
                      );
                    }
                  },
                  icon: const MoveraLineIcon(
                    mark: MoveraMark.receipt,
                    size: 15,
                    color: Color(0xFF1C242C),
                  ),
                  label: const Text('Waybill'),
                  style: TextButton.styleFrom(
                    foregroundColor: _AcceptRideState._ink,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    Widget _nextTripLocationRow({
      required Color color,
      required String label,
      required String address,
    }) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _AcceptRideState._muted,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: const TextStyle(
                    color: _AcceptRideState._ink,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    void _openWaitingTime() {
      if (!_countingWait) { return; }
      showWaitingTimeSheet(
        context,
        readSeconds: () => _waitSeconds,
        fullyPaid: _paidStopWait,
        onNoShow: _paidStopWait
            ? null
            : () {
                if (_waitSeconds < 300 || !mounted) { return; }
                _AcceptRideTrip(this)._confirmCancellationReason(_AcceptRideState._noShowReason);
              },
      );
    }
    Widget _buildNavigationCard() {
      final onTrip = _stage == ActiveRideStage.onTrip;
      final waiting = _stage == ActiveRideStage.waitingForRider;
      final title = waiting
          ? 'Pickup'
          : onTrip
              ? 'Drop-off'
              : 'Heading to pickup';

      return NavigationInstructionBanner(
        etaLabel: waiting ? _waitLabel : _routeEtaText,
        eyebrow: _nextStopEyebrow,
        title: title,
        detail: _nextStopDetail,
        address: _nextStopAddress,
        icon: waiting
            ? Icons.location_on_outlined
            : onTrip
                ? Icons.flag_outlined
                : Icons.near_me_outlined,
        radarSwitch: onTrip,
        radarOn: _onTripRadarOn,
        onRadarToggle: _AcceptRideTrip(this)._toggleOnTripRadar,
        waitSeconds: waiting ? _waitSeconds : null,
        onWaitTap: _openWaitingTime,
      );
    }
    Widget _buildMapControls() {
      return Column(
        children: [
          Text(_freshRadarLocation ? 'Demo Radar' : 'Demo Radar — live location unavailable/stale', style: const TextStyle(fontSize: 10)),
          _mapCircleButton(
            icon: Icons.my_location_rounded,
            onTap: () {
              _navigation.resumeFollow();
              unawaited(_AcceptRideTrip(this)._followVehicle(force: true));
            },
          ),
          const SizedBox(height: 9),
          _mapCircleButton(
            icon: Icons.shield_outlined,
            accent: _AcceptRideState._green,
            onTap: () => showSafetyToolKitSheet(context),
          ),
          const SizedBox(height: 9),
          const PreviewUnavailable(label: 'Map layers', child: Icon(Icons.layers_outlined, color: Colors.grey)),
        ],
      );
    }
    Widget _mapCircleButton({
      required IconData icon,
      required VoidCallback onTap,
      Color accent = _AcceptRideState._ink,
    }) {
      return Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: const Color(0xFF172027).withValues(alpha: 0.16),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            height: 44,
            width: 44,
            child: Icon(icon, color: accent, size: 20),
          ),
        ),
      );
    }
    Widget _buildRidePanel() {
      return ValueListenableBuilder<double>(
        valueListenable: _ridePanelPosition,
        builder: (context, pos, _) {
          final compact = pos < 0.14;
          return Container(
            key: const ValueKey<String>('active-ride-panel'),
            decoration: BoxDecoration(
              color: _AcceptRideState._panel,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border(top: BorderSide(color: _AcceptRideState._line)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF172027).withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8DEDF),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                  KeyedSubtree(
                    key: ValueKey<String>('active-ride-panel-${_stage.name}'),
                    child: const SizedBox.shrink(),
                  ),
                  if (compact)
                    CompactTripDock(
                      key: const ValueKey<String>('active-ride-compact-dock'),
                      pickupAddress: widget.pickupAddress,
                      dropoffAddress: widget.dropoffAddress,
                      stopAddresses: widget.stopAddresses,
                      etaLabel: _countingWait ? _waitLabel : _routeEtaText,
                      stageLabel: switch (_stage) {
                        ActiveRideStage.headingToPickup => 'PICKUP',
                        ActiveRideStage.waitingForRider => 'WAITING',
                        ActiveRideStage.onTrip =>
                          _paidStopWait ? 'STOP WAIT' : 'ON TRIP',
                      },
                      onArrived: _arrivalTarget != null ? _AcceptRideTrip(this)._onArrivedTap : null,
                      arrivedEnabled: _nearArrivalTarget,
                      onArrivedBlocked: _AcceptRideTrip(this)._blockedArrival,
                      riderReply: _riderOnTheWay ? 'RIDER ON THE WAY' : null,
                      onWaitTap: _countingWait ? _openWaitingTime : null,
                      riderName: widget.riderName,
                      onCall: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              RiderContactPolicy.unavailableMessage,
                            ),
                            backgroundColor: _AcceptRideState._ink,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        );
                      },
                      onMessage: () {
                        Navigator.push(
                          context,
                          BottomToTopTransition(
                            Chat(riderDisplayName: widget.riderName),
                          ),
                        );
                      },
                    )
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        key: const PageStorageKey<String>('active-ride-scroll'),
                        padding: const EdgeInsets.fromLTRB(16, 13, 16, 10),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _stagePill(),
                                      const SizedBox(height: 8),
                                      Text(
                                        _title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: _AcceptRideState._ink,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.55,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _subtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: _AcceptRideState._muted,
                                          fontSize: 10.5,
                                          height: 1.35,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      _liveStatus(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _buildJourneyDetailsCard(),
                            const SizedBox(height: 12),
                            _buildRiderRow(),
                            const SizedBox(height: 10),
                            _buildCurrentWaybillShortcut(),
                            if (_stage == ActiveRideStage.onTrip)
                              _buildSecuredNextTripDetails(),
                          ],
                        ),
                      ),
                    ),
                  if (compact) const Spacer(),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Color(0xFFF0F2F3)),
                      ),
                    ),
                    child: _buildPrimaryAction(),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
    Widget _buildJourneyDetailsCard() {
      return Container(
        key: const ValueKey<String>('active-ride-journey-card'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 16, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE6E8EA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pickup to drop-off',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _AcceptRideState._ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.stopAddresses.isEmpty
                      ? 'Direct'
                      : '${widget.stopAddresses.length} stop${widget.stopAddresses.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: _AcceptRideState._muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _journeyPoint(
              asset: 'assets/icons/movera_pin.svg',
              label: 'Pickup',
              address: widget.pickupAddress,
              isLast: false,
            ),
            for (var i = 0; i < widget.stopAddresses.length; i++)
              _journeyPoint(
                asset: 'assets/icons/movera_stop.svg',
                label: 'Stop ${i + 1}',
                address: widget.stopAddresses[i],
                isLast: false,
              ),
            _journeyPoint(
              asset: 'assets/icons/movera_flag.svg',
              label: 'Drop-off',
              address: widget.dropoffAddress,
              isLast: true,
            ),
            const Padding(
              padding: EdgeInsets.only(top: 12, bottom: 10),
              child: Divider(height: 1, color: Color(0xFFEEF0F1)),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.fare == '—'
                        ? widget.category
                        : '${widget.category} · ${widget.fare}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _AcceptRideState._ink,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    Widget _journeyPoint({
      required String asset,
      required String label,
      required String address,
      required bool isLast,
    }) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4F5F6),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      asset,
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        _AcceptRideState._ink,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 1.5,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        color: const Color(0xFFD5D8DB),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: _AcceptRideState._muted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.35,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AcceptRideState._ink,
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    Widget _stagePill() {
      final label = switch (_stage) {
        ActiveRideStage.headingToPickup => 'PICKUP',
        ActiveRideStage.waitingForRider => 'WAITING',
        ActiveRideStage.onTrip => 'ON TRIP',
      };

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE4E6E8)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: _AcceptRideState._ink,
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
      );
    }
    Widget _liveStatus() {
      final text = _hasLiveLocation
          ? (_routeLoading
              ? 'Live GPS · updating road route'
              : 'Live GPS · road route active')
          : (_locationStatus ?? 'Locating driver…');

      return Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _hasLiveLocation ? _AcceptRideState._green : const Color(0xFF9AA4A9),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _AcceptRideState._muted,
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    }
    Widget _buildRiderRow() {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: const Color(0xFFE6E8EA)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE6E8EA)),
              ),
              child: const CircleAvatar(
                backgroundImage: AssetImage(AppAssets.profileImg),
                backgroundColor: Color(0xFFE9EEEC),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: _showRiderProfile,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.riderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _AcceptRideState._ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${widget.riderRating.toStringAsFixed(1)} ★ · ${widget.riderTrips} rides',
                        style: const TextStyle(
                          color: _AcceptRideState._muted,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    Widget _buildCurrentWaybillShortcut() {
      return ValueListenableBuilder<WaybillRecord?>(
        valueListenable: _waybills.currentListenable,
        builder: (context, record, _) {
          if (record == null) { return const SizedBox.shrink(); }

          return Material(
            key: const ValueKey<String>('current-waybill-shortcut'),
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                showMoveraWaybillSheet(
                  context,
                  record,
                  title: 'Current trip waybill',
                );
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE6E8EA)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F5F6),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: _AcceptRideState._ink,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current waybill',
                            style: TextStyle(
                              color: _AcceptRideState._ink,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${record.service} · ${record.fare} · ${record.tripId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _AcceptRideState._muted,
                              fontSize: 8.8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF98A3A8),
                      size: 19,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
    Widget _buildPrimaryAction() {
      final accent = switch (_stage) {
        ActiveRideStage.headingToPickup => const Color(0xFF1C242C),
        ActiveRideStage.waitingForRider => const Color(0xFF146B45),
        ActiveRideStage.onTrip => const Color(0xFF1B3F6F),
      };

      return Column(
        children: [
          if (_arrivalTarget != null) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                key: const ValueKey<String>('active-ride-arrived-button'),
                onPressed: _nearArrivalTarget ? _AcceptRideTrip(this)._onArrivedTap : _AcceptRideTrip(this)._blockedArrival,
                style: FilledButton.styleFrom(
                  elevation: 0,
                  backgroundColor:
                      _nearArrivalTarget ? _AcceptRideState._ink : const Color(0xFFE6E8EA),
                  foregroundColor:
                      _nearArrivalTarget ? Colors.white : const Color(0xFF98A1A6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "I've arrived",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
        children: [
          Material(
            key: const ValueKey<String>('active-ride-trip-options'),
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(19),
            child: InkWell(
              onTap: _showTripOptions,
              borderRadius: BorderRadius.circular(19),
              child: Container(
                height: 62,
                width: 62,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF8FAF9),
                      Color(0xFFEEF3F1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: const Color(0xFFE1E8E5)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF18392E).withValues(alpha: 0.07),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/icons/movera_route.svg',
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF33423C),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SlideRideAction(
              key: const ValueKey<String>('active-ride-slide-action'),
              semanticsKey:
                  const ValueKey<String>('active-ride-primary-action'),
              label: _slideLabel,
              confirmedLabel: _slideConfirmedLabel,
              iconAsset: switch (_stage) {
                ActiveRideStage.headingToPickup =>
                  'assets/icons/movera_pin.svg',
                ActiveRideStage.waitingForRider =>
                  'assets/icons/movera_navigation.svg',
                ActiveRideStage.onTrip =>
                  'assets/icons/movera_flag.svg',
              },
              accent: accent,
              onConfirmed: () async {
                _setMapGesturesBlocked(false);
                if (_stage == ActiveRideStage.headingToPickup ||
                    (_stage == ActiveRideStage.onTrip &&
                     !_paidStopWait &&
                     _stopCursor < widget.stopAddresses.length)) {
                  await _AcceptRideTrip(this)._onArrivedTap();
                } else {
                  await _AcceptRideTrip(this)._advanceRide();
                }
              },
            ),
          ),
        ],
          ),
        ],
      );
    }
    Future<void> _showRiderProfile() async {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        builder: (sheetContext) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F9F8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 34,
                      backgroundImage: AssetImage(AppAssets.profileImg),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.riderName,
                      style: const TextStyle(
                        color: _AcceptRideState._ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${widget.riderRating.toStringAsFixed(1)} ★ · '
                      '${widget.riderTrips} rides',
                      style: const TextStyle(
                        color: _AcceptRideState._muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _AcceptRideState._line),
                      ),
                      child: const Text(
                        'Rider details from the booking will appear here when the backend profile is connected.',
                        style: TextStyle(
                          color: _AcceptRideState._muted,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
    Future<void> _showTripOptions() async {
      await showMoveraModalSheet<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        heightFactor: 0.78,
        builder: (sheetContext) {
          return MoveraModalSheet(
            heightFactor: 0.78,
            color: const Color(0xFFF7F9F9),
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
                physics: const BouncingScrollPhysics(),
                children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7DEDF),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _optionTile(
                      key: const ValueKey<String>('current-trip-waybill-option'),
                      icon: MoveraMark.receipt,
                      title: 'Current waybill',
                      subtitle:
                          '${widget.pickupAddress} → ${widget.dropoffAddress}',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        final record = _waybills.current;
                        if (record != null) {
                          showMoveraWaybillSheet(
                            context,
                            record,
                            title: 'Current trip waybill',
                          );
                        }
                      },
                    ),
                    if (_onTripRadarState == _OnTripRadarState.secured &&
                        _waybills.next != null)
                      _optionTile(
                        key: const ValueKey<String>('next-trip-waybill-option'),
                        icon: MoveraMark.route,
                        title: 'Next trip waybill',
                        subtitle: _waybills.next!.dropoff,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          showMoveraWaybillSheet(
                            context,
                            _waybills.next!,
                            title: 'Next trip waybill',
                          );
                        },
                      ),
                    _optionTile(
                      icon: MoveraMark.shield,
                      title: 'Safety toolkit',
                      subtitle: 'Share trip, record audio or get help',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        showSafetyToolKitSheet(context);
                      },
                    ),
                    _optionTile(
                      key: const ValueKey<String>('active-ride-cancel-option'),
                      icon: _stage == ActiveRideStage.onTrip
                          ? MoveraMark.warning
                          : MoveraMark.close,
                      title: _stage == ActiveRideStage.onTrip
                          ? 'End trip early'
                          : 'Cancel trip',
                      subtitle: _stage == ActiveRideStage.onTrip
                          ? 'Stop safely first · reason required'
                          : 'Choose a reason before cancelling',
                      danger: true,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _showCancellationReasons();
                      },
                    ),
                ],
              ),
            ),
          );
        },
      );
    }
    Widget _optionTile({
      Key? key,
      required MoveraMark icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
      bool danger = false,
    }) {
      return Material(
        key: key,
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: danger
                        ? const Color(0xFFFFECEE)
                        : const Color(0xFFF4F5F6),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: MoveraLineIcon(
                    mark: icon,
                    color: danger ? _AcceptRideState._danger : _AcceptRideState._ink,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: danger ? _AcceptRideState._danger : const Color(0xFF252E3A),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF7D898F),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFA7B0B4),
                ),
              ],
            ),
          ),
        ),
      );
    }
    Future<void> _showCancellationReasons() async {
      final isOnTrip = _stage == ActiveRideStage.onTrip;
      final reasons = isOnTrip
          ? _AcceptRideState._onTripCancellationReasons
          : _stage == ActiveRideStage.waitingForRider &&
                  !_paidStopWait &&
                  _waitSeconds >= 300
              ? <_TripCancellationReason>[_AcceptRideState._noShowReason, ..._AcceptRideState._preTripCancellationReasons]
              : _AcceptRideState._preTripCancellationReasons;

      final reason = await showMoveraModalSheet<_TripCancellationReason>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.32),
        heightFactor: isOnTrip ? 0.72 : 0.66,
        builder: (sheetContext) {
          return MoveraModalSheet(
            key: const ValueKey<String>('trip-cancellation-reasons-sheet'),
            heightFactor: isOnTrip ? 0.72 : 0.66,
            color: const Color(0xFFF8FAF9),
            radius: 28,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7DEDB),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOnTrip
                              ? 'Why are you ending the trip?'
                              : 'Why are you cancelling?',
                          style: const TextStyle(
                            color: _AcceptRideState._ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          isOnTrip
                              ? 'Stop the vehicle in a safe place before ending an active trip.'
                              : 'Choose the reason that best explains the cancellation.',
                          style: const TextStyle(
                            color: _AcceptRideState._muted,
                            fontSize: 11,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 2, 14, 20),
                      itemCount: reasons.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 7),
                      itemBuilder: (context, index) {
                        final reason = reasons[index];
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(17),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            key: ValueKey<String>(
                              'trip-cancel-reason-${reason.code}',
                            ),
                            onTap: () => Navigator.pop(sheetContext, reason),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
                              child: Row(
                                children: [
                                  Container(
                                    width: 39,
                                    height: 39,
                                    decoration: BoxDecoration(
                                      color: isOnTrip
                                          ? const Color(0xFFFFEEF0)
                                          : const Color(0xFFF0F3F2),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: MoveraLineIcon(
                                      mark: reason.icon,
                                      color: isOnTrip
                                          ? _AcceptRideState._danger
                                          : const Color(0xFF58656C),
                                      size: 19,
                                    ),
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          reason.title,
                                          style: const TextStyle(
                                            color: _AcceptRideState._ink,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          reason.subtitle,
                                          style: const TextStyle(
                                            color: _AcceptRideState._muted,
                                            fontSize: 9.5,
                                            height: 1.3,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFFA5AFB4),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (!mounted || reason == null) { return; }
      await _AcceptRideTrip(this)._confirmCancellationReason(reason);
    }
}
