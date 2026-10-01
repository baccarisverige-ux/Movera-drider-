import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:integration_test/integration_test.dart';
import 'package:movera/core/ride/completion_journal.dart';
import 'package:movera/core/waybill/waybill.dart';
import 'package:movera/main.dart';
import 'package:movera/presentation/driver/accept%20ride/accept_ride.dart';
import 'package:movera/presentation/driver/home/home.dart';
import 'package:movera/presentation/driver/ride%20completed/ride_completed.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'headless_map_platform.dart';

/// Frontend lifecycle on the real [MoveraApp] composition root.
///
/// Demo services are the ones [MoveraApp] already injects. No backend.
/// The map platform is a Flutter stand-in so this can run on the headless
/// tester. It does not certify the native Google Map.

Future<void> _advance(WidgetTester tester, Duration duration) async {
  await tester.pump();
  await tester.pump(duration);
}

Future<void> _tapArrived(WidgetTester tester) async {
  final button = find.byKey(const ValueKey<String>('active-ride-arrived-button'));
  expect(button, findsOneWidget);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump(const Duration(milliseconds: 240));
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _slide(WidgetTester tester) async {
  final action = find.byKey(const ValueKey<String>('active-ride-primary-action'));
  expect(action, findsOneWidget);
  await tester.ensureVisible(action);
  await tester.drag(action, const Offset(320, 0));
  await tester.pump(const Duration(milliseconds: 240));
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _confirmShortTripIfAsked(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 220));
  final confirm = find.text('Confirm finish');
  if (confirm.evaluate().isNotEmpty) {
    await tester.tap(confirm);
  }
  for (var i = 0; i < 60 && find.byType(DriverRideCompleted).evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 25));
  }
  await tester.pump(const Duration(milliseconds: 1100));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleMapsFlutterPlatform.instance = HeadlessMapPlatform();
    CompletionJournal.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('launch, accept, complete, and return home once', (tester) async {
    WaybillStore.reset();
    addTearDown(() {
      WaybillStore.reset();
      tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(375, 812));
    await tester.pumpWidget(const MoveraApp());
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(DriverHome), findsOneWidget);
    expect(find.text('Demo mode — no account'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('headless-map')), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('OFF'));
    await tester.pump(const Duration(milliseconds: 3800));
    final acceptButton = find.ancestor(
      of: find.text('Accept'),
      matching: find.byType(FilledButton),
    );
    tester.widget<FilledButton>(acceptButton).onPressed!.call();
    await _advance(tester, const Duration(milliseconds: 520));
    expect(find.byType(AcceptRide), findsOneWidget);

    await _tapArrived(tester);
    await _slide(tester);
    await _slide(tester);
    await _confirmShortTripIfAsked(tester);
    expect(find.byType(DriverRideCompleted), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pump(const Duration(milliseconds: 420));
    expect(find.byType(DriverHome), findsOneWidget);
    expect(find.text('OFF'), findsOneWidget);
    expect(find.byType(AcceptRide), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('driver cancel reason can be dismissed without ending the trip', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const MaterialApp(home: AcceptRide()));
    await tester.pump(const Duration(milliseconds: 160));

    await _tapArrived(tester);
    await _slide(tester);
    expect(find.textContaining('Dropping off'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('active-ride-trip-options')));
    await tester.pump(const Duration(milliseconds: 220));
    await tester.tap(find.byKey(const ValueKey<String>('active-ride-cancel-option')));
    await tester.pump(const Duration(milliseconds: 260));
    expect(
      find.byKey(const ValueKey<String>('trip-cancellation-reasons-sheet')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>('trip-cancel-reason-rider_requested_early_end'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 260));
    await tester.tap(find.text('Keep trip'));
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.textContaining('Dropping off'), findsOneWidget);
    expect(find.byType(DriverHome), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
