import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/money/money.dart';

void main() {
  test('malformed signs and inconsistent grouping stay unknown', () {
    for (final label in [
      '-+12,50 kr',
      '+-12,50 kr',
      '--12 kr',
      '++12 kr',
      '1 234,567 kr',
      '1,234.567 SEK',
      '1.234 567 kr',
    ]) {
      expect(Money.parseSekLabel(label), isNull, reason: label);
    }
  });

  test('consistent grouping and a single sign preserve exact minor units', () {
    for (final label in [
      '1 234 567,89 kr',
      '1.234.567,89 kr',
      '1,234,567.89 SEK',
      '+1 234 567,89 kr',
    ]) {
      expect(Money.parseSekLabel(label)?.minorUnits, 123456789, reason: label);
    }
    expect(Money.parseSekLabel('−1 234 567,89 kr')?.minorUnits, -123456789);
  });
}
