import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movera/core/contracts/trip_status.dart';
import 'package:movera/core/ride/active_ride_repository.dart';
import 'package:movera/core/realtime/driver_realtime.dart';
import 'package:movera/core/history/prefs_trip_history_repository.dart';
import 'package:movera/presentation/driver/accept%20ride/accept_ride.dart';
class _PendingSave extends MemoryActiveRideRepository {
  Completer<void>? hold;
  @override
  Future<void> save(PersistedActiveRide ride) async {
    final pending=hold;
    if(pending!=null) await pending.future;
    await super.save(ride);
  }
}
void main() {
  testWidgets('rider cancellation received during stage persistence is retained', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo=_PendingSave(), realtime=MemoryDriverRealtime();
    await tester.pumpWidget(MaterialApp(home:AcceptRide(offerId:'pending-trip',initialStage:ActiveRideStage.waitingForRider,activeRideRepository:repo,realtime:realtime)));
    for(var i=0;i<10;i++) {await tester.pump(const Duration(milliseconds:30));}
    repo.hold=Completer<void>();
    final action=find.byKey(const ValueKey<String>('active-ride-primary-action'));
    await tester.ensureVisible(action);
    await tester.drag(action,const Offset(320,0));await tester.pump();
    realtime.emit(tripId:'pending-trip',kind:DriverRealtimeKind.riderCancelled,status:TripStatus.cancelledByRider);
    await tester.pump(const Duration(milliseconds:150));
    expect((await repo.read())!.stage,ActiveRideStage.waitingForRider);
    final pending=repo.hold!;repo.hold=null;pending.complete();
    for(var i=0;i<20;i++) {await tester.pump(const Duration(milliseconds:50));}
    expect(await repo.read(),isNull);
    expect((await PrefsTripHistoryRepository().list()).single.status,TripStatus.cancelledByRider);
    expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox.shrink());realtime.dispose();
  });
}
