import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/waybill/waybill.dart';

WaybillRecord _record(String id, {String rider = 'Maya'}) {
  return WaybillRecord(
    tripId: id,
    statusLabel: 'Current trip',
    issuedAt: DateTime(2026, 9, 21),
    fare: '128,40 kr',
    service: 'Comfort',
    riderName: rider,
    pickup: 'Vasagatan 10, Stockholm',
    dropoff: 'Södermalm, Stockholm',
    source: 'Movera Radar',
    driverName: 'Movera Driver',
    vehicle: 'Movera partner vehicle',
    licensePlate: 'MVR 418',
    passengerCapacity: 4,
  );
}

void main() {
  tearDown(WaybillStore.reset);

  test('promoteNextToCurrent consumes the queued trip', () {
    final repo = InMemoryWaybillRepository.instance;
    repo.reset();
    repo.beginCurrent(_record('current-1', rider: 'Angelica'));
    repo.secureNext(_record('queued-1'));

    repo.completeCurrent();
    expect(repo.current, isNull);
    expect(repo.next?.tripId, 'queued-1');
    expect(repo.last?.tripId, 'current-1');

    final promoted = repo.promoteNextToCurrent();
    expect(promoted?.tripId, 'queued-1');
    expect(repo.current?.tripId, 'queued-1');
    expect(repo.current?.statusLabel, 'Current trip');
    expect(repo.next, isNull);
  });

  test('promoteNextToCurrent is a no-op when nothing is queued', () {
    final repo = InMemoryWaybillRepository.instance;
    repo.reset();
    expect(repo.promoteNextToCurrent(), isNull);
    expect(repo.current, isNull);
  });
}
