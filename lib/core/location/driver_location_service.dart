import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/location/driver_location_repository.dart';
import 'package:movera/core/logging/driver_log.dart';

class DriverLocationException implements Exception {
  const DriverLocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DriverLocationService implements DriverLocationRepository {
  const DriverLocationService();

  LocationSettings get _settings => LocationSettings(
        accuracy: kIsWeb
            ? LocationAccuracy.high
            : LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 8),
      );

  @override
  Future<DriverLocation> getCurrentPosition() async {
    await _ensurePermission();

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _settings,
      );
      return _toDriverLocation(position);
    } catch (error, stack) {
      DriverLog.warn('Current GPS failed, trying last known: $error');
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return _toDriverLocation(last);
      DriverLog.error('No GPS fix available', error, stack);
      rethrow;
    }
  }

  @override
  Stream<DriverLocation> watchPosition({
    int distanceFilterMeters = 8,
  }) async* {
    await _ensurePermission();

    yield* Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: kIsWeb
            ? LocationAccuracy.high
            : LocationAccuracy.bestForNavigation,
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
