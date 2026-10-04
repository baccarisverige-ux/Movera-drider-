import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/presentation/driver/accept%20ride/trip_bottom_bar.dart';
import 'package:movera/widgets/route_mark_pins.dart';

Widget _bar({
  bool cash = false,
  RouteMarkKind mark = RouteMarkKind.pickup,
  bool expanded = false,
  bool showDetailsButton = true,
  double? waitFraction,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: 900,
          child: TripBottomBar(
            etaLabel: '42 min',
            distanceLabel: '37.3 km',
            statusLabel: 'Heading to pickup',
            nextAddress: 'Kungsgatan 42',
            nextMark: mark,
            progress: 0.3,
            paidByCash: cash,
            expanded: expanded,
            showDetailsButton: showDetailsButton,
            waitFraction: waitFraction,
            onPreferences: () {},
            onDetails: () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Bar shows time, distance, the next address and a card logo', (
    tester,
  ) async {
    await tester.pumpWidget(_bar());
    expect(find.text('42 min'), findsOneWidget);
    expect(find.text('37.3 km'), findsOneWidget);
    expect(find.text('Kungsgatan 42'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('trip-pay-card')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('trip-pay-cash')), findsNothing);
    // No fare amount in the bar.
    expect(find.textContaining('kr'), findsNothing);
  });

  testWidgets('Cash trips show the cash logo', (tester) async {
    await tester.pumpWidget(_bar(cash: true));
    expect(find.byKey(const ValueKey<String>('trip-pay-cash')), findsOneWidget);
    expect(find.byTooltip('Cash: collect in the car'), findsOneWidget);
  });

  testWidgets('A stop is marked as a stop, not the final destination', (
    tester,
  ) async {
    await tester.pumpWidget(_bar(mark: RouteMarkKind.stop));
    final marks = tester.widgetList<RouteMarkIcon>(find.byType(RouteMarkIcon));
    expect(marks.map((m) => m.kind), everyElement(RouteMarkKind.stop));
  });

  testWidgets('Open sheet header names the step instead of the address', (
    tester,
  ) async {
    await tester.pumpWidget(_bar(expanded: true, showDetailsButton: true));
    expect(find.text('Heading to pickup'), findsOneWidget);
    expect(find.text('Kungsgatan 42'), findsNothing);
  });

  testWidgets('Waiting shows the wait line and the step', (tester) async {
    await tester.pumpWidget(_bar(waitFraction: 0.5));
    expect(find.byKey(const ValueKey<String>('trip-wait-line')), findsOneWidget);
    expect(find.text('Heading to pickup'), findsOneWidget);
  });
}
