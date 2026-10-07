import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/routing/route_instruction.dart';
import 'package:movera/presentation/driver/accept%20ride/navigation_instruction_banner.dart';
import 'package:movera/presentation/driver/accept%20ride/adaptive_trip_island.dart';

Widget surface({
  int? seconds,
  VoidCallback? route,
  String waitingMessage = 'Waiting for Angelica',
  double width = 320,
  double textScale = 1,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(
    body: RepaintBoundary(
      key: const ValueKey('island-visual-proof'),
      child: SizedBox(
        width: width,
        height: 220,
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
          waitingMessage: waitingMessage,
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
  ),
);

void main() {
  testWidgets('Record rendered guidance and alternating waiting views', (
    tester,
  ) async {
    Future<void> capture(String name) async {
      await tester.pump();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('island-visual-proof')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/test-evidence/island-$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await tester.pumpWidget(surface());
    await capture('guidance');
    await tester.pumpWidget(surface(seconds: 125));
    await tester.pump(const Duration(seconds: 1));
    await capture('timer');
    await tester.pump(const Duration(seconds: 7));
    await tester.pump(const Duration(seconds: 1));
    await capture('rider-message');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'Waiting digit ticks keep geometry stable and stop message is distinct',
    (tester) async {
      await tester.pumpWidget(
        surface(seconds: 9, waitingMessage: 'Waiting at stop 2'),
      );
      final size = tester.getSize(
        find.byKey(const ValueKey('island-morph-shell')),
      );
      await tester.pumpWidget(
        surface(seconds: 10, waitingMessage: 'Waiting at stop 2'),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('island-morph-shell'))),
        size,
      );
      await tester.pump(const Duration(seconds: 8));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Waiting at stop 2'), findsOneWidget);
      expect(find.text('Waiting for Angelica'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Long waiting names and larger text fit narrow screens', (
    tester,
  ) async {
    await tester.pumpWidget(
      surface(
        seconds: 125,
        width: 280,
        textScale: 1.6,
        waitingMessage: 'Waiting for Angelica Alexandra',
      ),
    );
    await tester.pump(const Duration(seconds: 8));
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester.getSize(find.byKey(const ValueKey('island-morph-shell'))).width,
      lessThanOrEqualTo(256),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
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
