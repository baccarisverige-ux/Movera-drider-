import 'dart:async';

import 'package:movera/core/dispatch/dispatch_repository.dart';
import 'package:movera/core/geo/geo_point.dart';

/// Frontend/demo dispatch. A backend implementation replaces this class.
///
/// nearby-2 is the only demo offer that loses the atomic claim race.
class DemoDispatchRepository implements DispatchRepository {
  DemoDispatchRepository({
    Duration claimDelay = const Duration(milliseconds: 1450),
    this.losingOfferId = 'nearby-2',
  }) : _claimDelay = claimDelay;

  final Duration _claimDelay;
  final String losingOfferId;

  final StreamController<List<RideOffer>> _nearby =
      StreamController<List<RideOffer>>.broadcast();
  final StreamController<List<RideOffer>> _nextTrip =
      StreamController<List<RideOffer>>.broadcast();

  List<RideOffer> _offers = List<RideOffer>.from(_seedOffers);

  static const List<RideOffer> _seedOffers = [
    RideOffer(
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
      pickupPosition: GeoPoint(59.3295, 18.0475),
      dropoffPosition: GeoPoint(59.2705, 18.0515),
      isNearby: true,
      followsDestination: false,
    ),
    RideOffer(
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
      pickupPosition: GeoPoint(59.3316, 18.0592),
      dropoffPosition: GeoPoint(59.3125, 18.0750),
      isNearby: true,
      followsDestination: true,
    ),
    RideOffer(
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
      pickupPosition: GeoPoint(59.3332, 18.0916),
      dropoffPosition: GeoPoint(59.3599, 18.0002),
      isNearby: true,
      followsDestination: true,
    ),
  ];

  @override
  Stream<List<RideOffer>> watchNearbyOffers({
    bool destinationModeActive = false,
  }) {
    Future<void>.microtask(() => _emitNearby(destinationModeActive));
    return _nearby.stream.map((offers) {
      if (!destinationModeActive) return offers;
      return offers.where((offer) => offer.followsDestination).toList();
    });
  }

  @override
  Stream<List<RideOffer>> watchNextTripOffers() {
    Future<void>.microtask(() {
      if (!_nextTrip.isClosed) {
        _nextTrip.add(const <RideOffer>[]);
      }
    });
    return _nextTrip.stream;
  }

  @override
  Future<ClaimResult> claimOffer(String offerId) async {
    await Future<void>.delayed(_claimDelay);
    RideOffer? offer;
    for (final item in _offers) {
      if (item.id == offerId) {
        offer = item;
        break;
      }
    }
    if (offer == null) {
      return const ClaimResult.unavailable();
    }
    if (offerId == losingOfferId) {
      return const ClaimResult.alreadyClaimed();
    }
    _offers = _offers.where((item) => item.id != offerId).toList();
    return ClaimResult.success(offer);
  }

  @override
  void refreshOffers() {
    _emitNearby(false);
  }

  void _emitNearby(bool destinationModeActive) {
    if (_nearby.isClosed) return;
    _nearby.add(List<RideOffer>.unmodifiable(_offers));
  }

  void dispose() {
    _nearby.close();
    _nextTrip.close();
  }
}
