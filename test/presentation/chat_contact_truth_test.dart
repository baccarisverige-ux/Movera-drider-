import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/presentation/common/chat/components/appbar.dart';

void main() {
  testWidgets('chat call does not dial a hard-coded number', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(appBar: ChatAppBar())));
    expect(find.text('Rider'), findsOneWidget);
    expect(find.textContaining('46701234567'), findsNothing);
    await tester.tap(find.byTooltip('Call unavailable'));
    await tester.pump();
    expect(find.text('Rider phone contact is not connected.'), findsOneWidget);
  });
}
