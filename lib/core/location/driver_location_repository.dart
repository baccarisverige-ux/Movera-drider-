import 'package:geolocator/geolocator.dart';

abstract interface class DriverLocationRepository {
  Future<Position> getCurrentPosition();

  Stream<Position> watchPosition({
    int distanceFilterMeters = 8,
  });
}
