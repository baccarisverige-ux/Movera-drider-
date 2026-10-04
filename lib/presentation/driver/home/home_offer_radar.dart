part of 'home.dart';

// Offer and Trip Radar orchestration for DriverHome.
// Timers and fields stay on the state. This extension is the only
// place that schedules or presents those demo offers.

enum _HomeRadarMatchState { available, resolving, claimedElsewhere }

enum _HomeRadarMatchNoticeType { matching, success }

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
        _homeRadarLostOwnMatch.remove(offer.id);
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
      // The row itself says what happened; no banner over the map.
      _homeRadarNoticeTimer?.cancel();
      _rebuild(() {
        if (_homeRadarMatchingOfferId == offer.id) {
          _homeRadarLostOwnMatch.add(offer.id);
        }
        _homeRadarMatchingOfferId = null;
        _homeRadarMatchStates[offer.id] =
            _HomeRadarMatchState.claimedElsewhere;
        _homeRadarMatchNotice = null;
      });

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
            offerId: tripOccurrenceId(offer.id),
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
            offerId: tripOccurrenceId(offer.id),
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
    // Radar offers use the reservation popup's look: white cards, black
    // ink, a pickup dot and a drop-off square, grey and black buttons.
    static const Color _offerInk = Color(0xFF111614);
    static const Color _offerMuted = Color(0xFF5E6461);
    static const Color _offerLine = Color(0xFFE4E6E5);
    static const Color _offerSoft = Color(0xFFEDEEED);

    Widget _buildRadarTrayHeader(List<_HomeDirectOffer> offers) {
      final pending = _pendingRadarHomeOffers.length;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Radar offers · ${offers.length}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _offerInk,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_destinationModeActive)
                    const Text(
                      'On your way · same direction only',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _offerMuted, fontSize: 12.5),
                    ),
                ],
              ),
            ),
            if (pending > 0)
              Material(
                color: _offerSoft,
                shape: const StadiumBorder(),
                child: InkWell(
                  key: const ValueKey<String>('radar-home-refresh'),
                  onTap: _refreshRadarHomeOffers,
                  customBorder: const StadiumBorder(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh_rounded, size: 17, color: _offerInk),
                        const SizedBox(width: 6),
                        Text(
                          '$pending new',
                          style: const TextStyle(
                            color: _offerInk,
                            fontSize: 13.5,
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
    Widget _buildRadarOffersTray() {
      final offers = List<_HomeDirectOffer>.unmodifiable(_radarHomeOffers);
      final maxHeight = math.min(
        430.0,
        MediaQuery.of(context).size.height * 0.5,
      );

      return RepaintBoundary(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Material(
            color: Colors.white,
            elevation: 8,
            shadowColor: const Color(0xFF172027).withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRadarTrayHeader(offers),
                Flexible(
                  child: ListView.separated(
                    key: const PageStorageKey<String>('radar-home-offers-list'),
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    itemCount: offers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
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
    bool _radarOfferExpanded(_HomeDirectOffer offer) {
      bool open(String id) =>
          _homeRadarStateFor(id) != _HomeRadarMatchState.claimedElsewhere;
      final chosen = _radarExpandedOfferId;
      if (chosen != null &&
          open(chosen) &&
          _radarHomeOffers.any((item) => item.id == chosen)) {
        return chosen == offer.id;
      }
      // Otherwise the first trip still available opens.
      for (final item in _radarHomeOffers) {
        if (open(item.id)) { return item.id == offer.id; }
      }
      return false;
    }
    Widget _buildRadarOpportunityCard(_HomeDirectOffer offer) {
      final matchState = _homeRadarStateFor(offer.id);
      final claimed = matchState == _HomeRadarMatchState.claimedElsewhere;
      final resolving = matchState == _HomeRadarMatchState.resolving;
      final blockOtherOffers =
          _homeRadarMatchingOfferId != null &&
          _homeRadarMatchingOfferId != offer.id;
      final expanded = _radarOfferExpanded(offer);
      final summary =
          '${offer.pickupMinutes} min away · ${offer.tripKm.toStringAsFixed(1)} km ride';

      final matchButton = SizedBox(
        height: expanded ? 46 : 40,
        child: FilledButton(
          onPressed: claimed || resolving || blockOtherOffers
              ? null
              : () => _startHomeRadarMatch(offer),
          style: FilledButton.styleFrom(
            elevation: 0,
            backgroundColor: _offerInk,
            disabledBackgroundColor: const Color(0xFFD9DEDF),
            foregroundColor: Colors.white,
            disabledForegroundColor: const Color(0xFF727E83),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                )
              : Text(
                  claimed ? 'Matched' : 'Match',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      );

      return AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: claimed
            ? _buildTakenRadarRow(offer)
            : _buildOpenableRadarCard(
                offer,
                expanded: expanded,
                resolving: resolving,
                summary: summary,
                matchButton: matchButton,
              ),
      );
    }
    /// A trip another driver got: one slim grey line, price crossed out,
    /// until it slides out of the list a moment later.
    Widget _buildTakenRadarRow(_HomeDirectOffer offer) {
      return Container(
        key: ValueKey<String>('radar-taken-${offer.id}'),
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_off_outlined, size: 18, color: _offerMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _homeRadarLostOwnMatch.contains(offer.id)
                    ? 'Another driver got it first'
                    : 'Taken by another driver',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _offerMuted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              offer.fare,
              style: const TextStyle(
                color: Color(0xFF9AA2A6),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.lineThrough,
                decorationColor: Color(0xFF9AA2A6),
              ),
            ),
          ],
        ),
      );
    }
    /// Tapping a trip (not its Match button) brings it to the top of the
    /// list with its details open.
    void _openRadarOffer(_HomeDirectOffer offer) {
      _rebuild(() {
        final index = _radarHomeOffers.indexWhere((item) => item.id == offer.id);
        if (index > 0) {
          _radarHomeOffers.insert(0, _radarHomeOffers.removeAt(index));
        }
        _radarExpandedOfferId = offer.id;
      });
      _previewDirectOfferRoute(offer.pickupPosition, offer.dropoffPosition);
    }
    Widget _buildOpenableRadarCard(
      _HomeDirectOffer offer, {
      required bool expanded,
      required bool resolving,
      required String summary,
      required Widget matchButton,
    }) {
      return Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: expanded ? _offerInk : _offerLine,
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: resolving ? null : () => _openRadarOffer(offer),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              offer.fare,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _offerInk,
                                fontSize: 20,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              resolving
                                  ? 'Confirming availability'
                                  : '${offer.category} · $summary',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _offerMuted,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!expanded)
                        matchButton
                      else if (!resolving)
                        Tooltip(
                          message: 'Hide offer',
                          child: InkWell(
                            onTap: () => _dismissRadarHomeOffer(offer),
                            customBorder: const CircleBorder(),
                            child: const SizedBox(
                              width: 32,
                              height: 32,
                              child: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: Color(0xFF9AA2A6),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (expanded) ...[
                    if (_destinationModeActive) ...[
                      const SizedBox(height: 8),
                      _homeBadge('On your way'),
                    ],
                    const SizedBox(height: 12),
                    _offerRouteRow(
                      square: false,
                      label: 'Pickup',
                      place: offer.pickup,
                      value: '${offer.pickupMinutes} min',
                      detail: '${offer.pickupKm.toStringAsFixed(1)} km away',
                    ),
                    _offerRouteConnector(),
                    _offerRouteRow(
                      square: true,
                      label: 'Drop-off',
                      place: offer.dropoff,
                      value: '${offer.tripMinutes} min',
                      detail: '${offer.tripKm.toStringAsFixed(1)} km ride',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: TextButton.icon(
                              onPressed: resolving
                                  ? null
                                  : () => _previewDirectOfferRoute(
                                        offer.pickupPosition,
                                        offer.dropoffPosition,
                                      ),
                              icon: const Icon(Icons.alt_route_rounded, size: 18),
                              label: const Text(
                                'Route',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: _offerInk,
                                backgroundColor: _offerSoft,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(flex: 2, child: matchButton),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
      );
    }
    Widget _offerRouteConnector() => Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(width: 2, height: 12, color: _offerLine),
          ),
        );
    Widget _offerRouteRow({
      required bool square,
      required String label,
      required String place,
      required String value,
      required String detail,
    }) {
      return Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: square ? _offerInk : Colors.white,
              shape: square ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: square ? BorderRadius.circular(2) : null,
              border: square ? null : Border.all(color: _offerInk, width: 3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: _offerMuted, fontSize: 11.5)),
                Text(
                  place,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _offerInk,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: _offerInk,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(detail, style: const TextStyle(color: _offerMuted, fontSize: 11.5)),
            ],
          ),
        ],
      );
    }
    Widget _offerChip(String label, IconData icon, {Color? bg, Color? fg}) {
      final foreground = fg ?? Colors.white;
      return Container(
        padding: const EdgeInsets.fromLTRB(7, 4, 9, 4),
        decoration: BoxDecoration(
          color: bg ?? _offerInk,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildOutsideRadarOfferCard(_HomeDirectOffer offer) {
      final reservation = offer.reservation && !offer.driverSigned;
      final lifetime = _DriverHomeState._outsideOfferLifetime;

      return Material(
        color: Colors.white,
        elevation: 8,
        shadowColor: const Color(0xFF172027).withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: _offerChip(offer.category, Icons.person_rounded),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: _offerChip(
                      reservation ? 'Reservation' : 'Exclusive',
                      reservation ? Icons.event_rounded : Icons.bolt_rounded,
                      bg: const Color(0xFFFFEDE8),
                      fg: const Color(0xFFC2462F),
                    ),
                  ),
                  if (_destinationModeActive) ...[
                    const SizedBox(width: 6),
                    _homeBadge('On your way'),
                  ],
                  const SizedBox(width: 8),
                  const Spacer(),
                  Tooltip(
                    message: 'Hide offer',
                    child: InkWell(
                      onTap: _dismissOutsideRadarOffer,
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 32,
                        height: 32,
                        child: Icon(
                          Icons.close_rounded,
                          size: 22,
                          color: _offerMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      offer.fare,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _offerInk,
                        fontSize: 30,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.star_rounded,
                    size: 17,
                    color: Color(0xFFD7A02C),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    offer.rating,
                    style: const TextStyle(
                      color: _offerMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                reservation
                    ? 'Reservation outside your Radar'
                    : 'Exclusive offer for you · nearby',
                style: const TextStyle(color: _offerMuted, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _offerLine, width: 1.5),
                ),
                child: Column(
                  children: [
                    _offerRouteRow(
                      square: false,
                      label: 'Pickup',
                      place: offer.pickup,
                      value: '${offer.pickupMinutes} min',
                      detail: '${offer.pickupKm.toStringAsFixed(1)} km away',
                    ),
                    _offerRouteConnector(),
                    _offerRouteRow(
                      square: true,
                      label: 'Drop-off',
                      place: offer.dropoff,
                      value: '${offer.tripMinutes} min',
                      detail: '${offer.tripKm.toStringAsFixed(1)} km ride',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: TextButton.icon(
                        key: const ValueKey<String>('direct-offer-route'),
                        onPressed: () => _previewDirectOfferRoute(
                          offer.pickupPosition,
                          offer.dropoffPosition,
                        ),
                        icon: const Icon(Icons.alt_route_rounded, size: 19),
                        label: const Text(
                          'Route',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: _offerInk,
                          backgroundColor: _offerSoft,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _acceptOutsideRadarOffer,
                        style: FilledButton.styleFrom(
                          elevation: 0,
                          backgroundColor: _offerInk,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        // The time left drains as a lighter band inside
                        // the button, with the seconds next to "Accept".
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey<String>(
                            'direct-offer-countdown-${offer.id}',
                          ),
                          tween: Tween<double>(begin: 1, end: 0),
                          duration: lifetime,
                          builder: (context, remaining, child) {
                            final seconds =
                                (remaining * lifetime.inMilliseconds / 1000)
                                    .ceil();
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                FractionallySizedBox(
                                  key: const ValueKey<String>(
                                    'direct-offer-countdown-fill',
                                  ),
                                  alignment: Alignment.centerLeft,
                                  widthFactor: remaining,
                                  child: const ColoredBox(
                                    color: Color(0xFF2C3438),
                                  ),
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Accept',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Text(
                                        ' · ',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      Text(
                                        '${seconds}s',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          fontFeatures: [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
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
