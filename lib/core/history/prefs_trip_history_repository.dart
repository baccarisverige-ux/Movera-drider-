import 'package:movera/core/contracts/trip_status.dart';
import 'package:movera/core/money/money.dart';
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
  static Future<void>? _pending;

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
      distance: data['distance'] as String? ?? '—',
      duration: data['duration'] as String? ?? '—',
      tip: data['tip'] as String? ?? '—',
      paymentMethod: data['paymentMethod'] as String? ?? '—',
      status: TripStatus.values.byName(data['status'] as String? ?? 'completed'),
      fareMinorUnits: data['fareMinorUnits'] as int?,
      cancellationActor: data['cancellationActor'] as String?,
      cancellationReasonCode: data['cancellationReasonCode'] as String?,
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

  Future<void> archive(
    WaybillRecord record, {
    DateTime? completedAt,
    String? distance,
    String? duration,
    String? tip,
    String? paymentMethod,
    TripStatus status=TripStatus.completed,
    String? cancellationActor,
    String? cancellationReasonCode,
  }) {
    final previous = _pending;
    Future<void> write() async {
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
        'status':status.name,
        if(status==TripStatus.completed && Money.parseSekLabel(record.fare)!=null) 'fareMinorUnits':Money.parseSekLabel(record.fare)!.minorUnits,
        if(cancellationActor!=null) 'cancellationActor':cancellationActor,
        if(cancellationReasonCode!=null) 'cancellationReasonCode':cancellationReasonCode,
        'category': record.service,
        if (distance?.trim().isNotEmpty == true) 'distance': distance!.trim(),
        if (duration?.trim().isNotEmpty == true) 'duration': duration!.trim(),
        if (tip?.trim().isNotEmpty == true) 'tip': tip!.trim(),
        if (paymentMethod?.trim().isNotEmpty == true)
          'paymentMethod': paymentMethod!.trim(),
        'completedAt': at.toIso8601String(),
      });
      final success = await prefs.setString(key, jsonEncode({'schemaVersion':1,'rows':rows.take(maxReceipts).toList()}));
      if (!success) throw StateError('Could not archive completed trip');
    }
    final result=previous==null ? write() : previous.then((_)=>write());
    final tail=result.catchError((Object _) {});
    _pending=tail;
    tail.then((_) { if(identical(_pending,tail)) _pending=null; });
    return result;
  }
}
