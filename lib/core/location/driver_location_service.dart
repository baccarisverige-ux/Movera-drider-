import 'package:geolocator/geolocator.dart';
import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/location/driver_location_repository.dart';

class DriverLocationException implements Exception {
  const DriverLocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DriverLocationService implements DriverLocationRepository {
  const DriverLocationService();

  @override
  Future<DriverLocation> getCurrentPosition() async {
    await _ensurePermission();

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      ),
    );
    return _toDriverLocation(position);
  }

  @override
  Stream<DriverLocation> watchPosition({
    int distanceFilterMeters = 8,
  }) async* {
    await _ensurePermission();

    yield* Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: distanceFilterMeters,
      ),
    ).map(_toDriverLocation);
  }

  DriverLocation _toDriverLocation(Position position) {
    return DriverLocation(
      point: GeoPoint(position.latitude, position.longitude),
      headingDegrees: position.heading,
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
