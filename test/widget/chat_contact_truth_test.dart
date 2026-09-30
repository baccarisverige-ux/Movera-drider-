import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/presentation/common/chat/chat.dart';

void main() {
  testWidgets('chat clearly identifies local demo delivery state', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Chat()));

    expect(
      find.text('Local demo chat · messages are not sent to the rider.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
