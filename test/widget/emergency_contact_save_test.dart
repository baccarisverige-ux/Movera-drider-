import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/settings/settings_repository.dart';
import 'package:movera/presentation/driver/settings/emergency_contacts.dart';

class _ContactsRepository extends SettingsRepository {
  int writes = 0;
  bool fail = false;
  Completer<void>? pending;
  Map<String, dynamic>? saved;

  @override
  Future<Map<String, dynamic>> read(String section) async => {};

  @override
  Future<void> save(String section, Map<String, dynamic> values) async {
    writes++;
    if (fail) throw StateError('Storage unavailable');
    if (pending != null) await pending!.future;
    saved = values;
  }
}

Future<void> _open(WidgetTester tester, _ContactsRepository repository) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, child) => MaterialApp(home: child),
      child: EmergencyContactsScreen(repository: repository),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('add-emergency-contact')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), 'Trusted person');
  await tester.enterText(find.byType(TextFormField).at(1), '+46 701234567');
}

void main() {
  testWidgets('failed contact save preserves fields and retries once', (
    tester,
  ) async {
    final repository = _ContactsRepository()..fail = true;
    await _open(tester, repository);
    await tester.tap(find.text('Save contact'));
    await tester.pumpAndSettle();
    expect(find.text('Contact could not be saved. Retry.'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(0))
          .controller!
          .text,
      'Trusted person',
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(1))
          .controller!
          .text,
      '+46 701234567',
    );
    expect(repository.writes, 1);
    repository.fail = false;
    await tester.tap(find.text('Save contact'));
    await tester.pumpAndSettle();
    expect(repository.writes, 2);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Trusted person'), findsOneWidget);
    expect(repository.saved!['rows'], hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending contact save disables repeated submit and editing', (
    tester,
  ) async {
    final repository = _ContactsRepository()..pending = Completer<void>();
    await _open(tester, repository);
    await tester.tap(find.text('Save contact'));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    for (final field in tester.widgetList<TextFormField>(
      find.byType(TextFormField),
    )) {
      expect(field.enabled, isFalse);
    }
    await tester.tap(find.text('Saving contact…'));
    await tester.pump();
    expect(repository.writes, 1);
    final sheetContext = tester.element(find.byType(FilledButton));
    expect(await Navigator.of(sheetContext).maybePop(), isTrue);
    await tester.pump();
    expect(
      find.byType(TextFormField),
      findsNWidgets(3),
      reason: 'Back must not discard an in-flight save',
    );
    repository.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Trusted person'), findsOneWidget);
    expect(repository.writes, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reserved emergency number cannot become a disappearing draft', (
    tester,
  ) async {
    final repository = _ContactsRepository();
    await _open(tester, repository);
    await tester.enterText(find.byType(TextFormField).at(1), '112');
    await tester.tap(find.text('Save contact'));
    await tester.pumpAndSettle();
    expect(
      find.text('This number is already in your contacts.'),
      findsOneWidget,
    );
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(repository.writes, 0);
    expect(tester.takeException(), isNull);
  });
}
