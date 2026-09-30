import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
/// Local-only drafts. No transport or support service is implied.
class LocalSupportRepository {
 static const key='movera_driver_support_drafts';
 static Future<void>? _pending;
 Future<Map<String,dynamic>> read() async {
 await _pending; return _read(await SharedPreferences.getInstance());
 }
 Map<String,dynamic> _read(SharedPreferences prefs) {
 try { final raw=prefs.getString(key); if(raw==null) { return {}; }
 final json=jsonDecode(raw); return json is Map && json['schemaVersion']==1 ? Map<String,dynamic>.from(json):{};
 } catch(_) { return {}; }
 }
 Future<void> update(String field,Object value) {
 Future<void> write() async {
 final prefs=await SharedPreferences.getInstance();final data=_read(prefs);
 data['schemaVersion']=1;data[field]=value;
 if(!await prefs.setString(key,jsonEncode(data))) { throw StateError('Local draft could not be saved'); }
 }
 final previous=_pending;
 final result=previous==null ? write() : previous.then((_)=>write());
 final tail=result.catchError((Object _) {});_pending=tail;
 tail.then((_) {if(identical(_pending,tail)) { _pending=null; }});
 return result;
 }
}
