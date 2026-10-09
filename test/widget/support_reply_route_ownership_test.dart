import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/support/local_support_repository.dart';
import 'package:movera/presentation/driver/support/support_inbox.dart';

class _Support extends LocalSupportRepository {
  int writes = 0;
  @override
  Future<Map<String, dynamic>> read() async => {
    'tickets': [
      {
        'subject': 'Conversation',
        'preview': 'Original message',
        'messages': [
          {'text': 'Original message'},
        ],
      },
    ],
  };
  @override
  Future<void> update(String field, Object value) async {
    writes++;
  }
}

Future<VoidCallback> _replyCallback(
  WidgetTester tester,
  _Support repo,
  GlobalKey<NavigatorState> navigator,
) async {
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      home: SupportInboxScreen(repository: repo),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Conversation'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), 'Unsaved reply');
  await tester.pump();
  return tester
      .widget<IconButton>(find.byKey(const ValueKey('local-reply-save')))
      .onPressed!;
}

void main() {
  testWidgets('S04 covered conversation callback cannot save a reply', (
    tester,
  ) async {
    final repo = _Support();
    final navigator = GlobalKey<NavigatorState>();
    final callback = await _replyCallback(tester, repo, navigator);
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Cover')),
      ),
    );
    await tester.pumpAndSettle();
    callback();
    await tester.pumpAndSettle();
    expect(repo.writes, 0);
    expect(find.text('Cover'), findsOneWidget);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Unsaved reply'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('local-reply-save')));
    await tester.pumpAndSettle();
    expect(repo.writes, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('S04 disposed conversation callback cannot mutate or throw', (
    tester,
  ) async {
    final repo = _Support();
    final navigator = GlobalKey<NavigatorState>();
    final callback = await _replyCallback(tester, repo, navigator);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    callback();
    await tester.pumpAndSettle();
    expect(repo.writes, 0);
    expect(find.byType(SupportInboxScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
