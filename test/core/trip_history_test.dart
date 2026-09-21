import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/history/trip_history.dart';

void main() {
  test('history repository returns the seeded trip by tripId', () {
    final repo = MemoryTripHistoryRepository();
    final row = repo.byTripId('ride-001');

    expect(row, isNotNull);
    expect(row!.tripId, 'ride-001');
    expect(row.pickup, 'Central Station');
    expect(row.dropoff, 'Södermalm');
    expect(row.fare, '126 kr');
    expect(row.fare.contains(r'$'), isFalse);
  });

  test('unknown tripId is a miss, not a dummy row', () {
    final repo = MemoryTripHistoryRepository();
    expect(repo.byTripId('missing'), isNull);
    expect(repo.list(), isNotEmpty);
  });
}
