import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/core/geo/geo_point_maps.dart';
import 'package:movera/core/dispatch/demo_dispatch_repository.dart';
import 'package:movera/core/dispatch/dispatch_repository.dart';
import 'package:movera/core/location/driver_location_repository.dart';
import 'package:movera/core/routing/route_repository.dart';
import 'package:movera/core/session/driver_session_controller.dart';
import 'package:movera/core/waybill/waybill.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/presentation/driver/accept%20ride/accept_ride.dart';
import 'package:movera/presentation/driver/overlays/trip_status_banner.dart';
import 'package:movera/widgets/layout_viewport.dart';
import 'package:movera/widgets/navigation_transition.dart';

class RideRequests extends StatefulWidget {
  final ValueChanged<bool>? onCloseRides;
  final bool destinationModeActive;
  final String? destinationAddress;
  final DriverSessionController? sessionController;
  final WaybillRepository? waybillRepository;
  final DriverLocationRepository? locationRepository;
  final RouteRepository? routeRepository;
  final DispatchRepository? dispatchRepository;

  const RideRequests({
    super.key,
    this.onCloseRides,
    this.destinationModeActive = false,
    this.destinationAddress,
    this.sessionController,
    this.waybillRepository,
    this.locationRepository,
    this.routeRepository,
    this.dispatchRepository,
  });

  @override
  State<RideRequests> createState() => _RideRequestsState();
}

class _RideRequestsState extends State<RideRequests> {
  static const Color _surface = Color(0xFFF7F8F9);
  static const Color _ink = Color(0xFF252E3A);
  static const Color _muted = Color(0xFF7D898F);
  static const Color _line = Color(0xFFE4E8EA);
  static const Color _green = Color(0xFF19865C);
  static const Color _mint = Color(0xFF58E5A6);
  static const int _maxVisibleRadarOffers = 10;

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
  List<_RadarTrip> get _visibleOffers {
    final nearby = _offers.where((offer) {
      if (!offer.isNearby) return false;
      if (!widget.destinationModeActive) return true;
      return offer.followsDestination;
    }).toList()
      ..sort((a, b) => a.pickupKm.compareTo(b.pickupKm));
    return nearby.take(_maxVisibleRadarOffers).toList(growable: false);
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
    if (!mounted) return;
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
      _markClaimedElsewhere(trip, showNotice: false);
    }
  }

  void _refreshFromRadarSignal() {
    if (!_hasNewTripSignal) return;

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
    widget.onCloseRides?.call(_visibleOffers.isNotEmpty);
  }

  _RadarOfferState _stateFor(String id) =>
      _offerStates[id] ?? _RadarOfferState.available;

  bool _isOfferStillVisible(_RadarTrip trip) {
    return _offers.any((offer) {
      if (offer.id != trip.id || !offer.isNearby) return false;
      if (!widget.destinationModeActive) return true;
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
    final result = await _dispatch.claimOffer(trip.id);
    if (!mounted || _matchingOfferId != trip.id) return;

    if (result.isSuccess) {
      _resolveMatchWon(trip);
    } else {
      _resolveMatchLost(trip);
    }
  }

  void _resolveMatchWon(_RadarTrip trip) {
    _matchNoticeTimer?.cancel();

    setState(() {
      _matchingOfferId = null;
      _offers.removeWhere((offer) => offer.id == trip.id);
      _offerStates.remove(trip.id);
      _matchNotice = const _RadarMatchNotice(
        type: _RadarMatchNoticeType.success,
        title: 'Trip matched',
        message: 'You’re assigned to this request. Opening trip…',
      );
    });

    _matchNoticeTimer = Timer(
      const Duration(milliseconds: 500),
      () {
        if (!mounted) return;
        final navigator = Navigator.of(context);
        final ride = AcceptRide(
          offerId: trip.id,
          fare: trip.fare,
          category: trip.category,
          matchedVia: 'Movera Radar',
          sessionController: widget.sessionController,
          waybillRepository: widget.waybillRepository,
          locationRepository: widget.locationRepository,
          routeRepository: widget.routeRepository,
          pickupAddress: trip.pickup,
          pickupArea: trip.pickup.split(',').last.trim(),
          dropoffAddress: trip.dropoff,
          pickupPosition: trip.pickupPosition,
          dropoffPosition: trip.dropoffPosition,
        );
        navigator.push(BottomToTopTransition(ride));
        if (mounted) {
          setState(() => _matchNotice = null);
        }
      },
    );
  }

  void _resolveMatchLost(_RadarTrip trip) {
    setState(() {
      _matchingOfferId = null;
      _offerStates[trip.id] = _RadarOfferState.claimedElsewhere;
      _matchNotice = const _RadarMatchNotice(
        type: _RadarMatchNoticeType.taken,
        title: 'Request taken',
        message: 'Another driver was matched first. Choose another trip.',
      );
    });

    _scheduleClaimedRemoval(trip.id);

    _matchNoticeTimer?.cancel();
    _matchNoticeTimer = Timer(
      const Duration(milliseconds: 2600),
      () {
        if (!mounted) return;
        setState(() => _matchNotice = null);
      },
    );
  }

  void _markClaimedElsewhere(
    _RadarTrip trip, {
    bool showNotice = true,
  }) {
    if (!_isOfferStillVisible(trip) ||
        _stateFor(trip.id) != _RadarOfferState.available) {
      return;
    }

    setState(() {
      _offerStates[trip.id] = _RadarOfferState.claimedElsewhere;
      if (showNotice) {
        _matchNotice = const _RadarMatchNotice(
          type: _RadarMatchNoticeType.taken,
          title: 'Request taken',
          message: 'This trip was matched with another driver.',
        );
      }
    });

    _scheduleClaimedRemoval(trip.id);
  }

  void _scheduleClaimedRemoval(String id) {
    _claimedRemovalTimers.remove(id)?.cancel();
    _claimedRemovalTimers[id] = Timer(
      const Duration(milliseconds: 2800),
      () {
        if (!mounted) return;
        setState(() {
          _offers.removeWhere((offer) => offer.id == id);
          _offerStates.remove(id);
        });
        _claimedRemovalTimers.remove(id);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final offers = _visibleOffers;

    return LayoutViewport(
      child: Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: Column(
              children: [
                _topBar(),
                _radarStatus(offers.length),
                if (widget.destinationModeActive) _destinationModeBanner(),
                if (_hasNewTripSignal) _newTripsBanner(),
                Expanded(
                  child: offers.isEmpty
                      ? _emptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                          physics: const BouncingScrollPhysics(),
                          itemCount: offers.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
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
      padding: const EdgeInsets.fromLTRB(6, 7, 12, 2),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: _closeRides,
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const Expanded(
              child: Text(
                'Trip radar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.35,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LiveDot(size: 7),
                  SizedBox(width: 6),
                  Text(
                    'ON',
                    style: TextStyle(
                      color: Color(0xFFDDE7E3),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _radarStatus(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 7, 18, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.destinationModeActive
                      ? 'Along your destination'
                      : 'Nearby trips',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.destinationModeActive
                      ? 'Only trips that keep you moving the same way'
                      : 'Only requests around your current area',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFAEB8BD),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            constraints: const BoxConstraints(minWidth: 34),
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(17),
            ),
            alignment: Alignment.center,
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        key: const ValueKey<String>('radar-destination-filter'),
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        decoration: BoxDecoration(
          color: const Color(0xFFE7F5EE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.near_me_rounded,
              color: _green,
              size: 17,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Trips toward $label',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _newTripsBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Material(
        color: const Color(0xFFE7F5EE),
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: _refreshFromRadarSignal,
          borderRadius: BorderRadius.circular(17),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 10, 11, 10),
            child: Row(
              children: [
                const _LiveDot(size: 8, dark: true),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'New nearby trips detected',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _ink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Refresh',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: claimed ? 0.68 : 1,
      child: Container(
      key: ValueKey(trip.id),
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 13),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.65)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.11),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9EEF1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    trip.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  trip.fare,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 25,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFD7A02C),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                trip.rating,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              const SizedBox(
                height: 13,
                child: VerticalDivider(width: 1, color: _line),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.near_me_outlined,
                size: 15,
                color: AppColor.primary,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${trip.pickupMinutes} min · ${trip.pickupKm.toStringAsFixed(1)} km away',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _line),
          const SizedBox(height: 13),
          _locationRow(
            markerColor: AppColor.primary,
            title: trip.pickup,
          ),
          const SizedBox(height: 10),
          _locationRow(
            markerColor: _ink,
            title: trip.dropoff,
          ),
          const SizedBox(height: 13),
          if (claimed || resolving) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: claimed
                    ? const Color(0xFFF0F2F3)
                    : const Color(0xFFFFF3DE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    claimed
                        ? Icons.lock_outline_rounded
                        : Icons.sync_rounded,
                    size: 15,
                    color: claimed
                        ? const Color(0xFF7D898F)
                        : const Color(0xFFB87512),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    claimed
                        ? 'Matched by another driver'
                        : 'Confirming availability',
                    style: TextStyle(
                      color: claimed
                          ? const Color(0xFF68747A)
                          : const Color(0xFF9A650F),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  '${trip.tripMinutes} min · ${trip.tripKm.toStringAsFixed(1)} km trip',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(
                height: 38,
                child: FilledButton(
                  onPressed: claimed || resolving || blockOtherOffers
                      ? null
                      : () => _matchTrip(trip),
                  style: FilledButton.styleFrom(
                    elevation: 0,
                    backgroundColor: _ink,
                    disabledBackgroundColor: const Color(0xFFD9DEDF),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: const Color(0xFF727E83),
                    padding: const EdgeInsets.symmetric(horizontal: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
    );
  }

  Widget _locationRow({
    required Color markerColor,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _surface,
            border: Border.all(color: markerColor, width: 2.5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Icon(
                Icons.radar_rounded,
                color: Color(0xFFB8C2C7),
                size: 27,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Scanning nearby',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'New trips will appear here when the radar finds requests around you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFAEB8BD),
                fontSize: 11.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _RadarOfferState { available, resolving, claimedElsewhere }

enum _RadarMatchNoticeType { matching, success, taken }

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
                .withOpacity(0.38),
            blurRadius: 7,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
