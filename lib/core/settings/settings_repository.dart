import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local-only settings persistence.
///
/// New writes are section-isolated so malformed data in one settings surface
/// cannot erase unrelated sections. The legacy aggregate key remains readable
/// for existing installs.
class SettingsRepository {
  static const key = 'movera_driver_settings';
  static const _sectionPrefix = 'movera_driver_settings_section_';
  static Future<void>? _pending;

  String _sectionKey(String section) => '$_sectionPrefix$section';

  Future<Map<String, dynamic>> read(String section) async {
    await _pending;
    final prefs = await SharedPreferences.getInstance();

    final isolated = prefs.getString(_sectionKey(section));
    if (isolated != null) {
      try {
        final decoded = jsonDecode(isolated);
        if (decoded is Map &&
            decoded['schemaVersion'] == 1 &&
            decoded['values'] is Map) {
          return Map<String, dynamic>.from(decoded['values'] as Map);
        }
        return <String, dynamic>{};
      } catch (_) {
        return <String, dynamic>{};
      }
    }

    // Legacy aggregate format. A malformed legacy blob is treated as missing;
    // future successful writes migrate each touched section to its own key.
    try {
      final decoded = jsonDecode(prefs.getString(key) ?? '{}');
      if (decoded is! Map) return <String, dynamic>{};
      final values = decoded[section];
      return values is Map
          ? Map<String, dynamic>.from(values)
          : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> save(String section, Map<String, dynamic> values) {
    Future<void> write() async {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode(<String, dynamic>{
        'schemaVersion': 1,
        'values': values,
      });
      if (!await prefs.setString(_sectionKey(section), payload)) {
        throw StateError('Settings save failed');
      }
    }

    final previous = _pending;
    final result = previous == null ? write() : previous.then((_) => write());
    final tail = result.catchError((Object _) {});
    _pending = tail;
    tail.then((_) {
      if (identical(_pending, tail)) _pending = null;
    });
    return result;
  }
}
