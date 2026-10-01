import 'package:movera/core/contracts/trip_status.dart';
import 'dart:convert';

import 'package:movera/core/logging/driver_log.dart';
import 'package:movera/core/ride/active_ride_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Durable [ActiveRideRepository] backed by SharedPreferences.
///
/// On Flutter web this is `localStorage` key `flutter.movera_driver_active_ride`.
/// Stale snapshots older than [PersistedActiveRide.freshnessWindow] are dropped
/// so an abandoned trip cannot revive days later.
class PrefsActiveRideRepository implements ActiveRideRepository, TerminalRideRepository {
  PrefsActiveRideRepository({Future<SharedPreferences> Function()? load})
    : _load = load ?? SharedPreferences.getInstance;

  /// SharedPreferences key. Web localStorage prefix is `flutter.`.
  static const key = 'movera_driver_active_ride';
  static const terminalKey = 'movera_driver_terminal_trips';
  static const maxTerminalMarkers = 256;
  static const terminalRetention = Duration(days: 90);

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
      if (ride == null) return null;
      final terminal = prefs.getStringList(terminalKey) ?? <String>[];
      if (terminal.any((item) => _terminalTripId(item) == ride.tripId)) {
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
  Future<void> markTerminal(
    String tripId,
    TripStatus status, {
    String? reasonCode,
    String? actor,
    DateTime? occurredAt,
  }) => _enqueue(() async {
    if (!status.isTerminal) {
      throw ArgumentError('Terminal status required');
    }
    final prefs = await _load();
    final ids = prefs.getStringList(terminalKey) ?? <String>[];
    final at = (occurredAt ?? DateTime.now()).toUtc();
    final existing = ids.where((item) => _terminalTripId(item) == tripId);
    final marker = existing.isNotEmpty
        ? existing.first
        : [
            tripId,
            status.name,
            reasonCode ?? '',
            actor ?? '',
            at.toIso8601String(),
          ].join('|');

    ids.removeWhere((item) => _terminalTripId(item) == tripId);
    ids.add(marker);

    final retained = _pruneTerminalMarkers(
      ids,
      currentTripId: tripId,
      now: at,
    );
    if (!await prefs.setStringList(terminalKey, retained)) {
      throw StateError('Terminal marker could not be saved');
    }
  });

  static List<String> _pruneTerminalMarkers(
    List<String> markers, {
    required String currentTripId,
    required DateTime now,
  }) {
    final seen = <String>{};
    final newestFirst = <String>[];

    for (final marker in markers.reversed) {
      final id = _terminalTripId(marker);
      if (id.isEmpty || !seen.add(id)) continue;

      if (id != currentTripId) {
        final timestamp = _terminalTimestamp(marker);
        if (timestamp != null &&
            now.difference(timestamp) > terminalRetention) {
          continue;
        }
      }

      newestFirst.add(marker);
      if (newestFirst.length >= maxTerminalMarkers) break;
    }

    return newestFirst.reversed.toList(growable: false);
  }

  static DateTime? _terminalTimestamp(String marker) {
    final parts = marker.split('|');
    if (parts.length < 5 || parts[4].isEmpty) return null;
    return DateTime.tryParse(parts[4])?.toUtc();
  }

  static String _terminalTripId(String marker) {
    final separator = marker.indexOf('|');
    return separator < 0 ? marker : marker.substring(0, separator);
  }

  @override
  Future<void> clearForTrip(String tripId) => _enqueue(() async {
    final prefs = await _load();
    final raw = prefs.getString(key);
    if (raw == null) return;
    final data = jsonDecode(raw);
    if (data is! Map || data['tripId'] != tripId) return;
    if (!await prefs.remove(key)) throw StateError('Trip cleanup failed');
  });

  @override
  Future<void> clear() => _enqueue(() async {
    final prefs = await _load();
    if (!await prefs.remove(key)) throw StateError('Active ride could not be cleared');
  });
}
