import 'package:movera/core/logging/driver_log.dart';
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
    return _decode(raw).map((data) => TripHistoryRecord(
      tripId: data['tripId'] as String, riderName: data['riderName'] as String,
      whenLabel: data['whenLabel'] as String, pickup: data['pickup'] as String,
      dropoff: data['dropoff'] as String, fare: data['fare'] as String,
      category: data['category'] as String,
      completedAt: DateTime.tryParse(data['completedAt'] as String? ?? ''),
    )).toList(growable: false);
  }

  static const maxReceipts = 500;
  List<Map<String,dynamic>> _decode(String? raw) {
    if(raw==null) return [];
    dynamic decoded;
    try { decoded=jsonDecode(raw); }
    catch(error) { DriverLog.warn('History JSON malformed: $error'); return []; }
    if(decoded is Map) {
      if(decoded['schemaVersion']!=1) throw StateError('Unsupported history schema');
      decoded=decoded['rows'];
    }
    if(decoded is! List) { DriverLog.warn('History rows are malformed'); return []; }
    final ids=<String>{}; final rows=<Map<String,dynamic>>[];
    for(final row in decoded) {
      if(row is! Map || !['tripId','riderName','whenLabel','pickup','dropoff','fare','category'].every((key)=>row[key] is String)
        || (row['tripId'] as String).isEmpty || (row['completedAt']!=null && (row['completedAt'] is! String || DateTime.tryParse(row['completedAt'] as String)==null))) {
        DriverLog.warn('Skipping malformed history row'); continue;
      }
      if(ids.add(row['tripId'] as String)) rows.add(Map<String,dynamic>.from(row));
    }
    rows.sort((a,b)=>(DateTime.tryParse(b['completedAt'] as String? ?? '') ?? DateTime(1970)).compareTo(DateTime.tryParse(a['completedAt'] as String? ?? '') ?? DateTime(1970)));
    return rows.take(maxReceipts).toList();
  }

  Future<void> archive(WaybillRecord record, {DateTime? completedAt}) {
    final result = _pending.then((_) async {
      final prefs = await _load();
      final raw = prefs.getString(key);
      final rows = _decode(raw);
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
      final success = await prefs.setString(key, jsonEncode({'schemaVersion':1,'rows':rows.take(maxReceipts).toList()}));
      if (!success) throw StateError('Could not archive completed trip');
    });
    _pending = result.catchError((Object _) {});
    return result;
  }
}
