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
    repo.secureNext(_record('queued-1').copyWith(statusLabel: 'Queued trip'));

    repo.completeCurrent();
    expect(repo.current, isNull);
    expect(repo.next?.tripId, 'queued-1');
    expect(repo.last?.tripId, 'current-1');

    final promoted = repo.promoteNextToCurrent();
    expect(promoted?.tripId, 'queued-1');
    expect(promoted?.statusLabel, 'Current trip');
    expect(identical(promoted, repo.current), isTrue);
    expect(repo.current?.tripId, 'queued-1');
    expect(repo.current?.statusLabel, 'Current trip');
    expect(repo.next, isNull);
  });

  test('promotion cannot overwrite an active ride or consume the queue', () {
    final repo = InMemoryWaybillRepository.instance;
    repo.reset();
    final active = _record('active-1');
    final queued = _record('queued-2').copyWith(statusLabel: 'Queued trip');
    repo.beginCurrent(active);
    repo.secureNext(queued);
    var currentNotifications = 0;
    var nextNotifications = 0;
    void onCurrent() => currentNotifications++;
    void onNext() => nextNotifications++;
    repo.currentListenable.addListener(onCurrent);
    repo.nextListenable.addListener(onNext);
    addTearDown(() {
      repo.currentListenable.removeListener(onCurrent);
      repo.nextListenable.removeListener(onNext);
    });

    expect(repo.promoteNextToCurrent(), isNull);
    expect(identical(repo.current, active), isTrue);
    expect(identical(repo.next, queued), isTrue);
    expect(currentNotifications, 0);
    expect(nextNotifications, 0);

    repo.discardCurrent();
    final promoted = repo.promoteNextToCurrent();
    expect(promoted?.tripId, 'queued-2');
    expect(promoted?.statusLabel, 'Current trip');
    expect(identical(repo.current, promoted), isTrue);
    expect(repo.next, isNull);
  });

  test('promoteNextToCurrent is a no-op when nothing is queued', () {
    final repo = InMemoryWaybillRepository.instance;
    repo.reset();
    expect(repo.promoteNextToCurrent(), isNull);
    expect(repo.current, isNull);
  });
}
