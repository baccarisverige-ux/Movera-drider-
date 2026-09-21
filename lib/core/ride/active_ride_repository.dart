import 'package:movera/core/ride/active_ride_controller.dart';

class PersistedActiveRide {
  const PersistedActiveRide({
    required this.tripId,
    required this.stage,
    this.nextTripId,
    this.arrivedAt,
    this.startedAt,
  });

  final String tripId;
  final ActiveRideStage stage;
  final String? nextTripId;
  final DateTime? arrivedAt;
  final DateTime? startedAt;
}

/// Persistence boundary for active-trip recovery after app restart.
///
/// Memory-only controller state is not durable. Backend is the source of
/// truth once connected; this interface exists so recovery can be added
/// without rewriting screens.
abstract interface class ActiveRideRepository {
  Future<PersistedActiveRide?> read();

  Future<void> save(PersistedActiveRide ride);

  Future<void> clear();
}

class MemoryActiveRideRepository implements ActiveRideRepository {
  PersistedActiveRide? _ride;

  @override
  Future<PersistedActiveRide?> read() async => _ride;

  @override
  Future<void> save(PersistedActiveRide ride) async {
    _ride = ride;
  }

  @override
  Future<void> clear() async {
    _ride = null;
  }
}
