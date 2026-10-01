import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/presentation/driver/my%20wallet/wallet.dart';

void main() {
  testWidgets('wallet does not invent a live balance or payout', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WalletScreen()));
    expect(find.text('0,00 kr'), findsOneWidget);
    expect(find.text('Preview only'), findsOneWidget);
    expect(find.textContaining('2 994'), findsNothing);
    expect(find.textContaining('21 Sep'), findsNothing);
    expect(find.textContaining('••••'), findsNothing);
    expect(find.text('No payouts yet. Local preview cannot invent earnings.'), findsOneWidget);
  });
}
