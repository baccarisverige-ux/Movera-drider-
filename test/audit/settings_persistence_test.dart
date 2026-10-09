import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movera/core/settings/settings_repository.dart';

void main() {
  test('queued saves preserve each requested nested value', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final gate = Completer<SharedPreferences>();
    final repo = SettingsRepository(load: () => gate.future);
    final selected = <bool>[true, false];
    final row = <String, dynamic>{'name': 'Original'};
    final values = <String, dynamic>{
      'selected': selected,
      'rows': [row],
    };
    final first = repo.save('categories', values);
    selected[0] = false;
    row['name'] = 'Later';
    final second = repo.save('contacts', values);
    selected[1] = true;
    row['name'] = 'Unsaved';
    gate.complete(prefs);
    await Future.wait([first, second]);
    final fresh = SettingsRepository();
    expect(await fresh.read('categories'), {
      'selected': [true, false],
      'rows': [
        {'name': 'Original'},
      ],
    });
    expect(await fresh.read('contacts'), {
      'selected': [false, false],
      'rows': [
        {'name': 'Later'},
      ],
    });
  });

  test('settings sections persist without overwriting one another', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = SettingsRepository();
    await Future.wait([
      repo.save('categories', {
        'selected': [true, false],
      }),
      repo.save('sound', {'generalVolume': .7}),
      repo.save('accessibility', {'flash': true}),
    ]);

    final fresh = SettingsRepository();
    expect((await fresh.read('sound'))['generalVolume'], .7);
    expect((await fresh.read('categories'))['selected'], [true, false]);
    expect((await fresh.read('accessibility'))['flash'], true);
  });

  test('corrupt one settings section does not poison another', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = SettingsRepository();
    await repo.save('sound', {'generalVolume': .7});
    await repo.save('accessibility', {'flash': true});

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'movera_driver_settings_section_sound',
      '{broken-json',
    );

    expect(await SettingsRepository().read('sound'), isEmpty);
    expect((await SettingsRepository().read('accessibility'))['flash'], true);
  });

  test('legacy aggregate settings remain readable', () async {
    SharedPreferences.setMockInitialValues({
      SettingsRepository.key: jsonEncode({
        'schemaVersion': 1,
        'sound': {'generalVolume': .5},
      }),
    });

    expect((await SettingsRepository().read('sound'))['generalVolume'], .5);
  });
}
