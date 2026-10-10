import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/waybill/waybill.dart';

void main() {
  test('Fee and earnings keep the fare format', () {
    final comma = WaybillPayment.fromFare('139,00 kr')!;
    expect(comma.fare, '139,00 kr');
    expect(comma.serviceFee, '34,75 kr');
    expect(comma.earnings, '104,25 kr');

    final dot = WaybillPayment.fromFare('126.75 kr')!;
    expect(dot.fare, '126.75 kr');
    expect(dot.serviceFee, '31.69 kr');
    expect(dot.earnings, '95.06 kr');
  });

  test('Half öre rounds up and fee + earnings always equal the fare', () {
    final payment = WaybillPayment.fromFare('111,02 kr')!;
    expect(payment.serviceFee, '27,76 kr');
    expect(payment.earnings, '83,26 kr');
  });

  test('No amount, no payment lines', () {
    expect(WaybillPayment.fromFare('—'), isNull);
    expect(WaybillPayment.fromFare(''), isNull);
  });
}
