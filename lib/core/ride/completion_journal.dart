import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movera/core/contracts/trip_status.dart';
import 'package:movera/core/ride/active_ride_repository.dart';
import 'package:movera/core/history/prefs_trip_history_repository.dart';
import 'package:movera/core/waybill/waybill.dart';

/// Replayable local transaction. Navigation to B only occurs after reconciliation.
class CompletionJournal {
 CompletionJournal({required this.active, PrefsTripHistoryRepository? history,
 Future<SharedPreferences> Function()? load, this.afterWrite})
 : history=history ?? PrefsTripHistoryRepository(), load=load ?? SharedPreferences.getInstance;
 static const key='movera_driver_completion_journal';
 final ActiveRideRepository active;
 final PrefsTripHistoryRepository history;
 final Future<SharedPreferences> Function() load;
 final void Function(String step)? afterWrite;
 static Future<void>? _pending;
 @visibleForTesting
 static void resetForTesting() { _pending=null; }
 Future<void> _serial(Future<void> Function() action) {
 final previous=_pending;
 // Start an idle queue directly: do not retain a Future from another test zone.
 final result=previous==null ? action() : previous.then((_)=>action());
 final tail=result.catchError((Object _) {});
 _pending=tail;
 tail.then((_) { if(identical(_pending,tail)) _pending=null; });
 return result;
 }
 Future<void> finish(
  WaybillRecord record, {
  PersistedActiveRide? next,
  TripStatus status=TripStatus.completed,
  String? cancellationReasonCode,
  String? cancellationActor,
 }) => _serial(() async {
 final prefs=await load();
 // Do not overwrite an earlier unfinished transaction.
 if(prefs.getString(key)!=null) await _replay(prefs);
 final terminalAt=DateTime.now();
 final payload={'schemaVersion':2,'tripId':record.tripId,'status':status.name,
 'completedAt':terminalAt.toIso8601String(),
 'record':{'tripId':record.tripId,'riderName':record.riderName,'fare':record.fare,
 'service':record.service,'pickup':record.pickup,'dropoff':record.dropoff},
 if(cancellationReasonCode!=null) 'cancellation':{
   'reasonCode':cancellationReasonCode,
   'actor':cancellationActor ?? 'unknown',
 },
 if(next!=null) 'next':next.toJson()};
 if(!await prefs.setString(key,jsonEncode(payload))) throw StateError('Completion journal write failed');
 afterWrite?.call('journal'); await _replay(prefs);
 });
 Future<void> reconcile() => _serial(() async => _replay(await load()));
 Future<void> _replay(SharedPreferences prefs) async {
 final raw=prefs.getString(key); if(raw==null) return;
 final data=jsonDecode(raw) as Map<String,dynamic>;
 final schemaVersion=data['schemaVersion'];
 if(schemaVersion!=1 && schemaVersion!=2) throw StateError('Unsupported completion journal');
 final id=data['tripId'] as String;
 final status=TripStatus.values.byName(data['status'] as String);
 if(![TripStatus.completed,TripStatus.cancelledByDriver,TripStatus.cancelledByRider,TripStatus.cancelledByAdmin].contains(status)) throw StateError('Invalid terminal journal');
 final row=Map<String,dynamic>.from(data['record'] as Map);
 final at=DateTime.parse(data['completedAt'] as String);
 if(status==TripStatus.completed) {
 await history.archive(WaybillRecord(tripId:id,statusLabel:'Completed',issuedAt:at,
 fare:row['fare'] as String,service:row['service'] as String,riderName:row['riderName'] as String,
 pickup:row['pickup'] as String,dropoff:row['dropoff'] as String,source:'Local demo',
 driverName:'Unavailable',vehicle:'Unavailable',licensePlate:'Unavailable',passengerCapacity:0),completedAt:at);
 afterWrite?.call('archive');
 }
 final cancellation=data['cancellation'];
 final cancellationMap=cancellation is Map ? Map<String,dynamic>.from(cancellation) : null;
 final repository=active;
 if(repository is TerminalRideRepository) {
   await (repository as TerminalRideRepository).markTerminal(
     id,
     status,
     reasonCode: cancellationMap?['reasonCode'] as String?,
     actor: cancellationMap?['actor'] as String?,
     occurredAt: at,
   );
 }
 afterWrite?.call('terminal');
 final nextData=data['next'];
 if(nextData is Map) {
 final next=PersistedActiveRide.fromJson(Map<String,dynamic>.from(nextData));
 if(next==null || next.tripId==id) throw StateError('Invalid queued trip');
 await active.save(next);
 } else {
 // Clear only A; do not erase an independently accepted newer trip.
 final current=await active.read();
 if(repository is TerminalRideRepository) { await (repository as TerminalRideRepository).clearForTrip(id); }
 else if(current==null || current.tripId==id) { await active.clear(); }
 }
 afterWrite?.call('snapshot');
 if(!await prefs.remove(key)) throw StateError('Completion journal cleanup failed');
 afterWrite?.call('cleanup');
 }
}
