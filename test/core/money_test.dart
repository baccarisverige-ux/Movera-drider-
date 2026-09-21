import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/earnings/earnings.dart';
import 'package:movera/core/money/money.dart';

void main() {
  test('SEK formats with comma decimals and grouped thousands', () {
    expect(Money.sek(104.80).formatted, '104,80 kr');
    expect(Money.ore(299480).formatted, '2 994,80 kr');
    expect(Money.sek(-325.40).formatted, '−325,40 kr');
  });

  test('earnings net is gross minus commission plus tips', () {
    final week = EarningsPeriod(
      periodId: 'test',
      label: 'Test',
      gross: Money.sek(1724.15),
      commission: Money.sek(325.40),
      tips: Money.sek(84.00),
      adjustments: Money.ore(0),
    );

    expect(week.net.ore, 148275);
    expect(week.net.formatted, '1 482,75 kr');
  });

  test('in-memory earnings seed a Stockholm week', () async {
    final repo = InMemoryEarningsRepository();
    final periods = await repo.load();
    expect(periods, hasLength(1));
    expect(periods.first.net.currency, 'SEK');
  });
}
