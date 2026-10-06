import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/presentation/driver/accept%20ride/trip_bottom_bar.dart';

void main() {
  testWidgets(
    'Collapsed dock shows rider summary and opens preferences and details',
    (tester) async {
      var preferences = 0, details = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: TripBottomBar(
                etaLabel: '2 min',
                distanceLabel: '1.4 km',
                statusLabel: 'Picking up Michael',
                onPreferences: () => preferences++,
                onDetails: () => details++,
              ),
            ),
          ),
        ),
      );
      expect(find.text('2 min'), findsOneWidget);
      expect(find.text('1.4 km'), findsOneWidget);
      expect(find.text('Picking up Michael'), findsOneWidget);
      expect(find.text("I've arrived"), findsNothing);
      expect(find.byKey(const ValueKey('trip-progress-line')), findsNothing);
      await tester.tap(find.byTooltip('Ride preferences'));
      await tester.tap(find.byTooltip('Trip details'));
      expect(preferences, 1);
      expect(details, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Waiting dock uses a centered pill timer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: TripBottomBar(
              etaLabel: '1:30',
              statusLabel: 'Included wait · then paid',
              waiting: true,
              onPreferences: () {},
              onDetails: () {},
            ),
          ),
        ),
      ),
    );
    final pill = find.byKey(const ValueKey('trip-sheet-waiting-timer'));
    expect(pill, findsOneWidget);
    expect(find.text('1:30'), findsOneWidget);
    expect(tester.getCenter(pill).dx, closeTo(160, 1));
    expect(tester.takeException(), isNull);
  });
}
