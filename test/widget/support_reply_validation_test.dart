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
        'subject': 'Validation ticket',
        'preview': 'Original draft',
        'messages': [
          {'text': 'Original draft'},
        ],
      },
    ],
  };
  @override
  Future<void> update(String field, Object value) async {
    writes++;
  }
}

void main() {
  testWidgets(
    'local reply enables only for trimmed text and disables after save',
    (tester) async {
      final repository = _Support();
      await tester.pumpWidget(
        MaterialApp(home: SupportInboxScreen(repository: repository)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Validation ticket'));
      await tester.pumpAndSettle();
      final save = find.byKey(const ValueKey('local-reply-save'));
      expect(tester.widget<IconButton>(save).onPressed, isNull);
      await tester.enterText(find.byType(TextField), '  \n\t ');
      await tester.pump();
      expect(tester.widget<IconButton>(save).onPressed, isNull);
      expect(repository.writes, 0);
      await tester.enterText(find.byType(TextField), '  Useful reply  ');
      await tester.pump();
      expect(tester.widget<IconButton>(save).onPressed, isNotNull);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repository.writes, 1);
      expect(find.text('Useful reply'), findsOneWidget);
      expect(tester.widget<IconButton>(save).onPressed, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
