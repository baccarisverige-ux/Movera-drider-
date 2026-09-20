import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeDirectOffer {
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
  const HomeDirectOffer({
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
  });
}

const HomeDirectOffer kVeryCloseDirectOffer = HomeDirectOffer(
    id: 'home-direct-close',
    category: 'Comfort',
    reason: 'Very close to you',
    detail: 'Direct request outside radar',
    fare: '104,80 kr',
    rating: '4.96',
    pickupMinutes: 3,
    pickupKm: 0.9,
    tripMinutes: 14,
    tripKm: 7.6,
    pickup: 'Kungsgatan 42, Stockholm',
    dropoff: 'Hornstull, Stockholm',
    pickupPosition: LatLng(59.3343, 18.0615),
    dropoffPosition: LatLng(59.3157, 18.0335),
  );
const HomeDirectOffer kExpandedDirectOffer = HomeDirectOffer(
    id: 'home-direct-expanded',
    category: 'Premium',
    reason: 'Expanded request',
    detail: 'No nearby radar driver matched',
    fare: '176,20 kr',
    rating: '4.98',
    pickupMinutes: 8,
    pickupKm: 3.3,
    tripMinutes: 21,
    tripKm: 13.8,
    pickup: 'Odengatan 63, Stockholm',
    dropoff: 'Solna centrum, Solna',
    pickupPosition: LatLng(59.3449, 18.0472),
    dropoffPosition: LatLng(59.3603, 18.0009),
  );
