import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movera/core/settings/settings_repository.dart';
import 'package:movera/presentation/driver/settings/emergency_contacts.dart';
import 'package:movera/presentation/driver/vehicles/vehicles.dart';

class _Contacts extends SettingsRepository {
  @override
  Future<Map<String, dynamic>> read(String section) async => {};
}

Future<GlobalKey<NavigatorState>> _root(
  WidgetTester tester,
  Widget screen,
) async {
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(
        navigatorKey: navigator,
        home: const Scaffold(body: Text('Caller owner')),
      ),
    ),
  );
  navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => screen));
  await tester.pumpAndSettle();
  return navigator;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'E02 covered contact Add cannot open a composer; current Add still works',
    (tester) async {
      final navigator = await _root(
        tester,
        EmergencyContactsScreen(repository: _Contacts()),
      );
      final add = tester
          .widget<IconButton>(
            find.byKey(const ValueKey('add-emergency-contact')),
          )
          .onPressed!;
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Cover owner')),
        ),
      );
      await tester.pumpAndSettle();
      add();
      await tester.pumpAndSettle();
      expect(find.text('Cover owner'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      add();
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('E02 disposed contact Add cannot open a composer or throw', (
    tester,
  ) async {
    final navigator = await _root(
      tester,
      EmergencyContactsScreen(repository: _Contacts()),
    );
    final add = tester
        .widget<IconButton>(find.byKey(const ValueKey('add-emergency-contact')))
        .onPressed!;
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    add();
    await tester.pumpAndSettle();
    expect(find.text('Caller owner'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('E03 disposed vehicle Retry cannot start restore or throw', (
    tester,
  ) async {
    const key = '${SettingsRepository.sectionPrefix}vehicles';
    SharedPreferences.setMockInitialValues({
      key: jsonEncode({
        'schemaVersion': 1,
        'values': {'rows': 'invalid'},
      }),
    });
    final navigator = await _root(tester, const DriverVehicles());
    final retry = tester
        .widget<TextButton>(
          find.widgetWithText(
            TextButton,
            'Could not load local vehicle drafts — Retry',
          ),
        )
        .onPressed!;
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    retry();
    await tester.pumpAndSettle();
    expect(find.text('Caller owner'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await SettingsRepository.settle();
  });
}
