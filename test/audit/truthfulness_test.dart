import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
String source(String path) => File('lib/presentation/driver/$path').readAsStringSync();
void main() {
 test('withdrawal entry and result disclose simulation', () {
 expect(source('my wallet/components/choose_bank.dart'), contains('Simulate withdrawal'));
 expect(source('my wallet/components/withdraw_sucess.dart'), contains('Simulated — no money moved'));
 expect(source('my wallet/components/withdraw_sucess.dart'), isNot(contains('Withdraw request sent!')));
 expect(source('my bank/add new account/add_new_account.dart'), contains('account not saved'));
 });
}
