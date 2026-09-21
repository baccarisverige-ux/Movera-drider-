import 'package:movera/core/session/driver_session_controller.dart';

/// Driver profile owned by a future backend. Screens keep their own copy.
class DriverProfile {
  const DriverProfile({
    required this.driverId,
    required this.displayName,
    required this.phone,
    required this.rating,
    required this.city,
    required this.status,
  });

  final String driverId;
  final String displayName;
  final String phone;
  final double rating;
  final String city;
  final DriverOnlineStatus status;

  DriverProfile copyWith({DriverOnlineStatus? status}) {
    return DriverProfile(
      driverId: driverId,
      displayName: displayName,
      phone: phone,
      rating: rating,
      city: city,
      status: status ?? this.status,
    );
  }
}

abstract interface class DriverProfileRepository {
  DriverProfile? get current;

  Future<DriverProfile> load();

  Future<void> save(DriverProfile profile);
}

class InMemoryDriverProfileRepository implements DriverProfileRepository {
  InMemoryDriverProfileRepository({DriverProfile? seed}) : _current = seed;

  DriverProfile? _current;

  @override
  DriverProfile? get current => _current;

  @override
  Future<DriverProfile> load() async {
    return _current ??= const DriverProfile(
      driverId: 'D-418',
      displayName: 'Movera Driver',
      phone: '+46 70 123 45 67',
      rating: 4.92,
      city: 'Stockholm',
      status: DriverOnlineStatus.offline,
    );
  }

  @override
  Future<void> save(DriverProfile profile) async {
    _current = profile;
  }
}
