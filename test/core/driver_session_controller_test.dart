import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/session/driver_session_controller.dart';

void main() {
  test('driver session keeps one authoritative online state', () {
    final session = DriverSessionController.instance;
    session.reset();

    expect(session.isOnline, isFalse);

    session.setOnline(true);
    expect(session.isOnline, isTrue);

    session.setOnline(false);
    expect(session.isOnline, isFalse);
  });
}
