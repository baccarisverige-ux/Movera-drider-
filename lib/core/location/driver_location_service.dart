import 'package:geolocator/geolocator.dart';
import 'package:movera/core/location/driver_location_repository.dart';

class DriverLocationException implements Exception {
  const DriverLocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DriverLocationService implements DriverLocationRepository {
  const DriverLocationService();

  Future<Position> getCurrentPosition() async {
    await _ensurePermission();

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      ),
    );
  }

  Stream<Position> watchPosition({
    int distanceFilterMeters = 8,
  }) async* {
    await _ensurePermission();

    yield* Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: distanceFilterMeters,
      ),
    );
  }

  Future<void> _ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const DriverLocationException(
        'Location services are turned off.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const DriverLocationException(
        'Location permission was denied.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const DriverLocationException(
        'Location permission is blocked in device settings.',
      );
    }
  }
}
