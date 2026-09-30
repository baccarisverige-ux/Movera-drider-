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
  PrefsActiveRideRepository({Future<SharedPreferences> Function()? load})
    : _load = load ?? SharedPreferences.getInstance;

  /// SharedPreferences key. Web localStorage prefix is `flutter.`.
  static const key = 'movera_driver_active_ride';

  final Future<SharedPreferences> Function() _load;

  // SharedPreferences operations are asynchronous. Keep them in invocation
  // order so a previous ride's cleanup cannot remove a newer ride's snapshot.
  Future<void> _pending = Future<void>.value();

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}).catchError((
      Object error,
      StackTrace stack,
    ) {
      DriverLog.error('Active-ride storage operation failed', error, stack);
    });
    return result;
  }

  @override
  Future<PersistedActiveRide?> read() => _enqueue(() async {
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
  });

  @override
  Future<void> save(PersistedActiveRide ride) => _enqueue(() async {
    final prefs = await _load();
    if (!await prefs.setString(key, jsonEncode(ride.stamped().toJson()))) {
      throw StateError('Active ride could not be saved');
    }
  });

  @override
  Future<void> clear() => _enqueue(() async {
    final prefs = await _load();
    if (!await prefs.remove(key)) throw StateError('Active ride could not be cleared');
  });
}
