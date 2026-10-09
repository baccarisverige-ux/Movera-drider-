import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/support/local_support_repository.dart';
import 'package:movera/presentation/driver/support/support_inbox.dart';

class _SupportRepository extends LocalSupportRepository {
  bool failTickets = false;
  Completer<void>? pendingTickets;
  int ticketWrites = 0;
  List<dynamic> savedTickets = [];

  @override
  Future<Map<String, dynamic>> read() async => {};

  @override
  Future<void> update(String field, Object value) async {
    if (field != 'tickets') return;
    ticketWrites++;
    if (pendingTickets != null) await pendingTickets!.future;
    if (failTickets) throw StateError('Storage unavailable');
    savedTickets = value as List;
  }
}

Future<void> _open(WidgetTester tester, _SupportRepository repository) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SupportInboxScreen(repository: repository),
              ),
            ),
            child: const Text('Open support'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open support'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Draft local ticket'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, 'Vehicle problem');
  await tester.enterText(
    find.byType(TextField).last,
    'Keep this local message',
  );
  await tester.pump();
}

void main() {
  testWidgets('failed local ticket save keeps composer and retries once', (
    tester,
  ) async {
    final repository = _SupportRepository()..failTickets = true;
    await _open(tester, repository);
    await tester.tap(find.text('Save draft in demo'));
    await tester.pumpAndSettle();
    expect(find.text('Could not save local ticket. Retry.'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Vehicle problem'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Keep this local message'),
      findsOneWidget,
    );
    expect(repository.ticketWrites, 1);
    repository.failTickets = false;
    await tester.tap(find.text('Save draft in demo'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Vehicle problem'), findsOneWidget);
    expect(repository.ticketWrites, 2);
    expect(repository.savedTickets, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending ticket save blocks repeated submit, editing and Back', (
    tester,
  ) async {
    final repository = _SupportRepository()..pendingTickets = Completer<void>();
    await _open(tester, repository);
    final submit = tester
        .widget<FilledButton>(find.byType(FilledButton))
        .onPressed!;
    submit();
    submit();
    await tester.pump();
    expect(repository.ticketWrites, 1);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      expect(field.enabled, isFalse);
    }
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .onChanged,
      isNull,
    );
    final context = tester.element(find.byType(FilledButton));
    await Navigator.of(context).maybePop();
    await tester.pump();
    expect(find.text('Local ticket draft'), findsOneWidget);
    repository.pendingTickets!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(SupportInboxScreen), findsOneWidget);
    expect(find.text('Vehicle problem'), findsOneWidget);
    expect(repository.savedTickets, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid draft saves do not close the support inbox', (
    tester,
  ) async {
    final repository = _SupportRepository();
    await _open(tester, repository);
    final submit = tester
        .widget<FilledButton>(find.byType(FilledButton))
        .onPressed!;
    submit();
    submit();
    await tester.pumpAndSettle();
    expect(find.byType(SupportInboxScreen), findsOneWidget);
    expect(find.text('Vehicle problem'), findsOneWidget);
    expect(repository.ticketWrites, 1);
    expect(repository.savedTickets, hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
