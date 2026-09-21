import 'package:movera/core/ride/active_ride_repository.dart';

/// Canonical trip lifecycle (P1). Payment and rating are separate machines.
enum TripStatus {
  draft,
  quoted,
  requested,
  searching,
  offered,
  accepted,
  driverToPickup,
  arrived,
  riderOnboard,
  inTrip,
  approachingDropoff,
  completed,
  cancelledByRider,
  cancelledByDriver,
  cancelledByAdmin,
  noShow,
  expired,
  failed,
}

extension TripStatusWire on TripStatus {
  /// Snake_case value used in contracts and logs.
  String get wireName => switch (this) {
        TripStatus.draft => 'draft',
        TripStatus.quoted => 'quoted',
        TripStatus.requested => 'requested',
        TripStatus.searching => 'searching',
        TripStatus.offered => 'offered',
        TripStatus.accepted => 'accepted',
        TripStatus.driverToPickup => 'driver_to_pickup',
        TripStatus.arrived => 'arrived',
        TripStatus.riderOnboard => 'rider_onboard',
        TripStatus.inTrip => 'in_trip',
        TripStatus.approachingDropoff => 'approaching_dropoff',
        TripStatus.completed => 'completed',
        TripStatus.cancelledByRider => 'cancelled_by_rider',
        TripStatus.cancelledByDriver => 'cancelled_by_driver',
        TripStatus.cancelledByAdmin => 'cancelled_by_admin',
        TripStatus.noShow => 'no_show',
        TripStatus.expired => 'expired',
        TripStatus.failed => 'failed',
      };
}

extension ActiveRideStageAsTripStatus on ActiveRideStage {
  TripStatus get tripStatus => switch (this) {
        ActiveRideStage.headingToPickup => TripStatus.driverToPickup,
        ActiveRideStage.waitingForRider => TripStatus.arrived,
        ActiveRideStage.onTrip => TripStatus.inTrip,
      };
}
