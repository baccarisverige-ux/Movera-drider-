import 'dart:convert';

import 'package:movera/core/logging/driver_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps unreadable or conflicting local records instead of deleting them.
///
/// A quarantined record no longer blocks the driver, but its raw text stays on
/// the device for support and diagnosis until logout clears local data.
class LocalQuarantine {
  const LocalQuarantine._();

  static const prefix = 'movera_driver_quarantine_';
  static const maxEntries = 10;

  static Future<String> storeOnce(
    SharedPreferences prefs, {
    required String source,
    required String raw,
    required String reason,
  }) async {
    for (final key in keys(prefs)) {
      try {
        final existing = jsonDecode(prefs.getString(key) ?? 'null');
        if (existing is Map &&
            existing['source'] == source &&
            existing['raw'] == raw) {
          return key;
        }
      } on FormatException {
        /* An older invalid quarantine is not a match. */
      }
    }
    return store(prefs, source: source, raw: raw, reason: reason);
  }

  static Future<String> store(
    SharedPreferences prefs, {
    required String source,
    required String raw,
    required String reason,
    DateTime? now,
  }) async {
    final at = (now ?? DateTime.now()).toUtc();
    final key = '$prefix${source}_${at.microsecondsSinceEpoch}';
    final payload = jsonEncode(<String, Object>{
      'source': source,
      'reason': reason,
      'quarantinedAt': at.toIso8601String(),
      'raw': raw,
    });
    if (!await prefs.setString(key, payload)) {
      throw StateError('Quarantine write failed');
    }
    DriverLog.warn('Quarantined $source record as $key: $reason');
    final existing = keys(prefs)
      ..sort((a, b) => _stamp(a).compareTo(_stamp(b)));
    for (final old in existing.take(
      existing.length > maxEntries ? existing.length - maxEntries : 0,
    )) {
      await prefs.remove(old);
    }
    return key;
  }

  static int _stamp(String key) =>
      int.tryParse(key.substring(key.lastIndexOf('_') + 1)) ?? 0;

  static List<String> keys(SharedPreferences prefs) =>
      prefs.getKeys().where((key) => key.startsWith(prefix)).toList();
}
