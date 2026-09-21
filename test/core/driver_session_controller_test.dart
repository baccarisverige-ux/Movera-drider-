import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/session/driver_session_controller.dart';
import 'package:movera/core/session/driver_session_repository.dart';

void main() {
  test('driver session keeps one authoritative online state', () {
    final session = DriverSessionController();

    expect(session.isOnline, isFalse);

    session.setOnline(true);
    expect(session.isOnline, isTrue);

    session.setOnline(false);
    expect(session.isOnline, isFalse);
  });

  test('driver session persists availability through the repository', () async {
    final store = MemoryDriverSessionRepository();
    final first = DriverSessionController(repository: store);
    first.setOnline(true);
    await Future<void>.delayed(Duration.zero);

    final restored = DriverSessionController(repository: store);
    expect(restored.isOnline, isFalse);
    await restored.restore();
    expect(restored.isOnline, isTrue);

    restored.reset();
    await Future<void>.delayed(Duration.zero);
    final afterReset = DriverSessionController(repository: store);
    await afterReset.restore();
    expect(afterReset.isOnline, isFalse);
  });
}
