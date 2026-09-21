import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/session/driver_session_controller.dart';
import 'package:movera/core/session/driver_session_repository.dart';

void main() {
  test('driver session keeps one authoritative online state', () {
    final session = DriverSessionController();

    expect(session.isOnline, isFalse);
    expect(session.status, DriverOnlineStatus.offline);

    session.setOnline(true);
    expect(session.isOnline, isTrue);
    expect(session.status, DriverOnlineStatus.online);

    session.setOnline(false);
    expect(session.isOnline, isFalse);
  });

  test('going online is a distinct status folded into the controller', () {
    final session = DriverSessionController();
    session.beginGoingOnline();
    expect(session.isGoingOnline, isTrue);
    expect(session.isOnline, isFalse);

    session.completeGoingOnline();
    expect(session.isGoingOnline, isFalse);
    expect(session.isOnline, isTrue);
  });

  test('suspended drivers cannot go online', () {
    final session = DriverSessionController();
    session.suspend();
    expect(session.isSuspended, isTrue);

    session.setOnline(true);
    expect(session.isOnline, isFalse);
    expect(session.status, DriverOnlineStatus.suspended);

    session.beginGoingOnline();
    expect(session.isGoingOnline, isFalse);
  });

  test('cold start stays offline even if the last write was online', () async {
    final store = MemoryDriverSessionRepository();
    final first = DriverSessionController(repository: store);
    first.setOnline(true);
    await Future<void>.delayed(Duration.zero);
    expect(await store.readOnline(), isTrue);

    final restored = DriverSessionController(repository: store);
    expect(restored.isOnline, isFalse);
    await restored.restore();
    expect(restored.isOnline, isFalse);
    expect(await store.readOnline(), isFalse);

    restored.reset();
    await Future<void>.delayed(Duration.zero);
    final afterReset = DriverSessionController(repository: store);
    await afterReset.restore();
    expect(afterReset.isOnline, isFalse);
  });

  test('finishing a trip keeps the driver online for Home', () {
    final session = DriverSessionController();
    session.setOnline(true);
    session.stayOnlineAfterTrip();
    expect(session.isOnline, isTrue);
    expect(session.consumeResumeHomeAfterTrip(), isTrue);
    expect(session.consumeResumeHomeAfterTrip(), isFalse);
  });
}
