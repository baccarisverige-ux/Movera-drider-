import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:movera/core/contracts/trip_status.dart';
import 'package:movera/core/history/trip_history.dart';
import 'package:movera/presentation/driver/ride history/history detail/history_detail.dart';
import 'package:movera/presentation/driver/ride history/ride_history.dart';

import '../../integration_test/headless_map_platform.dart';

void main() {
  for (final status in [
    TripStatus.completed,
    TripStatus.cancelledByRider,
    TripStatus.noShow,
  ]) {
    testWidgets('history detail preserves the complete $status record', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final original = GoogleMapsFlutterPlatform.instance;
      GoogleMapsFlutterPlatform.instance = HeadlessMapPlatform();
      addTearDown(() => GoogleMapsFlutterPlatform.instance = original);
      final record = TripHistoryRecord(
        tripId: 'history-record',
        riderName: 'Stored rider',
        whenLabel: 'Original timestamp label',
        pickup: 'Stockholm',
        dropoff: 'Solna',
        fare: '128,40 kr',
        fareMinorUnits: 12840,
        tip: '20 kr',
        paymentMethod: 'Card',
        distance: '8 km',
        duration: '19 min',
        category: 'Comfort',
        status: status,
        completedAt: DateTime.now(),
        cancellationActor: 'rider',
        cancellationReasonCode: 'changed_plans',
      );
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp(
            home: DriverRideHistory(loadHistory: () async => [record]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('history-all-rides-button')),
      );
      await tester.tap(find.byKey(const ValueKey('history-all-rides-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('history-record')));
      await tester.pumpAndSettle();
      final detail = tester.widget<DriverRideHistoryDetail>(
        find.byType(DriverRideHistoryDetail),
      );
      expect(detail.record, same(record));
      expect(detail.record.tip, '20 kr');
      expect(detail.record.paymentMethod, 'Card');
      expect(find.text('Rated you'), findsNothing);
      expect(find.text('5.0'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
