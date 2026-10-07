import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/presentation/driver/accept%20ride/trip_bottom_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movera/constants/appassets.dart';

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
      expect(find.text('2 min · 1.4 km'), findsOneWidget);
      expect(find.text('Picking up Michael'), findsOneWidget);
      expect(find.text("I've arrived"), findsNothing);
      expect(find.byKey(const ValueKey('trip-progress-line')), findsOneWidget);
      final icon = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(icon.bytesLoader, isA<SvgAssetLoader>());
      expect(
        (icon.bytesLoader as SvgAssetLoader).assetName,
        AppAssets.navMenuBranch,
      );
      await tester.tap(find.byTooltip('Ride preferences'));
      await tester.tap(find.byTooltip('Trip details'));
      expect(preferences, 1);
      expect(details, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Waiting dock shows only centered status, never a timer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: TripBottomBar(
              etaLabel: '1:30',
              statusLabel: 'Waiting for Angelica at stop 2',
              waiting: true,
              onPreferences: () {},
              onDetails: () {},
            ),
          ),
        ),
      ),
    );
    final pill = find.byKey(const ValueKey('trip-sheet-waiting-timer'));
    expect(pill, findsNothing);
    expect(find.text('1:30'), findsNothing);
    expect(find.byIcon(Icons.timer_outlined), findsNothing);
    expect(
      tester.getCenter(find.text('Waiting for Angelica at stop 2')).dx,
      closeTo(160, 1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Journey keeps every stop and progresses toward the active point',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: TripBottomBar(
                etaLabel: '7 min',
                distanceLabel: '2.8 km',
                statusLabel: 'Toward stop 2',
                stopCount: 3,
                nextPointIndex: 2,
                legFraction: 0.5,
                onPreferences: _noop,
                onDetails: _noop,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final paint = tester.widget<CustomPaint>(
        find.byKey(const ValueKey('trip-progress-line')),
      );
      final painter = paint.painter! as JourneyLanePainter;
      expect(painter.stopCount, 3);
      expect(painter.target, 2);
      expect(painter.progress, 0.5);
      expect(tester.getSize(find.byType(TripBottomBar)).height, 76);
      expect(tester.takeException(), isNull);
    },
  );
}

void _noop() {}
