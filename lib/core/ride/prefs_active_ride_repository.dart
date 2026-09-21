import 'dart:convert';

import 'package:movera/core/logging/driver_log.dart';
import 'package:movera/core/ride/active_ride_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Durable [ActiveRideRepository] backed by SharedPreferences.
///
/// On Flutter web this is `localStorage` key `flutter.movera_driver_active_ride`.
/// Stale snapshots older than [PersistedActiveRide.freshnessWindow] are dropped
/// so an abandoned trip cannot revive days later.
class PrefsActiveRideRepository implements ActiveRideRepository {
  PrefsActiveRideRepository({
    Future<SharedPreferences> Function()? load,
  }) : _load = load ?? SharedPreferences.getInstance;

  /// SharedPreferences key. Web localStorage prefix is `flutter.`.
  static const key = 'movera_driver_active_ride';

  final Future<SharedPreferences> Function() _load;

  /// Bumped on every [clear] so an in-flight [save] cannot revive a cancelled trip.
  int _epoch = 0;

  @override
  Future<PersistedActiveRide?> read() async {
    try {
      final prefs = await _load();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final ride = PersistedActiveRide.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (ride == null || !ride.isFresh) {
        await prefs.remove(key);
        return null;
      }
      return ride;
    } catch (error, stack) {
      DriverLog.warn('Active-ride snapshot unreadable: $error');
      DriverLog.error('Active-ride snapshot parse failed', error, stack);
      return null;
    }
  }

  @override
  Future<void> save(PersistedActiveRide ride) async {
    try {
      final token = _epoch;
      final prefs = await _load();
      if (token != _epoch) return;
      final stamped = ride.stamped();
      await prefs.setString(key, jsonEncode(stamped.toJson()));
      if (token != _epoch) {
        await prefs.remove(key);
      }
    } catch (error, stack) {
      DriverLog.warn('Active-ride snapshot save failed: $error');
      DriverLog.error('Active-ride snapshot save failed', error, stack);
    }
  }

  @override
  Future<void> clear() async {
    _epoch += 1;
    try {
      final prefs = await _load();
      await prefs.remove(key);
    } catch (error, stack) {
      DriverLog.warn('Active-ride snapshot clear failed: $error');
      DriverLog.error('Active-ride snapshot clear failed', error, stack);
    }
  }
}
