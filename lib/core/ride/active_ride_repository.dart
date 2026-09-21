enum ActiveRideStage {
  headingToPickup,
  waitingForRider,
  onTrip,
}

/// Queued next trip captured with the live ride so a reload can resume both.
class PersistedQueuedTrip {
  const PersistedQueuedTrip({
    required this.tripId,
    required this.riderName,
    required this.fare,
    required this.category,
    required this.pickup,
    required this.dropoff,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    this.rating = 4.9,
    this.pickupMinutes = 4,
    this.tripMinutes = 16,
  });

  final String tripId;
  final String riderName;
  final String fare;
  final String category;
  final String pickup;
  final String dropoff;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final double rating;
  final int pickupMinutes;
  final int tripMinutes;

  Map<String, dynamic> toJson() => {
        'tripId': tripId,
        'riderName': riderName,
        'fare': fare,
        'category': category,
        'pickup': pickup,
        'dropoff': dropoff,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'dropoffLat': dropoffLat,
        'dropoffLng': dropoffLng,
        'rating': rating,
        'pickupMinutes': pickupMinutes,
        'tripMinutes': tripMinutes,
      };

  static PersistedQueuedTrip? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final tripId = json['tripId'] as String?;
    if (tripId == null || tripId.isEmpty) return null;
    return PersistedQueuedTrip(
      tripId: tripId,
      riderName: json['riderName'] as String? ?? '',
      fare: json['fare'] as String? ?? '—',
      category: json['category'] as String? ?? 'Movera',
      pickup: json['pickup'] as String? ?? '',
      dropoff: json['dropoff'] as String? ?? '',
      pickupLat: (json['pickupLat'] as num?)?.toDouble() ?? 59.3328,
      pickupLng: (json['pickupLng'] as num?)?.toDouble() ?? 18.0587,
      dropoffLat: (json['dropoffLat'] as num?)?.toDouble() ?? 59.3142,
      dropoffLng: (json['dropoffLng'] as num?)?.toDouble() ?? 18.0735,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
      pickupMinutes: (json['pickupMinutes'] as num?)?.toInt() ?? 4,
      tripMinutes: (json['tripMinutes'] as num?)?.toInt() ?? 16,
    );
  }
}

class PersistedActiveRide {
  const PersistedActiveRide({
    required this.tripId,
    required this.stage,
    this.nextTripId,
    this.arrivedAt,
    this.startedAt,
    this.savedAt,
    this.riderName,
    this.riderRating,
    this.riderTrips,
    this.fare,
    this.category,
    this.matchedVia,
    this.pickupAddress,
    this.pickupArea,
    this.dropoffAddress,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.waitSeconds,
    this.next,
  });

  final String tripId;
  final ActiveRideStage stage;
  final String? nextTripId;
  final DateTime? arrivedAt;
  final DateTime? startedAt;
  final DateTime? savedAt;
  final String? riderName;
  final double? riderRating;
  final int? riderTrips;
  final String? fare;
  final String? category;
  final String? matchedVia;
  final String? pickupAddress;
  final String? pickupArea;
  final String? dropoffAddress;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final int? waitSeconds;
  final PersistedQueuedTrip? next;

  /// How long a saved live trip may sit untouched and still be restored.
  ///
  /// A Stockholm trip can outlive a short window if the driver backgrounds
  /// the PWA. Six hours matches Rider's active-ride snapshot.
  static const freshnessWindow = Duration(hours: 6);

  bool get isFresh {
    final at = savedAt;
    if (at == null) return true;
    return DateTime.now().difference(at) < freshnessWindow;
  }

  PersistedActiveRide stamped([DateTime? at]) {
    return PersistedActiveRide(
      tripId: tripId,
      stage: stage,
      nextTripId: nextTripId ?? next?.tripId,
      arrivedAt: arrivedAt,
      startedAt: startedAt,
      savedAt: at ?? DateTime.now(),
      riderName: riderName,
      riderRating: riderRating,
      riderTrips: riderTrips,
      fare: fare,
      category: category,
      matchedVia: matchedVia,
      pickupAddress: pickupAddress,
      pickupArea: pickupArea,
      dropoffAddress: dropoffAddress,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      waitSeconds: waitSeconds,
      next: next,
    );
  }

  Map<String, dynamic> toJson() => {
        'tripId': tripId,
        'stage': stage.name,
        if (nextTripId != null || next != null)
          'nextTripId': nextTripId ?? next?.tripId,
        if (arrivedAt != null) 'arrivedAt': arrivedAt!.toIso8601String(),
        if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
        if (savedAt != null) 'savedAt': savedAt!.toIso8601String(),
        if (riderName != null) 'riderName': riderName,
        if (riderRating != null) 'riderRating': riderRating,
        if (riderTrips != null) 'riderTrips': riderTrips,
        if (fare != null) 'fare': fare,
        if (category != null) 'category': category,
        if (matchedVia != null) 'matchedVia': matchedVia,
        if (pickupAddress != null) 'pickupAddress': pickupAddress,
        if (pickupArea != null) 'pickupArea': pickupArea,
        if (dropoffAddress != null) 'dropoffAddress': dropoffAddress,
        if (pickupLat != null) 'pickupLat': pickupLat,
        if (pickupLng != null) 'pickupLng': pickupLng,
        if (dropoffLat != null) 'dropoffLat': dropoffLat,
        if (dropoffLng != null) 'dropoffLng': dropoffLng,
        if (waitSeconds != null) 'waitSeconds': waitSeconds,
        if (next != null) 'next': next!.toJson(),
      };

  static PersistedActiveRide? fromJson(Map<String, dynamic> json) {
    final tripId = json['tripId'] as String?;
    if (tripId == null || tripId.isEmpty) return null;
    final stageName = json['stage'] as String?;
    final stage = ActiveRideStage.values.where((value) => value.name == stageName);
    if (stage.isEmpty) return null;
    final nextJson = json['next'];
    return PersistedActiveRide(
      tripId: tripId,
      stage: stage.first,
      nextTripId: json['nextTripId'] as String?,
      arrivedAt: DateTime.tryParse(json['arrivedAt'] as String? ?? ''),
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? ''),
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? ''),
      riderName: json['riderName'] as String?,
      riderRating: (json['riderRating'] as num?)?.toDouble(),
      riderTrips: (json['riderTrips'] as num?)?.toInt(),
      fare: json['fare'] as String?,
      category: json['category'] as String?,
      matchedVia: json['matchedVia'] as String?,
      pickupAddress: json['pickupAddress'] as String?,
      pickupArea: json['pickupArea'] as String?,
      dropoffAddress: json['dropoffAddress'] as String?,
      pickupLat: (json['pickupLat'] as num?)?.toDouble(),
      pickupLng: (json['pickupLng'] as num?)?.toDouble(),
      dropoffLat: (json['dropoffLat'] as num?)?.toDouble(),
      dropoffLng: (json['dropoffLng'] as num?)?.toDouble(),
      waitSeconds: (json['waitSeconds'] as num?)?.toInt(),
      next: nextJson is Map
          ? PersistedQueuedTrip.fromJson(Map<String, dynamic>.from(nextJson))
          : null,
    );
  }
}

/// Persistence boundary for active-trip recovery after app restart.
///
/// Memory-only controller state is not durable. This interface exists so
/// recovery can attach without rewriting screens. No backend is implied.
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
