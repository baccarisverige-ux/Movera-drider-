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

        final snap = _rideSnapPoint(context);
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
      final collapsed = MoveraSheetMetrics.activeCollapsedTotal(
            MediaQuery.paddingOf(context).bottom,
          );
      final bannerReserve = MediaQuery.paddingOf(context).top + 130;
      return math.min(
        MoveraSheetMetrics.expandedHeight(viewport),
        math.max(collapsed + 160, viewport - bannerReserve),
      );
    }
    /// Panel position of the middle sheet: header, rider and slide action.
    double _rideSnapPoint(BuildContext context) {
      final safeBottom = MediaQuery.paddingOf(context).bottom;
      return MoveraSheetMetrics.activeSnapPoint(
        collapsed: MoveraSheetMetrics.activeCollapsedTotal(safeBottom),
        middle: MoveraSheetMetrics.activeMiddleTotal(safeBottom),
        expanded: _rideExpandedHeight(context),
      );
    }
    void _showRideMiddle() {
      if (!_ridePanelController.isAttached) { return; }
      unawaited(_ridePanelController.animatePanelToSnapPoint(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      ));
    }
    Future<void> _snapRideSheet({double? velocity}) async {
      if (!_ridePanelController.isAttached) { return; }
      final collapsed = MoveraSheetMetrics.activeCollapsedTotal(
            MediaQuery.paddingOf(context).bottom,
          );
      _snapSheet.rangePx = _rideExpandedHeight(context) - collapsed;
      await _snapSheet.snapToNearest(
        snapPoint: _rideSnapPoint(context),
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
        arrivalPointKind: _showArrivalApproach ? _approachKind : null,
        arrivalDistanceMeters: _approachDistanceMeters,
        arrivalLabel: _approachLabel,
        arrivalAddress: _approachAddress,
        arrivalArrived: _arrivalApproachArrived,
        radarSwitch: onTrip,
        radarOn: _onTripRadarOn,
        onRadarToggle: _AcceptRideTrip(this)._toggleOnTripRadar,
        waitSeconds: _countingWait ? _waitSeconds : null,
        waitPaid: _paidStopWait,
        onWaitTap: _openWaitingTime,
      );
    }
    void _openRidePreferences() {
      Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const Preferences()),
      );
    }
    Widget _buildMapControls() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_freshRadarLocation ? 'Demo Radar' : 'Demo Radar — live location unavailable/stale', style: const TextStyle(fontSize: 10)),
          const SizedBox(height: 4),
          MapControlButton(
            key: const ValueKey<String>('active-ride-safety-button'),
            tooltip: 'Safety toolkit',
            size: 50,
            onTap: () => showSafetyToolKitSheet(context),
            child: SvgPicture.asset(AppAssets.mapSafety, width: 26, height: 26),
          ),
          const SizedBox(height: 12),
          MapControlButton(
            key: const ValueKey<String>('active-ride-google-maps-button'),
            tooltip: 'Navigate with Google Maps',
            size: 56,
            fill: MapControlButton.googleGrey,
            onTap: _openGoogleMaps,
            child: SvgPicture.asset(AppAssets.mapGoogle, width: 26, height: 26),
          ),
          const SizedBox(height: 12),
          MapControlButton(
            key: const ValueKey<String>('active-ride-recenter-button'),
            tooltip: 'Recenter',
            size: 56,
            fill: MapControlButton.recenterBlue,
            onTap: () {
              _navigation.resumeFollow();
              unawaited(_AcceptRideTrip(this)._followVehicle(force: true));
            },
            child: SvgPicture.asset(AppAssets.mapRecenter, width: 24, height: 24),
          ),
        ],
      );
    }
    Future<void> _openGoogleMaps() async {
      final target = _approachTarget ?? widget.dropoffPosition;
      final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=${target.latitude},${target.longitude}&travelmode=driving',
      );
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Maps is unavailable.')),
        );
      }
    }
    Widget _buildRidePanel() {
      return ValueListenableBuilder<double>(
        valueListenable: _ridePanelPosition,
        builder: (context, pos, _) {
          final snap = _rideSnapPoint(context);
          // Three states: the flat bar, the middle sheet with the rider and
          // the next action, and the clean full sheet with trip details.
          final compact = pos < snap * 0.5;
          final full = pos > snap + (1 - snap) * 0.35;
          return Container(
            key: const ValueKey<String>('active-ride-panel'),
            decoration: BoxDecoration(
              color: _AcceptRideState._panel,
              // Flat and square like the bar; rounded only when full.
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(full ? 24 : 0),
              ),
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
                  KeyedSubtree(
                    key: ValueKey<String>('active-ride-panel-${_stage.name}'),
                    child: const SizedBox.shrink(),
                  ),
                  if (compact)
                    TripBottomBar(
                      key: const ValueKey<String>('active-ride-compact-dock'),
                      etaLabel: _countingWait ? _waitBarEta : _sheetEtaText,
                      etaColor: _countingWait ? _waitBarColor : null,
                      distanceLabel: _countingWait ? null : _routeDistanceText,
                      statusLabel: _countingWait
                          ? _waitBarStatus
                          : _soonStatus ?? _tripBarStatus,
                      statusColor: _soonStatus != null ? _AcceptRideState._green : null,
                      progress: _soonStatus == null ? _legFraction : null,
                      nextMark: _nextMarkKind,
                      soonTitle: _soonStatus != null ? 'Almost there' : null,
                      waitFraction: _waitFraction,
                      waitPaidFrom: _AcceptRideState._includedWaitSeconds /
                          _AcceptRideState._noShowWaitSeconds,
                      waitAlert: _waitSeconds >= _AcceptRideState._noShowWaitSeconds,
                      stopCount: _soonStatus != null || _countingWait
                          ? 0
                          : widget.stopAddresses.length,
                      onPreferences: _openRidePreferences,
                      onDetails: _showRideMiddle,
                      onStatusTap: _countingWait ? _openWaitingTime : null,
                      onArrived: _arrivalTarget != null
                          ? _AcceptRideTrip(this)._onArrivedTap
                          : null,
                      arrivedEnabled: _nearArrivalTarget,
                    )
                  else ...[
                    // Grip line: the sheet can be pulled up for details.
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8DEDF),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    TripBottomBar(
                      key: const ValueKey<String>('active-ride-expanded-header'),
                      etaLabel: _countingWait ? _waitBarEta : _sheetEtaText,
                      etaColor: _countingWait ? _waitBarColor : null,
                      distanceLabel: _countingWait ? null : _routeDistanceText,
                      statusLabel: _countingWait
                          ? _waitBarStatus
                          : _soonStatus ?? _title,
                      statusColor: _soonStatus != null ? _AcceptRideState._green : null,
                      progress: _soonStatus == null ? _legFraction : null,
                      nextMark: _nextMarkKind,
                      soonTitle: _soonStatus != null ? 'Almost there' : null,
                      waitFraction: _waitFraction,
                      waitPaidFrom: _AcceptRideState._includedWaitSeconds /
                          _AcceptRideState._noShowWaitSeconds,
                      waitAlert: _waitSeconds >= _AcceptRideState._noShowWaitSeconds,
                      stopCount: _soonStatus != null || _countingWait
                          ? 0
                          : widget.stopAddresses.length,
                      onPreferences: _openRidePreferences,
                      onDetails: full
                          ? _showRideMiddle
                          : () => _ridePanelController.open(),
                      onStatusTap: _countingWait ? _openWaitingTime : null,
                      expanded: full,
                      showDetailsButton: full,
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFECEEEF)),
                    if (!full) ...[
                      _buildRiderRow(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: _buildPrimaryAction(),
                      ),
                    ] else
                      Expanded(
                        child: SingleChildScrollView(
                          key: const PageStorageKey<String>('active-ride-scroll'),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRiderRow(padding: const EdgeInsets.symmetric(vertical: 14)),
                              _buildJourneyDetailsCard(),
                              if (_stage == ActiveRideStage.onTrip)
                                _buildSecuredNextTripDetails(),
                              const SizedBox(height: 12),
                              _buildSafetyTile(),
                              const SizedBox(height: 10),
                              _buildTripOptionsTile(),
                              const SizedBox(height: 10),
                              Center(
                                child: _countingWait
                                    ? _waitPhaseChip()
                                    : _liveStatus(),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    }
    Widget _buildJourneyDetailsCard() {
      final stopCount = widget.stopAddresses.length;
      return Container(
        key: const ValueKey<String>('active-ride-journey-card'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6E8EA), width: 1.3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _journeyPoint(
              kind: _JourneyPointKind.pickup,
              label: 'Pickup',
              address: widget.pickupAddress,
              detail: widget.pickupArea,
              isLast: false,
            ),
            for (var i = 0; i < stopCount; i++)
              _journeyPoint(
                kind: _JourneyPointKind.stop,
                label: 'Stop ${i + 1}',
                address: widget.stopAddresses[i],
                isLast: false,
              ),
            _journeyPoint(
              kind: _JourneyPointKind.dropoff,
              label: 'Drop-off',
              address: widget.dropoffAddress,
              isLast: true,
            ),
            _buildCurrentWaybillShortcut(),
          ],
        ),
      );
    }
    Widget _journeyPoint({
      required _JourneyPointKind kind,
      required String label,
      required String address,
      required bool isLast,
      String? detail,
    }) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 34,
              child: Column(
                children: [
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: Center(child: _RouteDot(kind: kind)),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: const Color(0xFFD5D9DC),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 14, top: 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: _AcceptRideState._muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AcceptRideState._ink,
                        fontSize: 16,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (detail != null && detail.trim().isNotEmpty)
                      Text(
                        detail,
                        style: const TextStyle(
                          color: _AcceptRideState._muted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
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
    Widget _waitPhaseChip() {
      final color = _waitBarColor;
      return InkWell(
        key: const ValueKey<String>('active-ride-wait-phase'),
        onTap: _openWaitingTime,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            _waitBarStatus,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
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
        mainAxisSize: MainAxisSize.min,
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
    /// Rider row of the middle and full sheet: call on the left, the
    /// rider's name (opens the profile) in the middle, message on the right.
    Widget _buildRiderRow({
      EdgeInsets padding = const EdgeInsets.fromLTRB(16, 14, 16, 14),
    }) {
      return Padding(
        key: const ValueKey<String>('active-ride-rider-card'),
        padding: padding,
        child: Row(
          children: [
            _roundRiderButton(
              key: const ValueKey<String>('active-ride-call-rider'),
              tooltip: 'Call rider',
              onTap: _callRider,
              child: SvgPicture.asset(
                AppAssets.tripCall,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  _AcceptRideState._ink,
                  BlendMode.srcIn,
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: _showRiderProfile,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(
                    widget.riderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _AcceptRideState._ink,
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ),
            ),
            _roundRiderButton(
              key: const ValueKey<String>('active-ride-message-rider'),
              tooltip: 'Message rider',
              onTap: _messageRider,
              child: SvgPicture.asset(
                AppAssets.tripMessage,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  _AcceptRideState._ink,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
      );
    }
    Widget _roundRiderButton({
      required Key key,
      required String tooltip,
      required VoidCallback onTap,
      required Widget child,
    }) {
      return Tooltip(
        key: key,
        message: tooltip,
        child: Material(
          color: const Color(0xFFF2F3F4),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(width: 56, height: 56, child: Center(child: child)),
          ),
        ),
      );
    }
    void _callRider() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(RiderContactPolicy.unavailableMessage),
          backgroundColor: _AcceptRideState._ink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
    void _messageRider() {
      Navigator.push(
        context,
        BottomToTopTransition(
          Chat(riderDisplayName: widget.riderName),
        ),
      );
    }
    Widget _buildTripOptionsTile() => _sheetTile(
      key: const ValueKey<String>('active-ride-trip-options'),
      asset: 'assets/icons/movera_route.svg',
      label: 'Trip options',
      onTap: _showTripOptions,
    );
    Widget _buildSafetyTile() => _sheetTile(
      key: const ValueKey<String>('active-ride-safety-tile'),
      asset: AppAssets.tripSafety,
      label: 'Safety toolkit',
      onTap: () => showSafetyToolKitSheet(context),
    );
    Widget _sheetTile({
      required Key key,
      required String asset,
      required String label,
      required VoidCallback onTap,
    }) {
      return Material(
        key: key,
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE6E8EA), width: 1.3),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  asset,
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    _AcceptRideState._ink,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: _AcceptRideState._ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFA0A8AC),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      );
    }
    Widget _buildCurrentWaybillShortcut() {
      return ValueListenableBuilder<WaybillRecord?>(
        valueListenable: _waybills.currentListenable,
        builder: (context, record, _) {
          if (record == null) { return const SizedBox.shrink(); }

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 12, bottom: 8),
                child: Divider(height: 1, color: Color(0xFFEEF0F1)),
              ),
              InkWell(
                key: const ValueKey<String>('current-waybill-shortcut'),
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  showMoveraWaybillSheet(
                    context,
                    record,
                    title: 'Current trip waybill',
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F5),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          AppAssets.tripWaybill,
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                            _AcceptRideState._ink,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Waybill',
                              style: TextStyle(
                                color: _AcceptRideState._ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${record.service} · ${record.tripId}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _AcceptRideState._muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFA0A8AC),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ],
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

      // Arriving is a plain button; only trip steps after it slide.
      final arrival = _stage == ActiveRideStage.headingToPickup ||
          (_stage == ActiveRideStage.onTrip &&
           !_paidStopWait &&
           _stopCursor < widget.stopAddresses.length);
      if (arrival) {
        final near = _nearArrivalTarget;
        return SizedBox(
          width: double.infinity,
          height: 58,
          child: FilledButton(
            key: const ValueKey<String>('active-ride-arrived-button'),
            onPressed: () {
              _setMapGesturesBlocked(false);
              unawaited(_AcceptRideTrip(this)._onArrivedTap());
            },
            style: FilledButton.styleFrom(
              elevation: 0,
              backgroundColor: near ? const Color(0xFF111614) : const Color(0xFFEEEFF1),
              foregroundColor: near ? Colors.white : const Color(0xFF8E979B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "I've arrived",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }

      return _SlideRideAction(
        key: const ValueKey<String>('active-ride-slide-action'),
        semanticsKey: const ValueKey<String>('active-ride-primary-action'),
        label: _slideLabel,
        confirmedLabel: _slideConfirmedLabel,
        accent: accent,
        onConfirmed: () async {
          _setMapGesturesBlocked(false);
          await _AcceptRideTrip(this)._advanceRide();
        },
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

enum _JourneyPointKind { pickup, stop, dropoff }

/// Classic route marks: pickup is a black dot, a stop a smaller grey dot,
/// drop-off a black square, each with a white centre.
class _RouteDot extends StatelessWidget {
  const _RouteDot({required this.kind});

  final _JourneyPointKind kind;

  @override
  Widget build(BuildContext context) {
    final stop = kind == _JourneyPointKind.stop;
    final square = kind == _JourneyPointKind.dropoff;
    final size = stop ? 11.0 : 14.0;
    final inner = stop ? 4.0 : 5.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: stop ? const Color(0xFF8A9195) : _AcceptRideState._ink,
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: square ? BorderRadius.circular(2.5) : null,
      ),
      alignment: Alignment.center,
      child: Container(
        width: inner,
        height: inner,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: square ? BoxShape.rectangle : BoxShape.circle,
        ),
      ),
    );
  }
}
