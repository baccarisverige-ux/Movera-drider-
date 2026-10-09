import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/support/local_support_repository.dart';
import 'package:movera/presentation/driver/support/support_inbox.dart';

class _Support extends LocalSupportRepository {
  final reads = <Completer<Map<String, dynamic>>>[];
  final recoveries = <Completer<void>>[];

  @override
  Future<Map<String, dynamic>> read() {
    final result = Completer<Map<String, dynamic>>();
    reads.add(result);
    return result.future;
  }

  @override
  Future<void> recover() {
    final result = Completer<void>();
    recoveries.add(result);
    return result.future;
  }
}

const _retry = 'Could not load local support — Retry';
const _recover = 'Recover local support (preserve unreadable data)';
TextButton _button(WidgetTester tester, String text) =>
    tester.widget<TextButton>(find.widgetWithText(TextButton, text));

Future<void> _failedInbox(WidgetTester tester, _Support repository) async {
  await tester.pumpWidget(
    MaterialApp(home: SupportInboxScreen(repository: repository)),
  );
  repository.reads.single.completeError(StateError('Unreadable local data'));
  await tester.pumpAndSettle();
}

void _expectLocked(WidgetTester tester) {
  expect(_button(tester, _retry).onPressed, isNull);
  expect(_button(tester, _recover).onPressed, isNull);
  expect(
    tester
        .widget<FloatingActionButton>(find.byType(FloatingActionButton))
        .onPressed,
    isNull,
  );
  expect(find.byType(LinearProgressIndicator), findsOneWidget);
}

void main() {
  testWidgets(
    'retry is single flight and blocks recovery and new drafts until restored',
    (tester) async {
      final repository = _Support();
      await _failedInbox(tester, repository);
      final retry = _button(tester, _retry).onPressed!;
      final recover = _button(tester, _recover).onPressed!;
      retry();
      retry();
      recover();
      await tester.pump();
      _expectLocked(tester);
      expect(repository.reads, hasLength(2));
      expect(repository.recoveries, isEmpty);
      repository.reads.last.complete({
        'tickets': [
          {'subject': 'Restored conversation', 'preview': 'Saved message'},
        ],
      });
      await tester.pumpAndSettle();
      expect(find.text('Restored conversation'), findsOneWidget);
      expect(find.text(_retry), findsNothing);
      expect(
        tester
            .widget<FloatingActionButton>(find.byType(FloatingActionButton))
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('recovery owns the lock through the following restore read', (
    tester,
  ) async {
    final repository = _Support();
    await _failedInbox(tester, repository);
    final recover = _button(tester, _recover).onPressed!;
    final retry = _button(tester, _retry).onPressed!;
    recover();
    recover();
    retry();
    await tester.pump();
    _expectLocked(tester);
    expect(repository.recoveries, hasLength(1));
    expect(repository.reads, hasLength(1));
    repository.recoveries.single.complete();
    await tester.pump();
    _expectLocked(tester);
    expect(repository.reads, hasLength(2));
    retry();
    recover();
    expect(repository.reads, hasLength(2));
    expect(repository.recoveries, hasLength(1));
    repository.reads.last.complete({});
    await tester.pumpAndSettle();
    expect(find.text(_retry), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed recovery re-enables retry while keeping drafts disabled',
    (tester) async {
      final repository = _Support();
      await _failedInbox(tester, repository);
      _button(tester, _recover).onPressed!();
      repository.recoveries.single.completeError(
        StateError('Recovery write failed'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Could not recover local support. Retry.'),
        findsOneWidget,
      );
      expect(_button(tester, _retry).onPressed, isNotNull);
      expect(_button(tester, _recover).onPressed, isNotNull);
      expect(
        tester
            .widget<FloatingActionButton>(find.byType(FloatingActionButton))
            .onPressed,
        isNull,
      );
      _button(tester, _retry).onPressed!();
      repository.reads.last.complete({});
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FloatingActionButton>(find.byType(FloatingActionButton))
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'pending recovery completion after disposal cannot restore the old inbox',
    (tester) async {
      final repository = _Support();
      await _failedInbox(tester, repository);
      _button(tester, _recover).onPressed!();
      await tester.pumpWidget(const SizedBox());
      repository.recoveries.single.complete();
      await tester.pump();
      // A disposed inbox must not initiate another storage read.
      expect(repository.reads, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );
}
