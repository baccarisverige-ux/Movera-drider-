import 'dart:async';

import 'package:flutter/material.dart';
import 'package:movera/core/dispatch/trip_occurrence.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/core/geo/geo_point_maps.dart';
import 'package:movera/core/dispatch/demo_dispatch_repository.dart';
import 'package:movera/core/dispatch/dispatch_repository.dart';
import 'package:movera/core/location/driver_location_repository.dart';
import 'package:movera/core/routing/route_repository.dart';
import 'package:movera/core/ride/active_ride_repository.dart';
import 'package:movera/core/session/driver_session_controller.dart';
import 'package:movera/core/waybill/waybill.dart';
import 'package:movera/presentation/driver/accept%20ride/accept_ride.dart';
import 'package:movera/presentation/driver/overlays/trip_status_banner.dart';
import 'package:movera/widgets/layout_viewport.dart';
import 'package:movera/widgets/navigation_transition.dart';

class RideRequests extends StatefulWidget {
  final ValueChanged<bool>? onCloseRides;
  final bool destinationModeActive;
  final String? destinationAddress;
  final LatLng? destinationPosition;
  final DriverSessionController? sessionController;
  final WaybillRepository? waybillRepository;
  final DriverLocationRepository? locationRepository;
  final RouteRepository? routeRepository;
  final DispatchRepository? dispatchRepository;
  final ActiveRideRepository? activeRideRepository;

  const RideRequests({
    super.key,
    this.onCloseRides,
    this.destinationModeActive = false,
    this.destinationAddress,
    this.destinationPosition,
    this.sessionController,
    this.waybillRepository,
    this.locationRepository,
    this.routeRepository,
    this.dispatchRepository,
    this.activeRideRepository,
  });

  @override
  State<RideRequests> createState() => _RideRequestsState();
}

class _RideRequestsState extends State<RideRequests> {
  // Same look as the Radar offers sheet on Home and the reservation popup.
  static const Color _page = Color(0xFFF4F5F5);
  static const Color _ink = Color(0xFF111614);
  static const Color _muted = Color(0xFF5E6461);
  static const Color _line = Color(0xFFE4E6E5);
  static const Color _soft = Color(0xFFEDEEED);
  static const Color _green = Color(0xFF19865C);
  static const Color _mint = Color(0xFF58E5A6);

  Timer? _matchNoticeTimer;
  late final DispatchRepository _dispatch;
  late final bool _ownsDispatch;
  StreamSubscription<List<RideOffer>>? _nearbySubscription;
  final Map<String, Timer> _claimedRemovalTimers = <String, Timer>{};
  final Map<String, _RadarOfferState> _offerStates =
      <String, _RadarOfferState>{};
  bool _hasNewTripSignal = false;
  bool _hasDispatchSnapshot = false;
  String? _matchingOfferId;
  _RadarMatchNotice? _matchNotice;
  List<RideOffer> _latestDispatchOffers = const <RideOffer>[];

  final List<_RadarTrip> _offers = <_RadarTrip>[];

  /// Why a trip is leaving the list.
  final Map<String, _RadarGone> _goneReasons = <String, _RadarGone>{};

  List<_RadarTrip> get _visibleOffers {
    final nearby = _offers.where((offer) {
      if (!offer.isNearby) { return false; }
      if (!widget.destinationModeActive) { return true; }
      return offer.followsDestination;
    }).toList()
      ..sort((a, b) => a.pickupKm.compareTo(b.pickupKm));
    // Every Radar trip, each with its full details.
    return List<_RadarTrip>.unmodifiable(nearby);
  }

  _RadarTrip _tripFromOffer(RideOffer offer) {
    return _RadarTrip(
      id: offer.id,
      category: offer.category,
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
      isNearby: offer.isNearby,
      followsDestination: offer.followsDestination,
    );
  }

  @override
  void initState() {
    super.initState();
    _ownsDispatch = widget.dispatchRepository == null;
    _dispatch = widget.dispatchRepository ?? DemoDispatchRepository();
    _nearbySubscription = _dispatch.watchNearbyOffers().listen(_onDispatchOffers);
  }

  @override
  void dispose() {
    _nearbySubscription?.cancel();
    _matchNoticeTimer?.cancel();
    for (final timer in _claimedRemovalTimers.values) {
      timer.cancel();
    }
    if (_ownsDispatch) {
      final dispatch = _dispatch;
      if (dispatch is DemoDispatchRepository) {
        dispatch.dispose();
      }
    }
    super.dispose();
  }

  void _onDispatchOffers(List<RideOffer> offers) {
    if (!mounted) { return; }
    _latestDispatchOffers = offers;

    // First emission is the stable snapshot. Later additions wait for Refresh.
    // Removals of still-available cards are remote claims from dispatch.
    if (!_hasDispatchSnapshot) {
      setState(() {
        _hasDispatchSnapshot = true;
        _offers
          ..clear()
          ..addAll(offers.map(_tripFromOffer));
      });
      return;
    }

    final displayedIds = _offers.map((trip) => trip.id).toSet();
    final incomingIds = offers.map((offer) => offer.id).toSet();
    final hasNew = offers.any(
      (offer) => offer.isNearby && !displayedIds.contains(offer.id),
    );
    final disappeared = _offers.where((trip) {
      return !incomingIds.contains(trip.id) &&
          _stateFor(trip.id) == _RadarOfferState.available;
    }).toList();

    if (hasNew && !_hasNewTripSignal) {
      setState(() => _hasNewTripSignal = true);
    }
    for (final trip in disappeared) {
      _markClaimedElsewhere(trip);
    }
  }

  void _refreshFromRadarSignal() {
    if (!_hasNewTripSignal) { return; }

    setState(() {
      final lingering = _offers.where((trip) {
        final state = _stateFor(trip.id);
        return state == _RadarOfferState.claimedElsewhere ||
            state == _RadarOfferState.resolving;
      }).toList();
      final lingeringIds = lingering.map((trip) => trip.id).toSet();
      _offers
        ..clear()
        ..addAll(
          _latestDispatchOffers
              .map(_tripFromOffer)
              .where((trip) => !lingeringIds.contains(trip.id)),
        )
        ..addAll(lingering);
      _hasNewTripSignal = false;
    });
    _dispatch.refreshOffers();
  }

  void _closeRides() {
    final onClose = widget.onCloseRides;
    if (onClose != null) {
      onClose(_visibleOffers.isNotEmpty);
      return;
    }
    // Embedded Radar uses Home's callback. A standalone Radar route must
    // still offer a functional Back action rather than trapping navigation.
    final navigator = Navigator.maybeOf(context);
    if (navigator?.canPop() ?? false) {
      navigator!.pop();
    }
  }

  _RadarOfferState _stateFor(String id) =>
      _offerStates[id] ?? _RadarOfferState.available;

  bool _isOfferStillVisible(_RadarTrip trip) {
    return _offers.any((offer) {
      if (offer.id != trip.id || !offer.isNearby) { return false; }
      if (!widget.destinationModeActive) { return true; }
      return offer.followsDestination;
    });
  }

  void _matchTrip(_RadarTrip trip) {
    if (!_isOfferStillVisible(trip) ||
        _stateFor(trip.id) != _RadarOfferState.available ||
        _matchingOfferId != null) {
      return;
    }

    setState(() {
      _matchingOfferId = trip.id;
      _offerStates[trip.id] = _RadarOfferState.resolving;
      _matchNotice = const _RadarMatchNotice(
        type: _RadarMatchNoticeType.matching,
        title: 'Matching trip',
        message: 'Confirming this request in real time…',
      );
    });

    unawaited(_claimTrip(trip));
  }

  Future<void> _claimTrip(_RadarTrip trip) async {
    ClaimResult result;
    try {
      result = await _dispatch.claimOffer(trip.id);
    } catch (_) {
      result = const ClaimResult.networkError();
    }
    if (!mounted || _matchingOfferId != trip.id) { return; }

    switch (result.outcome) {
      case ClaimOutcome.success:
        _resolveMatchWon(trip);
      case ClaimOutcome.alreadyClaimed:
        _resolveMatchLost(trip, _RadarGone.lostOwnMatch);
      case ClaimOutcome.expired:
      case ClaimOutcome.unavailable:
        _resolveMatchLost(trip, _RadarGone.unavailable);
      case ClaimOutcome.networkError:
        // Nothing was decided; let the driver try again.
        setState(() {
          _matchingOfferId = null;
          _offerStates.remove(trip.id);
          _matchNotice = const _RadarMatchNotice(
            type: _RadarMatchNoticeType.error,
            title: 'Could not match trip. Try again.',
            message: 'Connection interrupted. You can retry this request.',
          );
        });
    }
  }

  void _resolveMatchWon(_RadarTrip trip) {
    _matchNoticeTimer?.cancel();

    // Keep the winning Radar frame intact until the active ride has mounted.
    // Clearing/removing the card underneath a long map transition caused a
    // visible disappear/reappear flash on iPhone Safari.
    setState(() {
      _matchingOfferId = trip.id;
      _matchNotice = const _RadarMatchNotice(
        type: _RadarMatchNoticeType.success,
        title: 'Trip matched',
        message: 'You’re assigned to this request. Opening trip…',
      );
    });

    _matchNoticeTimer = Timer(
      const Duration(milliseconds: 500),
      () {
        if (!mounted) { return; }
        final navigator = Navigator.of(context);
        final ride = AcceptRide(
          offerId: tripOccurrenceId(trip.id),
          fare: trip.fare,
          category: trip.category,
          matchedVia: 'Movera Radar',
          sessionController: widget.sessionController,
          waybillRepository: widget.waybillRepository,
          locationRepository: widget.locationRepository,
          routeRepository: widget.routeRepository,
          activeRideRepository: widget.activeRideRepository,
          pickupAddress: trip.pickup,
          pickupArea: trip.pickup.split(',').last.trim(),
          dropoffAddress: trip.dropoff,
          pickupPosition: trip.pickupPosition,
          dropoffPosition: trip.dropoffPosition,
          destinationModeActive: widget.destinationModeActive,
          destinationAddress: widget.destinationAddress,
          destinationPosition: widget.destinationPosition,
        );

        navigator.push(ActiveRideTransition(ride));

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) { return; }
          setState(() {
            _matchingOfferId = null;
            _offers.removeWhere((offer) => offer.id == trip.id);
            _offerStates.remove(trip.id);
            _matchNotice = null;
          });
        });
      },
    );
  }

  void _resolveMatchLost(_RadarTrip trip, _RadarGone reason) {
    // The trip's own row says what happened; no banner over the list.
    _matchNoticeTimer?.cancel();
    setState(() {
      _matchingOfferId = null;
      _offerStates[trip.id] = _RadarOfferState.claimedElsewhere;
      _goneReasons[trip.id] = reason;
      _matchNotice = null;
    });

    _scheduleClaimedRemoval(trip.id);
  }

  /// A trip gone from Radar without a claim of ours. The reason is not
  /// known here (rider cancelled, expired, taken elsewhere…).
  void _markClaimedElsewhere(_RadarTrip trip) {
    if (!_isOfferStillVisible(trip) ||
        _stateFor(trip.id) != _RadarOfferState.available) {
      return;
    }

    setState(() {
      _offerStates[trip.id] = _RadarOfferState.claimedElsewhere;
      _goneReasons[trip.id] = _RadarGone.unavailable;
    });

    _scheduleClaimedRemoval(trip.id);
  }

  void _scheduleClaimedRemoval(String id) {
    _claimedRemovalTimers.remove(id)?.cancel();
    _claimedRemovalTimers[id] = Timer(
      const Duration(milliseconds: 2800),
      () {
        if (!mounted) { return; }
        setState(() {
          _offers.removeWhere((offer) => offer.id == id);
          _offerStates.remove(id);
          _goneReasons.remove(id);
        });
        _claimedRemovalTimers.remove(id);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final offers = _visibleOffers;
    final openCount = offers
        .where((offer) => _stateFor(offer.id) != _RadarOfferState.claimedElsewhere)
        .length;

    return LayoutViewport(
      child: Material(
      color: _page,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: Column(
              children: [
                _topBar(),
                _radarStatus(openCount),
                if (widget.destinationModeActive) _destinationModeBanner(),
                Expanded(
                  child: offers.isEmpty
                      ? _emptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                          physics: const BouncingScrollPhysics(),
                          itemCount: offers.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            return _tripCard(offers[index]);
                          },
                        ),
                ),
              ],
            ),
          ),
          if (_matchNotice != null)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: _buildMatchNotice(_matchNotice!),
            ),
        ],
      ),
    ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            elevation: 5,
            shadowColor: const Color(0xFF172027).withValues(alpha: 0.22),
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Back',
              onPressed: _closeRides,
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              icon: const Icon(Icons.arrow_back_rounded, color: _ink, size: 22),
            ),
          ),
          const Spacer(),
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F6EE),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LiveDot(size: 8, dark: true),
                SizedBox(width: 7),
                Text(
                  'Radar on',
                  style: TextStyle(
                    color: Color(0xFF137A4B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _radarStatus(int count) {
    final trips = '$count trip${count == 1 ? '' : 's'}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trip radar',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.destinationModeActive
                      ? '$trips on your way · closest first'
                      : '$trips near you · closest first',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 14),
                ),
              ],
            ),
          ),
          if (_hasNewTripSignal)
            Material(
              color: _soft,
              shape: const StadiumBorder(),
              child: InkWell(
                key: const ValueKey<String>('radar-refresh-new'),
                onTap: _refreshFromRadarSignal,
                customBorder: const StadiumBorder(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 17, color: _ink),
                      SizedBox(width: 6),
                      Text(
                        'New trips',
                        style: TextStyle(
                          color: _ink,
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

  Widget _destinationModeBanner() {
    final destination = widget.destinationAddress?.trim();
    final label = destination == null || destination.isEmpty
        ? 'Destination route'
        : destination.split(',').first.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Container(
        key: const ValueKey<String>('radar-destination-filter'),
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(8),
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
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Trips toward $label',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tripCard(_RadarTrip trip) {
    final state = _stateFor(trip.id);
    final claimed = state == _RadarOfferState.claimedElsewhere;
    final resolving = state == _RadarOfferState.resolving;
    final blockOtherOffers =
        _matchingOfferId != null && _matchingOfferId != trip.id;

    if (claimed) {
      final reason = _goneReasons[trip.id] ?? _RadarGone.unavailable;
      return Container(
        key: ValueKey(trip.id),
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE9EBEB),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              reason == _RadarGone.unavailable
                  ? Icons.event_busy_outlined
                  : Icons.wifi_off_rounded,
              size: 18,
              color: _muted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                switch (reason) {
                  _RadarGone.lostOwnMatch => 'Another driver got it first',
                  _RadarGone.unavailable => 'No longer available',
                },
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              trip.fare,
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

    final matchButton = SizedBox(
      height: 46,
      child: FilledButton(
        onPressed: resolving || blockOtherOffers ? null : () => _matchTrip(trip),
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: _ink,
          disabledBackgroundColor: const Color(0xFFD9DEDF),
          foregroundColor: Colors.white,
          disabledForegroundColor: const Color(0xFF727E83),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            : const Text(
                'Match',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
      ),
    );

    return Material(
      key: ValueKey(trip.id),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _line, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
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
                          trip.fare,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
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
                              : '${trip.category} · ${trip.pickupMinutes} min away · ${trip.tripKm.toStringAsFixed(1)} km ride',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _muted, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.star_rounded, size: 16, color: Color(0xFFD7A02C)),
                  const SizedBox(width: 2),
                  Text(
                    trip.rating,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _routeRow(
                square: false,
                label: 'Pickup',
                place: trip.pickup,
                value: '${trip.pickupMinutes} min',
                detail: '${trip.pickupKm.toStringAsFixed(1)} km away',
              ),
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(width: 2, height: 12, color: _line),
                ),
              ),
              _routeRow(
                square: true,
                label: 'Drop-off',
                place: trip.dropoff,
                value: '${trip.tripMinutes} min',
                detail: '${trip.tripKm.toStringAsFixed(1)} km ride',
              ),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: matchButton),
            ],
          ),
      ),
    );
  }

  Widget _routeRow({
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
            color: square ? _ink : Colors.white,
            shape: square ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: square ? BorderRadius.circular(2) : null,
            border: square ? null : Border.all(color: _ink, width: 3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: _muted, fontSize: 11.5)),
              Text(
                place,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
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
                color: _ink,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(detail, style: const TextStyle(color: _muted, fontSize: 11.5)),
          ],
        ),
      ],
    );
  }

  Widget _buildMatchNotice(_RadarMatchNotice notice) {
    final isMatching = notice.type == _RadarMatchNoticeType.matching;
    final isSuccess = notice.type == _RadarMatchNoticeType.success;
    final accent = isSuccess
        ? const Color(0xFF2FBE7B)
        : isMatching
            ? const Color(0xFFD99B24)
            : const Color(0xFFC75B62);

    return TripStatusBanner(
      key: const ValueKey<String>('radar-match-notice'),
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

  Widget _emptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.radar_rounded, color: _muted, size: 30),
            SizedBox(height: 12),
            Text(
              'Scanning nearby',
              style: TextStyle(
                color: _ink,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'New trips will appear here when the radar finds requests around you.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

/// Why a Radar trip is leaving the list.
enum _RadarGone {
  /// This driver tapped Match and another driver won.
  lostOwnMatch,

  /// Expired, cancelled by the rider or gone from Radar for another reason.
  unavailable,
}

enum _RadarOfferState { available, resolving, claimedElsewhere }

enum _RadarMatchNoticeType { matching, success, error }

class _RadarMatchNotice {
  const _RadarMatchNotice({
    required this.type,
    required this.title,
    required this.message,
  });

  final _RadarMatchNoticeType type;
  final String title;
  final String message;
}

class _RadarTrip {
  const _RadarTrip({
    required this.id,
    required this.category,
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
    required this.isNearby,
    this.followsDestination = false,
  });

  final String id;
  final String category;
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
  final bool isNearby;
  final bool followsDestination;
}

class _LiveDot extends StatelessWidget {
  final double size;
  final bool dark;

  const _LiveDot({
    this.size = 8,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark ? _RideRequestsState._green : _RideRequestsState._mint,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (dark ? _RideRequestsState._green : _RideRequestsState._mint)
                .withValues(alpha: 0.38),
            blurRadius: 7,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
