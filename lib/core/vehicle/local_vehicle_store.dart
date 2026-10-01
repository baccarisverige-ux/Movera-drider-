import 'dart:convert';
import 'package:movera/core/settings/settings_repository.dart';

/// Device-only drafts; no vehicle activation or document verification.
class LocalVehicleStore {
  final _settings = SettingsRepository();
  static Future<void>? _pending;
  Future<void> _serial(Future<void> Function() write) {
    final previous=_pending;
    final result=previous==null ? write() : previous.then((_)=>write());
    final tail=result.catchError((Object _) {});_pending=tail;
    tail.then((_) {if(identical(_pending,tail)) _pending=null;});return result;
  }
  static const demo = <String,dynamic>{'id':'demo-V418','make':'Mercedes-Benz','model':'E 220','year':'2022','plate':'MVR 418'};
  Future<List<Map<String,dynamic>>> list() async {
    final data = await _settings.read('vehicles');
    final rows = data['rows'];
    if (rows == null) { return [Map.of(demo)]; }
    if (rows is! List) { throw StateError('Invalid vehicle drafts'); }
    return rows.map((row) {
      if (row is! Map || !['id','make','model','year','plate'].every((key)=>row[key] is String)) { throw StateError('Invalid vehicle draft'); }
      for(final field in ['registrationPhoto','insurancePhoto']) {
        if(row[field]!=null && (row[field] is! String || base64Decode(row[field] as String).length>2*1024*1024)) throw StateError('Invalid local photo');
      }
      return Map<String,dynamic>.from(row);
    }).toList();
  }
  Future<void> upsert(Map<String,dynamic> vehicle) => _serial(() async {
    final rows=await list();
    rows.removeWhere((row)=>row['id']==vehicle['id']);rows.add(Map.of(vehicle));
    await _settings.save('vehicles',{'rows':rows});
  });
  Future<void> remove(String id) => _serial(() async {
    final rows=await list();rows.removeWhere((row)=>row['id']==id);
    await _settings.save('vehicles',{'rows':rows});
  });
}
