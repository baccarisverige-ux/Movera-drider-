import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final contract = File('docs/contracts/openapi.yaml').readAsStringSync();

  test('every component reference resolves', () {
    final defined = RegExp(r'^    (\w+):\s*$', multiLine: true)
        .allMatches(contract)
        .map((m) => m.group(1))
        .toSet();
    final missing = RegExp(r"#/components/(?:schemas|parameters)/(\w+)")
        .allMatches(contract)
        .map((m) => m.group(1))
        .where((name) => !defined.contains(name))
        .toSet();
    expect(missing, isEmpty);
  });

  test('every operation has a unique operationId', () {
    final ids = RegExp(r'operationId: (\w+)').allMatches(contract).map((m) => m.group(1)).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('driver capabilities used by screens have a contract operation', () {
    for (final operation in [
      'listDriverOffers', 'acceptOffer', 'arriveDriverTrip', 'verifyPickupPin',
      'startDriverTrip', 'completeDriverTrip', 'cancelTrip', 'resyncTripEvents',
      'sendTripMessage', 'rateRider', 'reportDriverLocation', 'listDriverHistory',
      'createSupportTicket', 'createVehicle', 'uploadDocument', 'listPayouts',
    ]) {
      expect(contract, contains('operationId: $operation'), reason: operation);
    }
  });

  test('state-changing driver commands require an idempotency key', () {
    final blocks = contract.split(RegExp(r'\n  /'));
    for (final block in blocks.where((b) => RegExp(r'\n    (post|put|delete):').hasMatch(b))) {
      final path = block.split('\n').first;
      if (path.startsWith('admin')) continue;
      expect(block, contains("parameters/IdempotencyKey"), reason: path);
    }
  });
}
