import 'dart:convert';

import 'package:movera/core/history/trip_history.dart';
import 'package:movera/core/waybill/waybill.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local frontend archive. Trip IDs are unique: a retried completion cannot
/// add a second receipt. The backend adapter can replace this boundary later.
class PrefsTripHistoryRepository {
  PrefsTripHistoryRepository({Future<SharedPreferences> Function()? load})
      : _load = load ?? SharedPreferences.getInstance;

  static const key = 'movera_driver_completed_trips';
  final Future<SharedPreferences> Function() _load;
  Future<void> _pending = Future<void>.value();

  Future<List<TripHistoryRecord>> list() async {
    await _pending;
    final prefs = await _load();
    final raw = prefs.getString(key);
    if (raw == null) return const <TripHistoryRecord>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <TripHistoryRecord>[];
    return decoded.whereType<Map>().map((row) {
      final data = Map<String, dynamic>.from(row);
      return TripHistoryRecord(
        tripId: data['tripId'] as String,
        riderName: data['riderName'] as String,
        whenLabel: data['whenLabel'] as String,
        pickup: data['pickup'] as String,
        dropoff: data['dropoff'] as String,
        fare: data['fare'] as String,
        category: data['category'] as String,
        completedAt: DateTime.tryParse(data['completedAt'] as String? ?? ''),
      );
    }).toList(growable: false);
  }

  Future<void> archive(WaybillRecord record, {DateTime? completedAt}) {
    final result = _pending.then((_) async {
      final prefs = await _load();
      final raw = prefs.getString(key);
      final rows = raw == null ? <dynamic>[] : jsonDecode(raw) as List;
      if (rows.whereType<Map>().any((row) => row['tripId'] == record.tripId)) {
        return;
      }
      final at = completedAt ?? DateTime.now();
      rows.insert(0, <String, dynamic>{
        'tripId': record.tripId,
        'riderName': record.riderName,
        'whenLabel': '${at.day}/${at.month}/${at.year}, ${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}',
        'pickup': record.pickup,
        'dropoff': record.dropoff,
        'fare': record.fare,
        'category': record.service,
        'completedAt': at.toIso8601String(),
      });
      final success = await prefs.setString(key, jsonEncode(rows));
      if (!success) throw StateError('Could not archive completed trip');
    });
    _pending = result.catchError((Object _) {});
    return result;
  }
}
