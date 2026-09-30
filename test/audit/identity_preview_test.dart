import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
void main() { test('restore has no fabricated plate or rider', () {
 final home = File('lib/presentation/driver/home/home.dart').readAsStringSync();
 expect(home, isNot(contains("snapshot.riderName ?? 'Angelica'")));
 expect(home, isNot(contains("licensePlate: 'MVR 418'")));
 expect(home, contains('Plate unavailable'));
 }); }
