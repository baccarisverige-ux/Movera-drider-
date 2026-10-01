import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/contracts/trip_status.dart';
import 'package:movera/core/realtime/driver_realtime.dart';
void main() {
  test('interleaved trips keep contiguous independent sequences', () {
    final bus=MemoryDriverRealtime();
    expect(bus.emit(tripId:'A',kind:DriverRealtimeKind.location).sequence,1);
    expect(bus.emit(tripId:'B',kind:DriverRealtimeKind.location).sequence,1);
    expect(bus.emit(tripId:'A',kind:DriverRealtimeKind.location).sequence,2);
    bus.dispose();
  });
  test('resync retains lifecycle projection despite later locations and terminal dominates', () async {
    final bus=MemoryDriverRealtime();
    bus.emit(tripId:'A',kind:DriverRealtimeKind.tripProjection,status:TripStatus.inTrip);
    bus.emit(tripId:'A',kind:DriverRealtimeKind.location);
    final seen=<DriverRealtimeEvent>[];
    final sub=bus.subscribe('A').listen(seen.add);
    await bus.reconnectAndResync('A');await Future<void>.delayed(Duration.zero);
    expect(seen.single.status,TripStatus.inTrip);
    seen.clear();
    bus.emit(tripId:'A',kind:DriverRealtimeKind.tripProjection,status:TripStatus.completed);
    bus.emit(tripId:'A',kind:DriverRealtimeKind.tripProjection,status:TripStatus.inTrip);
    await Future<void>.delayed(Duration.zero);
    expect(seen.single.status,TripStatus.completed);
    bus.unsubscribe();seen.clear();
    await bus.reconnectAndResync('A');await Future<void>.delayed(Duration.zero);
    expect(seen,isEmpty);
    await sub.cancel();bus.dispose();
  });
}
