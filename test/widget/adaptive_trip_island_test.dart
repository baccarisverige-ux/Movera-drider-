import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
  String? fontFamily,
  String? arrival,
  NavigationBanner? banner,
  double progress = .4,
}) => MaterialApp(
  theme: ThemeData(fontFamily: fontFamily),
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
          banner:
              banner ??
              const NavigationBanner(
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
          arrival: arrival,
          progress: progress,
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
    String? font;
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root != null) {
      final file = File(
        '$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
      );
      if (file.existsSync()) {
        final loader = FontLoader('IslandProof')
          ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
        await loader.load();
        font = 'IslandProof';
      }
    }
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

    final stages = <String, NavigationBanner>{
      '01-pickup': const NavigationBanner(
        primary: 'Toward pickup · 450 m',
        distanceLabel: '',
        symbol: NavigationBannerSymbol.arrive,
      ),
      '02-straight': const NavigationBanner(
        primary: 'Continue ahead · 800 m',
        distanceLabel: '',
        symbol: NavigationBannerSymbol.straight,
      ),
      '03-right': const NavigationBanner(
        primary: 'Turn right · 180 m',
        distanceLabel: '',
        roadName: 'Sveavägen',
        symbol: NavigationBannerSymbol.right,
      ),
      '04-roundabout': const NavigationBanner(
        primary: 'Take 2nd exit',
        distanceLabel: 'Roundabout · 50 m',
        exitNumber: '2',
        exitAngleDegrees: 90,
        symbol: NavigationBannerSymbol.roundabout,
      ),
      '08-trip-started': const NavigationBanner(
        primary: 'Taking Angelica to destination',
        distanceLabel: '',
        symbol: NavigationBannerSymbol.arrive,
      ),
      '09-dropoff': const NavigationBanner(
        primary: 'Keep left · 300 m',
        distanceLabel: '',
        roadName: 'E4 toward Stockholm',
        symbol: NavigationBannerSymbol.slightLeft,
      ),
      '10-stop': const NavigationBanner(
        primary: 'Arriving at stop · 100 m',
        distanceLabel: '',
        symbol: NavigationBannerSymbol.arrive,
      ),
    };
    for (final entry in stages.entries) {
      await tester.pumpWidget(surface(fontFamily: font, banner: entry.value));
      await tester.pump(const Duration(seconds: 1));
      await capture(entry.key);
    }
    await tester.pumpWidget(surface(fontFamily: font, arrival: 'Pickup'));
    await tester.pump(const Duration(seconds: 1));
    await capture('05-arrival-pickup');
    await tester.pumpWidget(surface(seconds: 155, fontFamily: font));
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 33));
      await capture('motion-${frame.toString().padLeft(3, '0')}');
    }
    await capture('06-timer');
    for (
      var tick = 0;
      tick < 50 &&
          find.byKey(const ValueKey('island-waiting-name')).evaluate().isEmpty;
      tick++
    ) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Waiting for Angelica'), findsOneWidget);
    await capture('07-rider-message');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      surface(
        seconds: 155,
        fontFamily: font,
        waitingMessage: 'Waiting at stop 2',
      ),
    );
    await capture('10b-stop-timer');
    await tester.pump(const Duration(seconds: 8));
    await tester.pump(const Duration(seconds: 1));
    await capture('10c-stop-message');
    await tester.pumpWidget(surface(fontFamily: font, arrival: 'Destination'));
    await tester.pump(const Duration(seconds: 1));
    await capture('11-arrival-destination');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Normal islands stay compact at phone width', (tester) async {
    await tester.pumpWidget(surface(width: 375));
    final driving = tester.getSize(
      find.byKey(const ValueKey('island-morph-shell')),
    );
    expect(driving.height, lessThanOrEqualTo(104));
    expect(driving.width, lessThanOrEqualTo(351));
    await tester.pumpWidget(surface(width: 375, seconds: 155));
    await tester.pump(const Duration(seconds: 1));
    final waiting = tester.getSize(
      find.byKey(const ValueKey('island-morph-shell')),
    );
    expect(waiting.height, lessThanOrEqualTo(78));
    expect(waiting.width, lessThanOrEqualTo(244));
    expect(waiting.width, lessThan(driving.width));
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
