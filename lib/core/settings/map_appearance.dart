import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:movera/core/logging/driver_log.dart';
import 'package:movera/core/settings/settings_repository.dart';
import 'package:movera/styles/reference_map_style.dart';

/// The driver's map colours: always light, always dark, or dark at night.
enum MapAppearance {
  light('Light'),
  dark('Dark'),
  automatic('Automatic (night time)');

  const MapAppearance(this.label);
  final String label;
}

/// Owns the map appearance choice and the style every driver map draws with.
///
/// New drivers start on [MapAppearance.light]. [MapAppearance.automatic] is
/// dark from [nightStartHour] to [nightEndHour], phone local time, and is
/// re-checked every minute while a map is listening, so the map changes on its
/// own at the switch time, also during a trip.
class MapAppearanceController extends ChangeNotifier {
  MapAppearanceController({
    SettingsRepository? repository,
    DateTime Function()? clock,
  }) : _repository = repository ?? SettingsRepository(),
       _clock = clock ?? DateTime.now;

  static final MapAppearanceController instance = MapAppearanceController();

  /// Night window for [MapAppearance.automatic]. Temporary fixed times chosen
  /// by the product owner; change here.
  static const int nightStartHour = 20;
  static const int nightEndHour = 7;

  static const _section = 'map_appearance';

  final SettingsRepository _repository;
  final DateTime Function() _clock;
  MapAppearance _appearance = MapAppearance.light;
  bool _dark = false;
  Timer? _ticker;

  MapAppearance get appearance => _appearance;

  /// Whether maps draw dark right now.
  bool get isDark => _dark;

  String get style => _dark ? moveraDarkMapStyle : moveraLightMapStyle;

  static bool isNight(DateTime time) =>
      time.hour >= nightStartHour || time.hour < nightEndHour;

  /// Restores the saved choice. A missing or unreadable value stays Light.
  Future<void> load() async {
    try {
      final values = await _repository.read(_section);
      final saved = MapAppearance.values
          .where((value) => value.name == values['appearance'])
          .firstOrNull;
      if (saved != null) _apply(saved);
    } catch (error) {
      DriverLog.warn('Map appearance restore failed: $error');
    }
  }

  /// Applies the choice at once, then saves it. Throws when saving fails.
  Future<void> select(MapAppearance appearance) async {
    _apply(appearance);
    await _repository.save(_section, {'appearance': appearance.name});
  }

  /// Back to the default for a new driver, without saving (logout clears the
  /// stored settings).
  void reset() => _apply(MapAppearance.light);

  void _apply(MapAppearance appearance) {
    final changed = appearance != _appearance;
    _appearance = appearance;
    _syncTicker();
    if (!_refresh() && changed) notifyListeners();
  }

  /// Recomputes light or dark. Returns true when it notified listeners.
  bool _refresh() {
    final dark = _computeDark();
    if (dark == _dark) return false;
    _dark = dark;
    notifyListeners();
    return true;
  }

  bool _computeDark() => switch (_appearance) {
    MapAppearance.light => false,
    MapAppearance.dark => true,
    MapAppearance.automatic => isNight(_clock()),
  };

  void _syncTicker() {
    final needed = _appearance == MapAppearance.automatic && hasListeners;
    if (needed && _ticker == null) {
      _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
    } else if (!needed) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  void addListener(VoidCallback listener) {
    // The first map to listen may arrive long after the last check. Catch up
    // silently: it reads [style] right after subscribing, during its build.
    if (!hasListeners) _dark = _computeDark();
    super.addListener(listener);
    _syncTicker();
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
