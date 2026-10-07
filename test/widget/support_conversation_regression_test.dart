import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/support/local_support_repository.dart';
import 'package:movera/presentation/driver/support/support_inbox.dart';

class _Support extends LocalSupportRepository {
  _Support({this.messageCount = 500});
  final int messageCount;
  final List<Object> saved = [];
  Completer<void>? pending;
  bool fail = false;

  @override
  Future<Map<String, dynamic>> read() async => {
    'tickets': [
      {
        'subject': 'Long conversation',
        'preview': 'History ${messageCount - 1}',
        'messages': List.generate(messageCount, (i) => {'text': 'History $i'}),
      },
    ],
  };

  @override
  Future<void> update(String field, Object value) async {
    saved.add(value);
    if (pending != null) await pending!.future;
    if (fail) throw StateError('Storage unavailable');
  }
}

Future<void> _open(WidgetTester tester, _Support repository) async {
  await tester.pumpWidget(
    MaterialApp(home: SupportInboxScreen(repository: repository)),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Long conversation'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'long conversation opens at latest and builds visible rows only',
    (tester) async {
      await _open(tester, _Support());
      expect(find.text('History 499').hitTestable(), findsOneWidget);
      expect(find.text('History 0'), findsNothing);
      expect(find.textContaining('History ').evaluate().length, lessThan(30));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('saving from old history shows the new reply at the composer', (
    tester,
  ) async {
    final repository = _Support();
    await _open(tester, repository);
    final history = find.byType(ListView).last;
    await tester.drag(history, const Offset(0, 450));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Newest local reply');
    await tester.tap(find.byKey(const ValueKey('local-reply-save')));
    await tester.pumpAndSettle();
    expect(find.text('Newest local reply').hitTestable(), findsOneWidget);
    expect(repository.saved, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('save failure keeps input and removes the optimistic reply', (
    tester,
  ) async {
    final repository = _Support(messageCount: 1)..fail = true;
    await _open(tester, repository);
    await tester.enterText(find.byType(TextField), 'Retry this reply');
    await tester.tap(find.byKey(const ValueKey('local-reply-save')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Retry this reply'), findsOneWidget);
    expect(find.text('Retry this reply'), findsOneWidget);
    expect(find.text('History 0'), findsOneWidget);
    expect(
      find.text('Could not save local conversation. Retry.'),
      findsOneWidget,
    );
    expect(repository.saved, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending save is single flight and preserves a newer draft', (
    tester,
  ) async {
    final repository = _Support(messageCount: 1)..pending = Completer<void>();
    await _open(tester, repository);
    final save = find.byKey(const ValueKey('local-reply-save'));
    await tester.enterText(find.byType(TextField), 'First reply');
    await tester.tap(save);
    await tester.pump();
    expect(tester.widget<IconButton>(save).onPressed, isNull);
    await tester.tap(save);
    await tester.enterText(find.byType(TextField), 'Next unsaved draft');
    repository.pending!.complete();
    await tester.pumpAndSettle();
    expect(repository.saved, hasLength(1));
    expect(find.text('First reply'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Next unsaved draft'),
      findsOneWidget,
    );
    expect(tester.widget<IconButton>(save).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
