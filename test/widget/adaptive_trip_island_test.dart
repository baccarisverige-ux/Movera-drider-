import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/routing/route_instruction.dart';
import 'package:movera/presentation/driver/accept%20ride/navigation_instruction_banner.dart';
import 'package:movera/presentation/driver/accept%20ride/adaptive_trip_island.dart';

Widget surface({int? seconds, VoidCallback? route}) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: 320,
      child: AdaptiveTripIsland(
        banner: const NavigationBanner(
          primary: 'Roundabout, exit 3',
          distanceLabel: '150 m',
          symbol: NavigationBannerSymbol.roundabout,
          roadName: 'Sveavägen',
        ),
        status: 'To pickup',
        address: 'Sveavägen 20',
        detail: 'Picking up Angelica',
        eta: '2 min',
        distance: '1.4 km',
        progress: .4,
        waitingSeconds: seconds,
        waitingMessage: 'Waiting for Angelica',
        lastTripLabel: '120 kr',
        onRadar: () {},
        onMenu: () {},
        onSearch: () {},
        onHistory: () {},
        onRoute: route ?? () {},
        onSafety: () {},
        onWait: () {},
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'Island presents one maneuver and relocated route; touch restores after idle',
    (tester) async {
      var route = 0;
      await tester.pumpWidget(surface(route: () => route++));
      expect(find.text('Roundabout, exit 3'), findsOneWidget);
      final cue = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((paint) => paint.painter)
          .whereType<NavigationCuePainter>()
          .single;
      expect(cue.exitNumber, '3');
      expect(find.text('Sveavägen 20'), findsNothing);
      expect(find.text('To pickup'), findsNothing);
      expect(find.text('150 m · Sveavägen'), findsOneWidget);
      await tester.tap(find.byTooltip('Trip route and options'));
      await tester.pump();
      expect(
        route,
        1,
        reason: 'Touching the island must not swallow its controls.',
      );
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.byKey(const ValueKey('trip-default-island')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.byKey(const ValueKey('trip-default-island')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 900));
      expect(
        find.byKey(const ValueKey('trip-guidance-island')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('trip-default-island')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Waiting alternates timer and rider name, then disposes timers', (
    tester,
  ) async {
    await tester.pumpWidget(surface(seconds: 125));
    expect(find.text('02:05'), findsOneWidget);
    expect(find.text('Waiting for Angelica'), findsNothing);
    await tester.pump(const Duration(seconds: 8));
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('Waiting for Angelica'), findsOneWidget);
    expect(find.text('02:05'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('02:05'), findsOneWidget);
    expect(find.text('Waiting for Angelica'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
    expect(tester.takeException(), isNull);
  });
}
