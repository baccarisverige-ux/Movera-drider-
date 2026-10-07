import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/settings/settings_repository.dart';
import 'package:movera/presentation/driver/vehicles/vehicles.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('unreadable vehicles block Add until a successful retry', (
    tester,
  ) async {
    const key = '${SettingsRepository.sectionPrefix}vehicles';
    final damaged = jsonEncode({
      'schemaVersion': 1,
      'values': {'rows': 'invalid rows'},
    });
    SharedPreferences.setMockInitialValues({key: damaged});
    await tester.pumpWidget(const MaterialApp(home: DriverVehicles()));
    await tester.pumpAndSettle();
    final add = find.widgetWithIcon(IconButton, Icons.add_rounded);
    expect(tester.widget<IconButton>(add).onPressed, isNull);
    expect(
      find.text('Could not load local vehicle drafts — Retry'),
      findsOneWidget,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(key), damaged);
    await prefs.setString(
      key,
      jsonEncode({
        'schemaVersion': 1,
        'values': {'rows': []},
      }),
    );
    await tester.tap(find.text('Could not load local vehicle drafts — Retry'));
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(add).onPressed, isNotNull);
    expect(
      find.text('Could not load local vehicle drafts — Retry'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await SettingsRepository.settle();
  });
}
