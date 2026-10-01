part of 'home.dart';

// Offer and Trip Radar orchestration for DriverHome.
// Timers and fields stay on the state. This extension is the only
// place that schedules or presents those demo offers.

enum _HomeRadarMatchState { available, resolving, claimedElsewhere }

enum _HomeRadarMatchNoticeType { matching, success, taken }

class _HomeRadarMatchNotice {
  const _HomeRadarMatchNotice({
    required this.type,
    required this.title,
    required this.message,
  });

  final _HomeRadarMatchNoticeType type;
  final String title;
  final String message;
}

class _HomeDirectOffer {
  final String id;
  final String category;
  final String reason;
  final String detail;
  final String fare;
  final String rating;
  final int pickupMinutes;
  final double pickupKm;
  final int tripMinutes;
  final double tripKm;
  final String pickup;
  final String dropoff;
  final LatLng pickupPosition;
  final LatLng dropoffPosition;
  final bool reservation;
  final bool driverSigned = false;

  const _HomeDirectOffer({
    required this.id,
    required this.category,
    required this.reason,
    required this.detail,
    required this.fare,
    required this.rating,
    required this.pickupMinutes,
    required this.pickupKm,
    required this.tripMinutes,
    required this.tripKm,
    required this.pickup,
    required this.dropoff,
    required this.pickupPosition,
    required this.dropoffPosition,
    this.reservation = false,
  });
}

extension _HomeOfferRadar on _DriverHomeState {
    void _maybeShowSoonReservation() {
      if (!_soonReservationReady || !mounted || !_isOnline) { return; }
      final offer = _DriverHomeState._soonReservationOffer;
      if (offer.driverSigned || offer.pickupMinutes > 30) { return; }
      if (!_directOfferFollowsDestination(offer)) { return; }

      _showOutsideRadarOffer(offer);
      if (_outsideRadarOffer?.id == offer.id) {
        _soonReservationReady = false;
      }
    }
    bool _directOfferFollowsDestination(_HomeDirectOffer offer) {
      if (!_destinationModeActive) { return true; }
      final destination = _destinationPosition;
      if (destination == null) { return true; }

      final latitudeRadians = _driverPosition.latitude * math.pi / 180;
      final longitudeScale = math.cos(latitudeRadians);

      final destinationX =
          (destination.longitude - _driverPosition.longitude) * longitudeScale;
      final destinationY = destination.latitude - _driverPosition.latitude;
      final offerX =
          (offer.dropoffPosition.longitude - _driverPosition.longitude) *
          longitudeScale;
      final offerY =
          offer.dropoffPosition.latitude - _driverPosition.latitude;

      final destinationLength = math.sqrt(
        destinationX * destinationX + destinationY * destinationY,
      );
      final offerLength = math.sqrt(offerX * offerX + offerY * offerY);
      if (destinationLength == 0 || offerLength == 0) { return true; }

      final cosine =
          (destinationX * offerX + destinationY * offerY) /
          (destinationLength * offerLength);
      return cosine >= 0.45;
    }
    void _clearDirectOfferRoute() {
      if (!mounted) { return; }
      _rebuild(() {
        _isDirectOfferRoutePreview = false;
        _directOfferRouteMarkers = {};
        _directOfferRoutePolylines = {};
      });
    }
    Future<void> _showOutsideRadarOffer(
      _HomeDirectOffer offer,
    ) async {
      if (!mounted ||
          !_isOnline ||
          showRideRequests ||
          _radarHomeOffers.isNotEmpty ||
          _pendingRadarHomeOffers.isNotEmpty ||
          _hasRideOffers ||
          !_directOfferFollowsDestination(offer) ||
          (offer.reservation &&
              (offer.driverSigned || offer.pickupMinutes > 30)) ||
          _mainPanelPosition > 0.04 ||
          isPanelOpen) {
        return;
      }

      _outsideOfferTimeoutTimer?.cancel();
      _rebuild(() {
        _outsideRadarOffer = offer;
      });

      _outsideOfferTimeoutTimer = Timer(
        _DriverHomeState._outsideOfferLifetime,
        () {
          if (!mounted || _outsideRadarOffer?.id != offer.id) { return; }
          _dismissOutsideRadarOffer();
        },
      );

      await _previewDirectOfferRoute(
        offer.pickupPosition,
        offer.dropoffPosition,
      );
    }
    void _dismissOutsideRadarOffer() {
      _outsideOfferTimeoutTimer?.cancel();
      _outsideOfferTimeoutTimer = null;
      if (!mounted) { return; }

      _rebuild(() {
        _outsideRadarOffer = null;
      });
      _clearDirectOfferRoute();
      _releasePendingRadarOffers();
    }
    void _showRadarHomeOffer(_HomeDirectOffer offer) {
      if (!mounted ||
          !_isOnline ||
          !_directOfferFollowsDestination(offer) ||
          _radarHomeOffers.any((item) => item.id == offer.id) ||
          _pendingRadarHomeOffers.any((item) => item.id == offer.id) ||
          _radarHomeOffers.length + _pendingRadarHomeOffers.length >=
              _DriverHomeState._maxHomeRadarOffers) {
        return;
      }

      // Dispatch owns offer expiry and claim state for both Home and Radar.

      if (_outsideRadarOffer != null) {
        _rebuild(() {
          _hasRideOffers = true;
          _pendingRadarHomeOffers.add(offer);
        });
        return;
      }

      // Keep the visible Home Radar list stable. The first detected trip creates
      // the snapshot; later detections wait for an explicit driver refresh.
      if (_radarHomeOffers.isEmpty) {
        _activateRadarHomeOffer(offer);
        return;
      }

      _rebuild(() {
        _hasRideOffers = true;
        _pendingRadarHomeOffers.add(offer);
      });
    }
    void _activateRadarHomeOffer(_HomeDirectOffer offer) {
      if (!mounted ||
          !_isOnline ||
          _radarHomeOffers.length >= _DriverHomeState._maxHomeRadarOffers ||
          _radarHomeOffers.any((item) => item.id == offer.id)) {
        return;
      }

      _rebuild(() {
        _hasRideOffers = true;
        _radarHomeOffers.add(offer);
        _pendingRadarHomeOffers.removeWhere((item) => item.id == offer.id);
      });
    }
    void _refreshRadarHomeOffers() {
      if (!mounted ||
          !_isOnline ||
          _outsideRadarOffer != null ||
          _pendingRadarHomeOffers.isEmpty) {
        return;
      }

      final refreshed = <_HomeDirectOffer>[
        ..._radarHomeOffers,
        ..._pendingRadarHomeOffers,
      ];

      final seen = <String>{};
      final next = <_HomeDirectOffer>[];
      for (final offer in refreshed) {
        if (seen.add(offer.id)) {
          next.add(offer);
        }
        if (next.length >= _DriverHomeState._maxHomeRadarOffers) { break; }
      }

      _rebuild(() {
        _radarHomeOffers
          ..clear()
          ..addAll(next);
        _pendingRadarHomeOffers.clear();
        _hasRideOffers = _radarHomeOffers.isNotEmpty;
      });

      _dispatch.refreshOffers();
      _scheduleHomeRadarExternalClaimDemo();
    }
    void _releasePendingRadarOffers() {
      if (!mounted ||
          !_isOnline ||
          _outsideRadarOffer != null ||
          _pendingRadarHomeOffers.isEmpty) {
        return;
      }

      // Keep detected trips pending until the driver explicitly refreshes.
      _rebuild(() {
        _hasRideOffers = true;
      });
    }
    void _dismissRadarHomeOffer(_HomeDirectOffer offer) {
      _radarOfferTimeoutTimers.remove(offer.id)?.cancel();
      if (!mounted) { return; }

      _rebuild(() {
        _radarHomeOffers.removeWhere((item) => item.id == offer.id);
        _pendingRadarHomeOffers.removeWhere((item) => item.id == offer.id);
        _homeRadarMatchStates.remove(offer.id);
        _hasRideOffers =
            _radarHomeOffers.isNotEmpty || _pendingRadarHomeOffers.isNotEmpty;
      });

      if (_radarHomeOffers.isEmpty && _pendingRadarHomeOffers.isNotEmpty) {
        _releasePendingRadarOffers();
      }
      if (_radarHomeOffers.isEmpty && _pendingRadarHomeOffers.isEmpty) {
        _maybeShowSoonReservation();
      }
    }
    _HomeRadarMatchState _homeRadarStateFor(String id) =>
        _homeRadarMatchStates[id] ?? _HomeRadarMatchState.available;
    void _startHomeRadarMatch(_HomeDirectOffer offer) {
      if (!_radarHomeOffers.any((item) => item.id == offer.id) ||
          _homeRadarStateFor(offer.id) != _HomeRadarMatchState.available ||
          _homeRadarMatchingOfferId != null) {
        return;
      }

      _rebuild(() {
        _homeRadarMatchingOfferId = offer.id;
        _homeRadarMatchStates[offer.id] = _HomeRadarMatchState.resolving;
        _homeRadarMatchNotice = const _HomeRadarMatchNotice(
          type: _HomeRadarMatchNoticeType.matching,
          title: 'Matching trip',
          message: 'Confirming this request in real time…',
        );
      });

      unawaited(_claimHomeRadarOffer(offer));
    }
    Future<void> _claimHomeRadarOffer(_HomeDirectOffer offer) async {
      final result = await _dispatch.claimOffer(offer.id);
      if (!mounted || _homeRadarMatchingOfferId != offer.id) { return; }
      if (result.isSuccess) {
        _resolveHomeRadarMatchWon(offer);
      } else {
        _resolveHomeRadarMatchLost(offer);
      }
    }
    void _watchDispatchRadar() {
      _radarSubscription?.cancel();
      _radarSubscription = _dispatch.watchNearbyOffers().listen((offers) {
        if (!mounted || !_isOnline) { return; }
        _latestDispatchOffers = offers;
        final ids = offers.map((item) => item.id).toSet();
        for (final offer in [..._radarHomeOffers, ..._pendingRadarHomeOffers]) {
          if (!ids.contains(offer.id) &&
              _homeRadarStateFor(offer.id) == _HomeRadarMatchState.available) {
            _resolveHomeRadarMatchLost(offer);
          }
        }
      });
    }
    void _showDispatchOfferAt(int index) {
      final offers = _latestDispatchOffers.where((offer) => offer.isNearby &&
          (!_destinationModeActive || offer.followsDestination)).toList();
      if (index >= offers.length) { return; }
      final offer = offers[index];
      _showRadarHomeOffer(_HomeDirectOffer(
        id: offer.id,
        category: offer.category,
        reason: 'Trip Radar match',
        detail: 'Detected in your live radar coverage',
        fare: offer.fare,
        rating: offer.rating,
        pickupMinutes: offer.pickupMinutes,
        pickupKm: offer.pickupKm,
        tripMinutes: offer.tripMinutes,
        tripKm: offer.tripKm,
        pickup: offer.pickup,
        dropoff: offer.dropoff,
        pickupPosition: offer.pickupPosition.toLatLng(),
        dropoffPosition: offer.dropoffPosition.toLatLng(),
      ));
    }
    void _resolveHomeRadarMatchWon(_HomeDirectOffer offer) {
      _homeRadarNoticeTimer?.cancel();

      _rebuild(() {
        _homeRadarMatchingOfferId = null;
        _homeRadarMatchStates.remove(offer.id);
        _homeRadarMatchNotice = const _HomeRadarMatchNotice(
          type: _HomeRadarMatchNoticeType.success,
          title: 'Trip matched',
          message: 'You’re assigned to this request. Opening trip…',
        );
      });

      _homeRadarNoticeTimer = Timer(
        const Duration(milliseconds: 850),
        () {
          if (!mounted) { return; }
          _acceptRadarHomeOffer(offer);
        },
      );
    }
    void _resolveHomeRadarMatchLost(_HomeDirectOffer offer) {
      _rebuild(() {
        _homeRadarMatchingOfferId = null;
        _homeRadarMatchStates[offer.id] =
            _HomeRadarMatchState.claimedElsewhere;
        _homeRadarMatchNotice = const _HomeRadarMatchNotice(
          type: _HomeRadarMatchNoticeType.taken,
          title: 'Request taken',
          message: 'Another driver was matched first. Choose another trip.',
        );
      });

      _homeRadarNoticeTimer?.cancel();
      _homeRadarNoticeTimer = Timer(
        const Duration(milliseconds: 2600),
        () {
          if (!mounted) { return; }
          _rebuild(() => _homeRadarMatchNotice = null);
        },
      );

      _homeRadarLostMatchTimer?.cancel();
      _homeRadarLostMatchTimer = Timer(
        const Duration(milliseconds: 2800),
        () {
          if (!mounted ||
              _homeRadarStateFor(offer.id) !=
                  _HomeRadarMatchState.claimedElsewhere) {
            return;
          }
          _dismissRadarHomeOffer(offer);
        },
      );
    }
    void _scheduleHomeRadarExternalClaimDemo() {
      _homeRadarExternalClaimTimer?.cancel();

      _HomeDirectOffer? offer;
      for (final item in _radarHomeOffers) {
        if (item.id == 'home-radar-match-3' || item.id == 'nearby-3') {
          offer = item;
          break;
        }
      }
      offer ??= _radarHomeOffers.isEmpty ? null : _radarHomeOffers.last;
      if (offer == null ||
          _homeRadarStateFor(offer.id) != _HomeRadarMatchState.available) {
        return;
      }

      final matchedOffer = offer;
      _homeRadarExternalClaimTimer = Timer(
        const Duration(milliseconds: 4200),
        () {
          if (!mounted ||
              !_radarHomeOffers.any((item) => item.id == matchedOffer.id) ||
              _homeRadarStateFor(matchedOffer.id) !=
                  _HomeRadarMatchState.available) {
            return;
          }

          _rebuild(() {
            _homeRadarMatchStates[matchedOffer.id] =
                _HomeRadarMatchState.claimedElsewhere;
          });

          _homeRadarExternalClaimCleanupTimer?.cancel();
          _homeRadarExternalClaimCleanupTimer = Timer(
            const Duration(milliseconds: 2800),
            () {
              if (!mounted ||
                  _homeRadarStateFor(matchedOffer.id) !=
                      _HomeRadarMatchState.claimedElsewhere) {
                return;
              }
              _dismissRadarHomeOffer(matchedOffer);
            },
          );
        },
      );
    }
    void _cancelAllOfferTimers() {
      _outsideOfferTimeoutTimer?.cancel();
      _outsideOfferTimeoutTimer = null;
      _reservationOfferTimer?.cancel();
      _reservationOfferTimer = null;
      _homeRadarMatchResolutionTimer?.cancel();
      _homeRadarNoticeTimer?.cancel();
      _homeRadarExternalClaimTimer?.cancel();
      _homeRadarExternalClaimCleanupTimer?.cancel();
      _homeRadarLostMatchTimer?.cancel();
      _homeRadarMatchingOfferId = null;
      _homeRadarMatchStates.clear();
      _homeRadarMatchNotice = null;
      for (final timer in _radarOfferTimeoutTimers.values) {
        timer.cancel();
      }
      _radarOfferTimeoutTimers.clear();
    }
    void _acceptOutsideRadarOffer() {
      final offer = _outsideRadarOffer;
      if (offer == null) { return; }

      _cancelAllOfferTimers();
      _expandedDirectOfferTimer?.cancel();
      _offerSimulationTimer?.cancel();
      _radarOfferTwoTimer?.cancel();
      _radarOfferThreeTimer?.cancel();

      Navigator.push(
        context,
        ActiveRideTransition(
          AcceptRide(
            offerId: '${offer.id}-${DateTime.now().microsecondsSinceEpoch}',
            fare: offer.fare,
            category: offer.category,
            matchedVia: offer.reservation ? 'Reservation' : 'Exclusive Radar',
            waybillRepository: _waybills,
            sessionController: _driverSession,
            locationRepository: _driverLocationService,
            routeRepository: _roadRouteService,
            activeRideRepository: widget.activeRideRepository,
            pickupAddress: offer.pickup,
            pickupArea: offer.pickup.split(',').last.trim(),
            dropoffAddress: offer.dropoff,
            pickupPosition: offer.pickupPosition,
            dropoffPosition: offer.dropoffPosition,
            destinationModeActive: _destinationModeActive,
            destinationAddress: _destinationAddress,
            destinationPosition: _destinationPosition,
          ),
        ),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) { return; }
        _rebuild(() {
          _outsideRadarOffer = null;
          _radarHomeOffers.clear();
          _pendingRadarHomeOffers.clear();
          _hasRideOffers = false;
          _isDirectOfferRoutePreview = false;
          _directOfferRouteMarkers = {};
          _directOfferRoutePolylines = {};
        });
      });
    }
    void _acceptRadarHomeOffer(_HomeDirectOffer offer) {
      if (!_radarHomeOffers.any((item) => item.id == offer.id)) { return; }

      _cancelAllOfferTimers();
      _expandedDirectOfferTimer?.cancel();
      _offerSimulationTimer?.cancel();
      _radarOfferTwoTimer?.cancel();
      _radarOfferThreeTimer?.cancel();

      Navigator.push(
        context,
        ActiveRideTransition(
          AcceptRide(
            offerId: '${offer.id}-${DateTime.now().microsecondsSinceEpoch}',
            fare: offer.fare,
            category: offer.category,
            matchedVia: 'Movera Radar',
            waybillRepository: _waybills,
            sessionController: _driverSession,
            locationRepository: _driverLocationService,
            routeRepository: _roadRouteService,
            activeRideRepository: widget.activeRideRepository,
            pickupAddress: offer.pickup,
            pickupArea: offer.pickup.split(',').last.trim(),
            dropoffAddress: offer.dropoff,
            pickupPosition: offer.pickupPosition,
            dropoffPosition: offer.dropoffPosition,
            destinationModeActive: _destinationModeActive,
            destinationAddress: _destinationAddress,
            destinationPosition: _destinationPosition,
          ),
        ),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) { return; }
        _rebuild(() {
          _outsideRadarOffer = null;
          _radarHomeOffers.clear();
          _pendingRadarHomeOffers.clear();
          _hasRideOffers = false;
          _isDirectOfferRoutePreview = false;
          _directOfferRouteMarkers = {};
          _directOfferRoutePolylines = {};
        });
      });
    }
    Widget _buildHomeRadarMatchNotice(_HomeRadarMatchNotice notice) {
      final isMatching =
          notice.type == _HomeRadarMatchNoticeType.matching;
      final isSuccess =
          notice.type == _HomeRadarMatchNoticeType.success;
      final accent = isSuccess
          ? const Color(0xFF2FBE7B)
          : isMatching
              ? const Color(0xFFD99B24)
              : const Color(0xFFC75B62);

      return TripStatusBanner(
        key: const ValueKey<String>('home-radar-match-notice'),
        title: notice.title,
        subtitle: notice.message,
        accent: accent,
        busy: isMatching,
        leading: isMatching
            ? null
            : Icon(
                isSuccess
                    ? Icons.check_rounded
                    : Icons.person_off_outlined,
                color: accent,
                size: 22,
              ),
      );
    }
    Widget _buildRadarRefreshPrompt() {
      final count = _pendingRadarHomeOffers.length;

      return RepaintBoundary(
        child: Material(
          color: const Color(0xFFF7F9F9).withValues(alpha: 0.98),
          elevation: 8,
          shadowColor: const Color(0x3311181C),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3DE),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.radar_rounded,
                    color: Color(0xFFD28A19),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New Radar trips',
                        style: TextStyle(
                          color: Color(0xFF252E3A),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        count.toString() +
                            (count == 1
                                ? ' new offer ready'
                                : ' new offers ready'),
                        style: const TextStyle(
                          color: Color(0xFF7C888E),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  key: const ValueKey<String>('radar-home-refresh-empty'),
                  onPressed: _refreshRadarHomeOffers,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF9A650F),
                    backgroundColor: const Color(0xFFFFF3DE),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 15),
                  label: const Text(
                    'Refresh',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    Widget _buildRadarTrayHeader(List<_HomeDirectOffer> offers) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;

          final title = Row(
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3DE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.radar_rounded,
                  color: Color(0xFFD28A19),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trip Radar offers',
                      style: TextStyle(
                        color: Color(0xFF252E3A),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      _destinationModeActive
                          ? 'On your way · same direction only'
                          : 'Stable list · refresh when new trips arrive',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7C888E),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_pendingRadarHomeOffers.isEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF26343A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${offers.length} live',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          );

          final refresh = TextButton.icon(
            key: const ValueKey<String>('radar-home-refresh'),
            onPressed: _refreshRadarHomeOffers,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF9A650F),
              backgroundColor: const Color(0xFFFFF3DE),
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 7,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 15),
            label: Text(
              'Refresh · ${_pendingRadarHomeOffers.length} new',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          );

          return Padding(
            padding: const EdgeInsets.fromLTRB(15, 13, 12, 10),
            child: _pendingRadarHomeOffers.isEmpty
                ? title
                : compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          title,
                          const SizedBox(height: 9),
                          Align(
                            alignment: Alignment.centerRight,
                            child: refresh,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: title),
                          const SizedBox(width: 8),
                          refresh,
                        ],
                      ),
          );
        },
      );
    }
    Widget _buildRadarOffersTray() {
      final offers = List<_HomeDirectOffer>.unmodifiable(_radarHomeOffers);
      final trayHeight = math.min(
        390.0,
        MediaQuery.of(context).size.height * 0.45,
      );

      return RepaintBoundary(
        child: SizedBox(
          height: trayHeight,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9F9).withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFDDE5E2)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF11181C).withValues(alpha: 0.12),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildRadarTrayHeader(offers),
                const Divider(height: 1, color: Color(0xFFE3E8E6)),
                Expanded(
                  child: ListView.separated(
                    key: const PageStorageKey<String>('radar-home-offers-list'),
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                    itemCount: offers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final offer = offers[index];
                      return RepaintBoundary(
                        key: ValueKey<String>('radar-offer-${offer.id}'),
                        child: _buildRadarOpportunityCard(offer),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    Widget _buildRadarOpportunityCard(_HomeDirectOffer offer) {
      final matchState = _homeRadarStateFor(offer.id);
      final claimed = matchState == _HomeRadarMatchState.claimedElsewhere;
      final resolving = matchState == _HomeRadarMatchState.resolving;
      final blockOtherOffers =
          _homeRadarMatchingOfferId != null &&
          _homeRadarMatchingOfferId != offer.id;

      return AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: claimed ? 0.68 : 1,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: claimed || resolving
                ? null
                : () => _previewDirectOfferRoute(
                      offer.pickupPosition,
                      offer.dropoffPosition,
                    ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F5F6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE6E8EA)),
                        ),
                        child: const Text(
                          'RADAR',
                          style: TextStyle(
                            color: Color(0xFF1C242C),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                      if (_destinationModeActive) ...[
                        const SizedBox(width: 7),
                        _homeBadge('On your way'),
                      ],
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          offer.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF657178),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (!resolving)
                        InkWell(
                          onTap: () => _dismissRadarHomeOffer(offer),
                          borderRadius: BorderRadius.circular(16),
                          child: const SizedBox(
                            width: 30,
                            height: 30,
                            child: MoveraLineIcon(
                              mark: MoveraMark.close,
                              color: Color(0xFF89949A),
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          offer.fare,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF252E3A),
                            fontSize: 25,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const MoveraLineIcon(
                        mark: MoveraMark.star,
                        color: Color(0xFFD7A02C),
                        size: 15,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        offer.rating,
                        style: const TextStyle(
                          color: Color(0xFF69757B),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _homeDirectLocationRow(
                    color: const Color(0xFF2FBE7B),
                    title:
                        '${offer.pickupMinutes} min · ${offer.pickupKm.toStringAsFixed(1)} km away',
                    subtitle: offer.pickup,
                  ),
                  const SizedBox(height: 8),
                  _homeDirectLocationRow(
                    color: const Color(0xFF252E3A),
                    title:
                        '${offer.tripMinutes} min · ${offer.tripKm.toStringAsFixed(1)} km trip',
                    subtitle: offer.dropoff,
                  ),
                  const SizedBox(height: 12),
                  if (claimed || resolving) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: claimed
                            ? const Color(0xFFF0F2F3)
                            : const Color(0xFFFFF3DE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          MoveraLineIcon(
                            mark: claimed ? MoveraMark.lock : MoveraMark.sync,
                            size: 15,
                            color: claimed
                                ? const Color(0xFF7D898F)
                                : const Color(0xFFB87512),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              claimed
                                  ? 'Matched by another driver'
                                  : 'Confirming availability',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: claimed
                                    ? const Color(0xFF68747A)
                                    : const Color(0xFF9A650F),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: claimed || resolving
                            ? null
                            : () => _previewDirectOfferRoute(
                                  offer.pickupPosition,
                                  offer.dropoffPosition,
                                ),
                        icon: const MoveraLineIcon(
                          mark: MoveraMark.route,
                          size: 16,
                          color: Color(0xFF1C242C),
                        ),
                        label: const Text('Route'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1C242C),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 40,
                        child: FilledButton(
                          onPressed: claimed || resolving || blockOtherOffers
                              ? null
                              : () => _startHomeRadarMatch(offer),
                          style: FilledButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF252E3A),
                            disabledBackgroundColor: const Color(0xFFD9DEDF),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: const Color(0xFF727E83),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          child: resolving
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 13,
                                      height: 13,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF727E83),
                                      ),
                                    ),
                                    SizedBox(width: 7),
                                    Text(
                                      'Matching…',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  claimed ? 'Matched' : 'Match',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    Widget _buildOutsideRadarOfferCard(_HomeDirectOffer offer) {
      const alertCoral = Color(0xFFFF765C);

      return AnimatedBuilder(
        animation: _goOnlinePulseController,
        builder: (context, child) {
          final pulse = _goOnlinePulseController.value;

          return Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: alertCoral.withValues(alpha: 0.38 + (pulse * 0.28)),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: alertCoral.withValues(alpha: 0.08 + (pulse * 0.07)),
                    blurRadius: 20 + (pulse * 8),
                    spreadRadius: pulse * 1.8,
                    offset: const Offset(0, 5),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9EEF1),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          offer.category,
                          style: const TextStyle(
                            color: Color(0xFF252E3A),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      if (_destinationModeActive) ...[
                        _homeBadge('On your way'),
                        const SizedBox(width: 7),
                      ],
                      if (offer.reservation && !offer.driverSigned) ...[
                        _homeBadge('Reservation'),
                        const SizedBox(width: 7),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: alertCoral.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            offer.reason,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFB84F3D),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: _dismissOutsideRadarOffer,
                        borderRadius: BorderRadius.circular(20),
                        child: const SizedBox(
                          width: 34,
                          height: 34,
                          child: MoveraLineIcon(
                            mark: MoveraMark.close,
                            color: Color(0xFF7D898F),
                            size: 20,
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
                            color: Color(0xFF252E3A),
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
                        offer.rating,
                        style: const TextStyle(
                          color: Color(0xFF6F7B82),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    offer.detail,
                    style: const TextStyle(
                      color: Color(0xFF7D898F),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TweenAnimationBuilder<double>(
                    key: ValueKey<String>('direct-offer-countdown-${offer.id}'),
                    tween: Tween<double>(begin: 1, end: 0),
                    duration: _DriverHomeState._outsideOfferLifetime,
                    builder: (context, remaining, child) {
                      final seconds = (remaining *
                              (_DriverHomeState._outsideOfferLifetime.inMilliseconds / 1000))
                          .ceil();
                      final reservation =
                          offer.reservation && !offer.driverSigned;

                      return Column(
                        children: [
                          Row(
                            children: [
                              const MoveraLineIcon(
                                mark: MoveraMark.timer,
                                color: Color(0xFF1C242C),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  reservation
                                      ? 'Reservation · ${seconds}s'
                                      : 'Exclusive offer · ${seconds}s',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF1C242C),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  reservation ? 'Outside radar' : 'Exclusive Radar',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
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
                  _homeDirectLocationRow(
                    color: AppColor.primary,
                    title:
                        '${offer.pickupMinutes} min · ${offer.pickupKm.toStringAsFixed(1)} km away',
                    subtitle: offer.pickup,
                  ),
                  const SizedBox(height: 9),
                  _homeDirectLocationRow(
                    color: const Color(0xFF252E3A),
                    title:
                        '${offer.tripMinutes} min · ${offer.tripKm.toStringAsFixed(1)} km trip',
                    subtitle: offer.dropoff,
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _previewDirectOfferRoute(
                          offer.pickupPosition,
                          offer.dropoffPosition,
                        ),
                        icon: const MoveraLineIcon(
                          mark: MoveraMark.route,
                          size: 17,
                          color: Color(0xFF1C242C),
                        ),
                        label: const Text('Route'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1C242C),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 42,
                        child: FilledButton(
                          onPressed: _acceptOutsideRadarOffer,
                          style: FilledButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF252E3A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Accept',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
    Widget _homeBadge(String label) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1C242C),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    Widget _homeDirectLocationRow({
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
                    color: Color(0xFF252E3A),
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
                    color: Color(0xFF7D898F),
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
    void _scheduleVisibleOffers() {
      if(!mounted || !_liveVisible || !_driverSession.availableForOffers) return;
      _cancelAllOfferTimers();
      _directOfferTimer?.cancel();_offerSimulationTimer?.cancel();
      _radarOfferTwoTimer?.cancel();_radarOfferThreeTimer?.cancel();_expandedDirectOfferTimer?.cancel();
          _watchDispatchRadar();

          // Frontend demo only. Outside-Radar offers remain exclusive and
          // never enter the Trip Radar list.
          _directOfferTimer = Timer(
            const Duration(milliseconds: 2200),
            () {
              if (!mounted || !_isOnline) { return; }
              _showOutsideRadarOffer(_DriverHomeState._veryCloseDirectOffer);
            },
          );

          // Radar offers start only after the exclusive outside-Radar offer
          // has had its own presentation window.
          _offerSimulationTimer = Timer(
            const Duration(milliseconds: 11500),
            () {
              if (!mounted || !_isOnline) { return; }
              _showDispatchOfferAt(0);
            },
          );

          _radarOfferTwoTimer = Timer(
            const Duration(milliseconds: 14500),
            () {
              if (!mounted || !_isOnline) { return; }
              _showDispatchOfferAt(1);
            },
          );

          _radarOfferThreeTimer = Timer(
            const Duration(milliseconds: 17500),
            () {
              if (!mounted || !_isOnline) { return; }
              _showDispatchOfferAt(2);
            },
          );

          // Keep a second outside-Radar example available later, but never
          // show it while Radar offers are active.
          _expandedDirectOfferTimer = Timer(
            const Duration(milliseconds: 50000),
            () {
              if (!mounted ||
                  !_isOnline ||
                  _radarHomeOffers.isNotEmpty ||
                  _hasRideOffers) {
                return;
              }
              _showOutsideRadarOffer(_DriverHomeState._expandedDirectOffer);
            },
          );

          _soonReservationReady = true;
          _reservationOfferTimer = Timer(
            const Duration(milliseconds: 40000),
            () {
              if (!mounted || !_isOnline) { return; }
              _maybeShowSoonReservation();
            },
          );
    }
}
