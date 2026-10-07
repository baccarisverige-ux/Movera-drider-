import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/support/local_support_repository.dart';
import 'package:movera/presentation/driver/support/support_inbox.dart';

class _Support extends LocalSupportRepository {
  Completer<Map<String, dynamic>>? pending;
  bool fail = false;
  @override
  Future<Map<String, dynamic>> read() async {
    if (pending != null) return pending!.future;
    if (fail) throw StateError('Unreadable support');
    return {};
  }

  @override
  Future<void> update(String field, Object value) async {}
}

void main() {
  testWidgets(
    'draft action is disabled during restore and on restore failure',
    (tester) async {
      final repository = _Support()
        ..pending = Completer<Map<String, dynamic>>();
      await tester.pumpWidget(
        MaterialApp(home: SupportInboxScreen(repository: repository)),
      );
      final action = find.byType(FloatingActionButton);
      expect(tester.widget<FloatingActionButton>(action).onPressed, isNull);
      repository.pending!.completeError(StateError('Unreadable support'));
      await tester.pumpAndSettle();
      expect(tester.widget<FloatingActionButton>(action).onPressed, isNull);
      expect(find.text('Could not load local support — Retry'), findsOneWidget);
      repository.pending = null;
      await tester.tap(find.text('Could not load local support — Retry'));
      await tester.pumpAndSettle();
      expect(tester.widget<FloatingActionButton>(action).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('draft validation clears as corrected fields become valid', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: SupportInboxScreen(repository: _Support())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Draft local ticket'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save draft in demo'));
    await tester.pump();
    expect(find.text('Enter a subject'), findsOneWidget);
    expect(find.text('Enter a message'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Valid subject');
    await tester.pump();
    expect(find.text('Enter a subject'), findsNothing);
    expect(find.text('Enter a message'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Valid message');
    await tester.pump();
    expect(find.text('Enter a message'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
