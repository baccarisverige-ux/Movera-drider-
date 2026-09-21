import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/contracts/trip_status.dart';
import 'package:movera/core/realtime/driver_realtime.dart';

void main() {
  test('events are sequence-numbered and filtered by tripId', () async {
    final bus = MemoryDriverRealtime();
    final seen = <DriverRealtimeEvent>[];
    final sub = bus.subscribe('trip-1').listen(seen.add);

    bus.emit(
      tripId: 'trip-1',
      kind: DriverRealtimeKind.tripProjection,
      status: TripStatus.inTrip,
    );
    bus.emit(
      tripId: 'trip-2',
      kind: DriverRealtimeKind.riderCancelled,
      status: TripStatus.cancelledByRider,
    );
    bus.emit(
      tripId: 'trip-1',
      kind: DriverRealtimeKind.riderCancelled,
      status: TripStatus.cancelledByRider,
    );

    await Future<void>.delayed(Duration.zero);
    expect(seen, hasLength(2));
    expect(seen.first.sequence, 1);
    expect(seen.last.sequence, 3);
    expect(seen.last.kind, DriverRealtimeKind.riderCancelled);
    expect(seen.last.status, TripStatus.cancelledByRider);
    await sub.cancel();
    bus.dispose();
  });

  test('reconnect replays the last event for the trip', () async {
    final bus = MemoryDriverRealtime();
    bus.emit(
      tripId: 'trip-1',
      kind: DriverRealtimeKind.location,
      latitude: 59.3293,
      longitude: 18.0686,
    );

    final seen = <DriverRealtimeEvent>[];
    final sub = bus.subscribe('trip-1').listen(seen.add);
    await bus.reconnectAndResync('trip-1');
    await Future<void>.delayed(Duration.zero);

    expect(seen, hasLength(1));
    expect(seen.single.kind, DriverRealtimeKind.location);
    expect(seen.single.latitude, 59.3293);
    await sub.cancel();
    bus.dispose();
  });
}
