import 'package:movera/core/contracts/trip_status.dart';

/// Server-owned state boundary. No production implementation is installed.
class DriverTripProjection {
  const DriverTripProjection({required this.tripId,required this.status,required this.version});
  final String tripId;
  final TripStatus status;
  final int version;
}

abstract interface class DriverTripGateway {
  Future<DriverTripProjection> getTrip(String tripId);
  Future<DriverTripProjection> acceptOffer(String offerId,{required String idempotencyKey});
  Future<DriverTripProjection> arrive(String tripId,{required int expectedVersion,required String idempotencyKey});
  Future<DriverTripProjection> start(String tripId,{required int expectedVersion,required String idempotencyKey,String? verifiedPinToken});
  Future<DriverTripProjection> complete(String tripId,{required int expectedVersion,required String idempotencyKey});
  Future<DriverTripProjection> cancel(String tripId,{required int expectedVersion,required String idempotencyKey,required String reasonCode});
}
