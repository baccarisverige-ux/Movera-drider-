import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movera/core/ride/active_ride_repository.dart';
import 'package:movera/core/ride/prefs_active_ride_repository.dart';
import 'package:movera/core/contracts/trip_status.dart';
void main() {
 test('tombstone prevents terminal snapshot revival even before clear', () async {
 SharedPreferences.setMockInitialValues({}); final repo=PrefsActiveRideRepository();
 await repo.save(const PersistedActiveRide(tripId:'A',stage:ActiveRideStage.onTrip));
 await repo.markTerminal('A',TripStatus.completed);
 expect(await PrefsActiveRideRepository().read(),null);
 await repo.save(const PersistedActiveRide(tripId:'B',stage:ActiveRideStage.headingToPickup));
 expect((await repo.read())?.tripId,'B');
 });
 test('old and legacy snapshots remain explicit recovery candidates', () {
 final now=DateTime(2026,9,30); final ride=PersistedActiveRide(tripId:'A',stage:ActiveRideStage.onTrip,savedAt:now.subtract(const Duration(hours:7)));
 expect(ride.isFreshAt(now),false); expect(PersistedActiveRide.fromJson(ride.toJson())?.tripId,'A');
 expect(PersistedActiveRide.fromJson({'tripId':'old','stage':'onTrip'})?.tripId,'old');
 expect(PersistedActiveRide.fromJson({'schemaVersion':999,'tripId':'future','stage':'onTrip'}),null);
 });
}
