import 'dart:convert';

import 'package:movera/core/storage/local_write_session.dart';

import 'package:movera/core/logging/driver_log.dart';
import 'package:movera/core/storage/local_quarantine.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only settings persistence.
///
/// New writes are section-isolated so malformed data in one settings surface
/// cannot erase unrelated sections. The legacy aggregate key remains readable
/// for existing installs.
class SettingsRepository {
  static const key = 'movera_driver_settings';
  static const sectionPrefix = 'movera_driver_settings_section_';
  static const _sectionPrefix = sectionPrefix;
  static Future<void>? _pending;
  final int _generation = LocalWriteSession.generation;

  /// Completes after every storage operation queued so far has finished.
  static Future<void> settle() async {
    final pending = _pending;
    if (pending != null) {
      await pending;
    }
  }

  String _sectionKey(String section) => '$_sectionPrefix$section';

  Future<Map<String, dynamic>> read(String section) async {
    await _pending;
    final prefs = await SharedPreferences.getInstance();
    LocalWriteSession.check(_generation);

    final isolated = prefs.getString(_sectionKey(section));
    if (isolated != null) {
      try {
        final decoded = jsonDecode(isolated);
        if (decoded is Map &&
            decoded['schemaVersion'] == 1 &&
            decoded['values'] is Map) {
          return Map<String, dynamic>.from(decoded['values'] as Map);
        }
        throw const FormatException('Unsupported settings section');
      } catch (error) {
        // Keep the unreadable text before a later save replaces the section.
        await _quarantine(prefs, _sectionKey(section), isolated, error);
        return <String, dynamic>{};
      }
    }

    // Legacy aggregate format. A malformed legacy blob is quarantined and
    // treated as missing; future writes migrate each section to its own key.
    final legacy = prefs.getString(key);
    if (legacy == null) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(legacy);
      if (decoded is! Map) throw const FormatException('Malformed settings');
      final values = decoded[section];
      return values is Map
          ? Map<String, dynamic>.from(values)
          : <String, dynamic>{};
    } catch (error) {
      await _quarantine(prefs, key, legacy, error);
      return <String, dynamic>{};
    }
  }

  Future<void> _quarantine(
    SharedPreferences prefs,
    String storageKey,
    String raw,
    Object error,
  ) async {
    try {
      LocalWriteSession.check(_generation);
      await LocalQuarantine.store(
        prefs,
        source: 'settings',
        raw: raw,
        reason: '$storageKey: $error',
      );
      await prefs.remove(storageKey);
    } catch (quarantineError) {
      DriverLog.warn('Settings quarantine failed: $quarantineError');
    }
  }

  Future<void> save(String section, Map<String, dynamic> values) {
    Future<void> write() async {
      final prefs = await SharedPreferences.getInstance();
      LocalWriteSession.check(_generation);
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
      if (identical(_pending, tail)) {
        _pending = null;
      }
    });
    return result;
  }
}
