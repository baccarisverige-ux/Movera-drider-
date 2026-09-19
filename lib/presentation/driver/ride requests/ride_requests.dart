import 'dart:async';

import 'package:flutter/material.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/presentation/driver/accept%20ride/accept_ride.dart';
import 'package:movera/widgets/navigation_transition.dart';

class RideRequests extends StatefulWidget {
  final VoidCallback? onCloseRides;

  const RideRequests({super.key, this.onCloseRides});

  @override
  State<RideRequests> createState() => _RideRequestsState();
}

class _RideRequestsState extends State<RideRequests> {
  static const Color _screen = Color(0xFF202529);
  static const Color _surface = Color(0xFFF7F8F9);
  static const Color _ink = Color(0xFF252E3A);
  static const Color _muted = Color(0xFF7D898F);
  static const Color _line = Color(0xFFE4E8EA);
  static const Color _green = Color(0xFF19865C);
  static const Color _mint = Color(0xFF58E5A6);

  Timer? _newTripSignalTimer;
  Timer? _availabilityTimer;
  bool _hasNewTripSignal = false;

  final List<_RadarTrip> _offers = [
    const _RadarTrip(
      id: 'nearby-1',
      category: 'Comfort',
      fare: '111,02 kr',
      rating: '4.95',
      pickupMinutes: 7,
      pickupKm: 2.1,
      tripMinutes: 15,
      tripKm: 10.5,
      pickup: 'Hantverkargatan 4, Stockholm',
      dropoff: 'Trollesundsvägen 58B, Bandhagen',
      isNearby: true,
    ),
    const _RadarTrip(
      id: 'nearby-2',
      category: 'Movera',
      fare: '96,40 kr',
      rating: '4.91',
      pickupMinutes: 5,
      pickupKm: 1.4,
      tripMinutes: 18,
      tripKm: 8.7,
      pickup: 'Klarabergsgatan, Stockholm',
      dropoff: 'Ringvägen, Södermalm',
      isNearby: true,
    ),
    const _RadarTrip(
      id: 'nearby-3',
      category: 'Premium',
      fare: '184,60 kr',
      rating: '4.98',
      pickupMinutes: 9,
      pickupKm: 3.6,
      tripMinutes: 22,
      tripKm: 14.2,
      pickup: 'Strandvägen, Stockholm',
      dropoff: 'Solna centrum, Solna',
      isNearby: true,
    ),
    const _RadarTrip(
      id: 'outside-area',
      category: 'Priority',
      fare: '210,00 kr',
      rating: '4.89',
      pickupMinutes: 34,
      pickupKm: 31.0,
      tripMinutes: 17,
      tripKm: 11.8,
      pickup: 'Outside local radar area',
      dropoff: 'Stockholm',
      isNearby: false,
    ),
  ];

  final List<_RadarTrip> _pendingNearbyOffers = [
    const _RadarTrip(
      id: 'nearby-4',
      category: 'Priority',
      fare: '128,70 kr',
      rating: '4.93',
      pickupMinutes: 4,
      pickupKm: 1.1,
      tripMinutes: 13,
      tripKm: 7.4,
      pickup: 'Vasagatan, Stockholm',
      dropoff: 'Gärdet, Stockholm',
      isNearby: true,
    ),
    const _RadarTrip(
      id: 'nearby-5',
      category: 'Electric',
      fare: '139,20 kr',
      rating: '4.97',
      pickupMinutes: 8,
      pickupKm: 2.9,
      tripMinutes: 20,
      tripKm: 12.1,
      pickup: 'Odengatan, Stockholm',
      dropoff: 'Liljeholmen, Stockholm',
      isNearby: true,
    ),
  ];

  List<_RadarTrip> get _visibleOffers {
    final nearby = _offers.where((offer) => offer.isNearby).toList()
      ..sort((a, b) => a.pickupKm.compareTo(b.pickupKm));
    return nearby;
  }

  @override
  void initState() {
    super.initState();

    // Frontend-only signal simulation. A real backend/realtime source should
    // set this flag when new nearby requests arrive. The list itself stays on
    // this screen until the driver explicitly refreshes after that signal.
    _newTripSignalTimer = Timer(const Duration(seconds: 7), () {
      if (!mounted) return;
      setState(() {
        _hasNewTripSignal = true;
      });
    });

    // Frontend-only availability simulation. In production, "claimed by
    // another driver" and "cancelled by rider" events remove the matching
    // offer immediately. Once removed, its Match action no longer exists.
    _availabilityTimer = Timer(const Duration(seconds: 13), () {
      if (!mounted) return;
      setState(() {
        _offers.removeWhere((offer) => offer.id == 'nearby-3');
      });
    });
  }

  @override
  void dispose() {
    _newTripSignalTimer?.cancel();
    _availabilityTimer?.cancel();
    super.dispose();
  }

  void _refreshFromRadarSignal() {
    if (!_hasNewTripSignal) return;

    setState(() {
      final existingIds = _offers.map((offer) => offer.id).toSet();
      for (final offer in _pendingNearbyOffers) {
        if (offer.isNearby && !existingIds.contains(offer.id)) {
          _offers.add(offer);
        }
      }
      _hasNewTripSignal = false;
    });
  }

  void _matchTrip(_RadarTrip trip) {
    if (!_offers.any((offer) => offer.id == trip.id && offer.isNearby)) {
      return;
    }

    Navigator.push(
      context,
      BottomToTopTransition(const AcceptRide()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offers = _visibleOffers;

    return Material(
      color: _screen,
      child: SafeArea(
        child: Column(
          children: [
            _topBar(),
            _radarStatus(offers.length),
            if (_hasNewTripSignal) _newTripsBanner(),
            Expanded(
              child: offers.isEmpty
                  ? _emptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: offers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _tripCard(offers[index], index);
                      },
                    ),
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
              onPressed: widget.onCloseRides,
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nearby trips',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Only requests around your current area',
                style: TextStyle(
                  color: Color(0xFFAEB8BD),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
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

  Widget _tripCard(_RadarTrip trip, int index) {
    return Container(
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
                  trip.category,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                trip.fare,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 25,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
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
              Text(
                '${trip.pickupMinutes} min · ${trip.pickupKm.toStringAsFixed(1)} km away',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
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
                  onPressed: () => _matchTrip(trip),
                  style: FilledButton.styleFrom(
                    elevation: 0,
                    backgroundColor: _ink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Match',
                    style: TextStyle(
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
    required this.isNearby,
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
  final bool isNearby;
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
