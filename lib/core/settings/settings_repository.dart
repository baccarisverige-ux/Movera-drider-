import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
class SettingsRepository {
 static const key='movera_driver_settings';
 static Future<void> _pending=Future<void>.value();
 Future<Map<String,dynamic>> read(String section) async {
 await _pending; final prefs=await SharedPreferences.getInstance();
 try { final data=jsonDecode(prefs.getString(key) ?? '{}');
 return data is Map && data[section] is Map ? Map<String,dynamic>.from(data[section] as Map) : {}; }
 catch(_) { return {}; }
 }
 Future<void> save(String section,Map<String,dynamic> values) {
 final result=_pending.then((_) async {
 final prefs=await SharedPreferences.getInstance();Map<String,dynamic> data={};
 try { final raw=jsonDecode(prefs.getString(key) ?? '{}');if(raw is Map)data=Map<String,dynamic>.from(raw); } catch(_) {}
 data['schemaVersion']=1;data[section]=values;
 if(!await prefs.setString(key,jsonEncode(data)))throw StateError('Settings save failed');
 });_pending=result.catchError((Object _) {});return result;
 }
}
