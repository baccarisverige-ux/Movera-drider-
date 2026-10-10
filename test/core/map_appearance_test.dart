import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/settings/map_appearance.dart';
import 'package:movera/core/settings/settings_repository.dart';
import 'package:movera/presentation/driver/settings/settings.dart';
import 'package:movera/styles/reference_map_style.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Memory extends SettingsRepository {
  _Memory([this.values = const {}]);
  Map<String, dynamic> values;
  final saved = <Map<String, dynamic>>[];
  @override
  Future<Map<String, dynamic>> read(String section) async => values;
  @override
  Future<void> save(String section, Map<String, dynamic> values) async =>
      saved.add(values);
}

void main() {
  test('Both map styles are valid Google style JSON', () {
    for (final style in [moveraLightMapStyle, moveraDarkMapStyle]) {
      expect(jsonDecode(style), isA<List<dynamic>>());
    }
    expect(moveraLightMapStyle, contains('#FAFCFA'));
    expect(moveraDarkMapStyle, contains('#272D3A'));
    expect(moveraReferenceMapStyle, moveraLightMapStyle);
  });

  test('New drivers start on the light map', () async {
    final controller = MapAppearanceController(repository: _Memory());
    await controller.load();
    expect(controller.appearance, MapAppearance.light);
    expect(controller.isDark, isFalse);
    expect(controller.style, moveraLightMapStyle);
  });

  test('A saved choice is restored and a new choice is saved', () async {
    final store = _Memory({'appearance': 'dark'});
    final controller = MapAppearanceController(repository: store);
    await controller.load();
    expect(controller.appearance, MapAppearance.dark);
    expect(controller.style, moveraDarkMapStyle);

    await controller.select(MapAppearance.light);
    expect(controller.style, moveraLightMapStyle);
    expect(store.saved.last, {'appearance': 'light'});
  });

  test('An unknown saved value stays light', () async {
    final controller = MapAppearanceController(
      repository: _Memory({'appearance': 'purple'}),
    );
    await controller.load();
    expect(controller.appearance, MapAppearance.light);
  });

  test('Automatic is dark from 20:00 to 07:00', () {
    bool night(int hour, [int minute = 0]) =>
        MapAppearanceController.isNight(DateTime(2026, 10, 10, hour, minute));
    expect(night(19, 59), isFalse);
    expect(night(20), isTrue);
    expect(night(0), isTrue);
    expect(night(6, 59), isTrue);
    expect(night(7), isFalse);
    expect(night(12), isFalse);
  });

  testWidgets('Automatic switches on its own while a map is open', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 10, 19, 59, 30);
    final controller = MapAppearanceController(
      repository: _Memory(),
      clock: () => now,
    );
    var changes = 0;
    void listener() => changes++;
    controller.addListener(listener);
    await controller.select(MapAppearance.automatic);
    expect(controller.isDark, isFalse);
    changes = 0;

    // The clock passes 20:00; the next minute tick turns the map dark.
    now = DateTime(2026, 10, 10, 20, 0, 30);
    await tester.pump(const Duration(minutes: 1));
    expect(controller.isDark, isTrue);
    expect(controller.style, moveraDarkMapStyle);
    expect(changes, 1);

    // 07:00: light again.
    now = DateTime(2026, 10, 11, 7, 0, 30);
    await tester.pump(const Duration(minutes: 1));
    expect(controller.isDark, isFalse);
    expect(changes, 2);

    // No map listening: the ticker stops.
    controller.removeListener(listener);
    now = DateTime(2026, 10, 11, 21);
    await tester.pump(const Duration(minutes: 1));
    expect(changes, 2);
    controller.dispose();
  });

  test('Light and Dark ignore the clock', () async {
    final controller = MapAppearanceController(
      repository: _Memory(),
      clock: () => DateTime(2026, 10, 10, 23),
    );
    await controller.select(MapAppearance.light);
    expect(controller.isDark, isFalse);
    await controller.select(MapAppearance.dark);
    expect(controller.isDark, isTrue);
  });

  testWidgets('Settings: Map appearance shows the choice and changes it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final appearance = MapAppearanceController.instance;
    appearance.reset();
    await tester.pumpWidget(const MaterialApp(home: Settings()));

    final row = find.byKey(const ValueKey('settings-map-appearance'));
    expect(row, findsOneWidget);
    expect(find.text('Map appearance'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);

    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(
      find.text('Automatic uses the dark map from 20:00 to 07:00.'),
      findsOneWidget,
    );
    expect(find.text('Automatic (night time)'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('map-appearance-dark')));
    await tester.pumpAndSettle();
    expect(appearance.appearance, MapAppearance.dark);
    expect(appearance.isDark, isTrue);
    expect(find.text('Dark'), findsOneWidget);

    final stored = await SettingsRepository().read('map_appearance');
    expect(stored['appearance'], 'dark');
    appearance.reset();
  });
}
