import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/session/driver_session_controller.dart';

void main() {
  test('R15 ending a trip during connecting cannot advertise availability', () {
    final session = DriverSessionController();
    addTearDown(session.dispose);
    session.beginGoingOnline();
    session.beginTrip('trip');
    session.endTrip();
    expect(session.status, DriverOnlineStatus.offline);
    expect(session.availableForOffers, isFalse);
  });
  test(
    'R16 restore cannot change availability while a trip owns the session',
    () async {
      final session = DriverSessionController(initialOnline: true);
      addTearDown(session.dispose);
      session.beginTrip('trip');
      await session.restore();
      expect(session.status, DriverOnlineStatus.onTrip);
      expect(session.activeTripId, 'trip');
    },
  );
}
