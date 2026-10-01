import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/presentation/driver/my%20bank/my_bank.dart';

void main() {
  testWidgets('bank starts disconnected like wallet', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyBank()));
    expect(find.textContaining('Erik'), findsNothing);
    expect(find.textContaining('SE45'), findsNothing);
    expect(find.textContaining('No payout account is connected'), findsOneWidget);
    expect(find.text('Weekly payouts'), findsNothing);
  });
}
