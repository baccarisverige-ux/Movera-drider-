import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Home offer radar orchestration is outside the widget file', () {
    final home = File(
      'lib/presentation/driver/home/home.dart',
    ).readAsStringSync();
    final offers = File(
      'lib/presentation/driver/home/home_offer_radar.dart',
    ).readAsStringSync();

    expect(home, contains("part 'home_offer_radar.dart';"));
    expect(home, contains('class DriverHome'));
    expect(home, isNot(contains('void _scheduleVisibleOffers')));
    expect(offers, contains("part of 'home.dart';"));
    expect(offers, contains('extension _HomeOfferRadar on _DriverHomeState'));
    expect(offers, contains('Duration(milliseconds: 2200)'));
    expect(offers, contains('Duration(milliseconds: 11500)'));
    expect(offers, contains('Duration(milliseconds: 14500)'));
    expect(offers, contains('Duration(milliseconds: 17500)'));
    expect(offers, contains('Duration(milliseconds: 50000)'));
    expect(offers, contains('Duration(milliseconds: 40000)'));
    expect(home, contains('Duration(milliseconds: 1400)'));
  });
}
