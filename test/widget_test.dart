import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/main.dart';
import 'package:movera/presentation/driver/accept%20ride/accept_ride.dart';
import 'package:movera/presentation/driver/destination%20mode/destination_picker.dart';
import 'package:movera/presentation/driver/home/home.dart';
import 'package:movera/presentation/driver/home/components/driver_sheet_nav.dart';
import 'package:movera/presentation/driver/my%20wallet/wallet.dart';
import 'package:movera/presentation/driver/ride%20history/ride_history.dart';
import 'package:movera/presentation/driver/ride%20requests/ride_requests.dart';
import 'package:movera/presentation/driver/scheduled%20rides/scheduled_rides.dart';
import 'package:movera/presentation/driver/safety%20toolkits/safety_toolkits.dart';
import 'package:movera/presentation/driver/support/support_inbox.dart';
import 'package:movera/widgets/custom_google_map.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

Future<void> _pumpHome(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(const MoveraApp());

  // ScreenUtilInit with ensureScreenSize initializes on the next frame.
  await tester.pump(const Duration(milliseconds: 120));
  expect(find.byType(DriverHome), findsOneWidget);

  final startupException = tester.takeException();
  expect(startupException, isNull, reason: startupException?.toString());
}

void _expectNoException(WidgetTester tester) {
  final exception = tester.takeException();
  expect(exception, isNull, reason: exception?.toString());
}

Future<void> _advanceAnimation(
  WidgetTester tester,
  Duration duration,
) async {
  await tester.pump();
  await tester.pump(duration);
}

Future<void> _openPanel(WidgetTester tester) async {
  final panel = tester.widget<SlidingUpPanel>(find.byType(SlidingUpPanel));
  panel.controller!.open();
  await _advanceAnimation(tester, const Duration(milliseconds: 520));
}

Future<void> _closePanel(WidgetTester tester) async {
  final panel = tester.widget<SlidingUpPanel>(find.byType(SlidingUpPanel));
  panel.controller!.close();
  await _advanceAnimation(tester, const Duration(milliseconds: 520));
}

void _invokeTooltipAction(WidgetTester tester, String tooltip) {
  final tooltips = find.byTooltip(tooltip);
  expect(tooltips, findsWidgets);
  final taps = find.descendant(
    of: tooltips,
    matching: find.byType(InkWell),
  );
  final action = tester
      .widgetList<InkWell>(taps)
      .firstWhere((widget) => widget.onTap != null);
  action.onTap!.call();
}

void main() {
  const phoneSizes = <Size>[
    Size(320, 700),
    Size(375, 812),
    Size(390, 844),
    Size(430, 932),
  ];

  for (final size in phoneSizes) {
    testWidgets(
      'Driver Home sheet is layout-safe at ${size.width.toInt()}x${size.height.toInt()}',
      (WidgetTester tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await _pumpHome(tester, size);

        await _openPanel(tester);
        expect(find.text('Driver overview').hitTestable(), findsOneWidget);
        _expectNoException(tester);

        await _closePanel(tester);
        _expectNoException(tester);
      },
    );
  }

  for (final size in phoneSizes) {
    testWidgets(
      'Scheduled Rides is layout-safe at ${size.width.toInt()}x${size.height.toInt()}',
      (WidgetTester tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          const MaterialApp(home: ScheduledRidesScreen()),
        );
        await tester.pump(const Duration(milliseconds: 120));

        expect(find.text('Scheduled rides'), findsOneWidget);
        expect(find.text('Requests'), findsOneWidget);
        _expectNoException(tester);

        await tester.tap(find.text('Accepted'));
        await tester.pump(const Duration(milliseconds: 120));

        expect(find.text('Upcoming'), findsOneWidget);
        _expectNoException(tester);
      },
    );
  }

  testWidgets('Home sheet survives rapid open-close-open without stale map blocking', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(320, 700));

    final panel =
        tester.widget<SlidingUpPanel>(find.byType(SlidingUpPanel));
    panel.controller!.open();
    await tester.pump(const Duration(milliseconds: 140));
    panel.controller!.close();
    await tester.pump(const Duration(milliseconds: 140));
    panel.controller!.open();
    await _advanceAnimation(tester, const Duration(milliseconds: 520));

    var latestPanel =
        tester.widget<SlidingUpPanel>(find.byType(SlidingUpPanel));
    expect((latestPanel.body! as AbsorbPointer).absorbing, isTrue);
    expect(find.text('Driver overview').hitTestable(), findsOneWidget);
    _expectNoException(tester);

    latestPanel.controller!.close();
    await _advanceAnimation(tester, const Duration(milliseconds: 520));

    latestPanel = tester.widget<SlidingUpPanel>(find.byType(SlidingUpPanel));
    expect((latestPanel.body! as AbsorbPointer).absorbing, isFalse);
    _expectNoException(tester);
  });

  testWidgets('Home drawer opens without overflow on narrow phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(320, 700));

    final scaffoldState =
        tester.state<ScaffoldState>(find.byType(Scaffold).first);
    scaffoldState.openDrawer();
    await _advanceAnimation(tester, const Duration(milliseconds: 420));

    expect(scaffoldState.isDrawerOpen, isTrue);
    _expectNoException(tester);
  });

  testWidgets('Collapsed dock actions are wired safely in isolation', (
    WidgetTester tester,
  ) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final pulseController = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 2600),
    );
    addTearDown(pulseController.dispose);

    var scheduledTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          key: scaffoldKey,
          drawer: const Drawer(child: Text('Menu drawer')),
          body: Builder(
            builder: (context) => Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: 108,
                child: DriverSheetNav.collapsedDock(
                  context: context,
                  scaffoldKey: scaffoldKey,
                  isOnline: false,
                  hasScheduledRideOffers: true,
                  goOnlinePulseController: pulseController,
                  onOpenScheduledRides: () {
                    scheduledTapped = true;
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final wallet = find.byTooltip('Wallet');
    expect(wallet, findsOneWidget);
    await tester.tap(wallet);
    await tester.pumpAndSettle();
    expect(find.byType(WalletScreen), findsOneWidget);
    _expectNoException(tester);
    Navigator.of(tester.element(find.byType(WalletScreen))).pop();
    await tester.pumpAndSettle();

    final inbox = find.byTooltip('Inbox');
    expect(inbox, findsOneWidget);
    await tester.tap(inbox);
    await tester.pumpAndSettle();
    expect(find.byType(SupportInboxScreen), findsOneWidget);
    _expectNoException(tester);
    Navigator.of(tester.element(find.byType(SupportInboxScreen))).pop();
    await tester.pumpAndSettle();

    final scheduled = find.byTooltip('Scheduled');
    expect(scheduled, findsOneWidget);
    await tester.tap(scheduled);
    await tester.pump();
    expect(scheduledTapped, isTrue);
    _expectNoException(tester);

    final menu = find.byTooltip('Menu');
    expect(menu, findsOneWidget);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    expect(scaffoldKey.currentState?.isDrawerOpen, isTrue);
    _expectNoException(tester);
  });

  testWidgets('Sheet open and close correctly blocks and releases map input', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    SlidingUpPanel panel =
        tester.widget<SlidingUpPanel>(find.byType(SlidingUpPanel));
    expect(panel.body, isA<AbsorbPointer>());
    expect((panel.body! as AbsorbPointer).absorbing, isFalse);

    await _openPanel(tester);
    panel = tester.widget<SlidingUpPanel>(find.byType(SlidingUpPanel));
    expect((panel.body! as AbsorbPointer).absorbing, isTrue);
    _expectNoException(tester);

    await _closePanel(tester);
    panel = tester.widget<SlidingUpPanel>(find.byType(SlidingUpPanel));
    expect((panel.body! as AbsorbPointer).absorbing, isFalse);
    _expectNoException(tester);
  });

  testWidgets('Full radar orb responds near its outer edge', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    final target = find.byKey(
      const ValueKey<String>('trip-radar-touch-target'),
    );
    expect(target, findsOneWidget);
    expect(tester.getSize(target), const Size(104, 104));

    final rect = tester.getRect(target);
    await tester.tapAt(Offset(rect.right - 4, rect.center.dy));
    await tester.pump();

    expect(find.text('STARTING'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1550));
    expect(find.text('LIVE'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('Closing radar list keeps alert while nearby offers remain', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    await tester.tap(find.text('OFF'));
    await tester.pump(const Duration(milliseconds: 1550));
    expect(find.text('LIVE'), findsOneWidget);

    // First direct offer.
    await tester.pump(const Duration(milliseconds: 2300));
    expect(find.text('104,80 kr'), findsOneWidget);

    // Let it expire, then allow the second direct-offer condition to run.
    await tester.pump(const Duration(milliseconds: 9000));
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pump(const Duration(milliseconds: 9000));

    // Normal radar offer arrives later and opens the radar list.
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(RideRequests), findsOneWidget);
    _expectNoException(tester);

    await tester.tap(find.byTooltip('Back'));
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(RideRequests), findsNothing);
    expect(find.text('Trip found'), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('Destination Mode sets one route and auto-starts online', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    final openDestination = find.byKey(
      const ValueKey<String>('destination-mode-open'),
    );
    expect(openDestination, findsOneWidget);
    final destinationControl = tester.widget<InkWell>(openDestination);
    expect(destinationControl.onTap, isNotNull);
    destinationControl.onTap!.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 520));

    expect(find.byType(DriverDestinationPicker), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('destination-search')),
      findsOneWidget,
    );
    expect(find.byType(CustomGoogleMap), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('destination-result-solna')),
      findsOneWidget,
    );
    _expectNoException(tester);

    await tester.tap(
      find.byKey(const ValueKey<String>('destination-result-solna')),
    );
    await tester.pump(const Duration(milliseconds: 420));

    expect(find.byType(DriverHome), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('destination-mode-home-tab')),
      findsOneWidget,
    );
    expect(find.text('STARTING'), findsOneWidget);

    final map = tester.widget<CustomGoogleMap>(
      find.byType(CustomGoogleMap).first,
    );
    expect(
      map.polylines!.any(
        (polyline) =>
            polyline.polylineId.value == 'destination_mode_route' &&
            polyline.points.length == 2,
      ),
      isTrue,
    );
    expect(
      map.markers!.any(
        (marker) => marker.markerId.value == 'destination_mode_target',
      ),
      isTrue,
    );

    await tester.pump(const Duration(milliseconds: 1550));
    expect(find.text('LIVE'), findsOneWidget);
    _expectNoException(tester);

    final endDestination = find.byKey(
      const ValueKey<String>('destination-mode-end'),
    );
    expect(endDestination, findsOneWidget);
    tester.widget<InkWell>(endDestination).onTap!.call();
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('destination-mode-home-tab')),
      findsNothing,
    );
    expect(find.text('LIVE'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('Home destination control does not block the map area', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    final destinationControl = find.byKey(
      const ValueKey<String>('destination-mode-open'),
    );
    expect(destinationControl, findsOneWidget);

    final interceptor = find.ancestor(
      of: destinationControl,
      matching: find.byType(PointerInterceptor),
    );
    expect(interceptor, findsOneWidget);

    final interceptorSize = tester.getSize(interceptor);
    expect(interceptorSize.width, lessThan(180));
    expect(interceptorSize.height, lessThan(80));
    _expectNoException(tester);
  });

  testWidgets('Destination picker remains layout-safe on narrow phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 700));
    await tester.pumpWidget(
      const MaterialApp(home: DriverDestinationPicker()),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Destination'), findsOneWidget);
    expect(find.text('Choose one address'), findsOneWidget);
    expect(find.text('Suggested addresses'), findsOneWidget);
    expect(find.byType(CustomGoogleMap), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('destination-search')),
      findsOneWidget,
    );
    _expectNoException(tester);
  });

  testWidgets('Destination radar only shows same-way frontend offers', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(375, 812));
    await tester.pumpWidget(
      const MaterialApp(
        home: RideRequests(
          destinationModeActive: true,
          destinationAddress: 'Solna Torg, Solna',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(
      find.byKey(const ValueKey<String>('radar-destination-filter')),
      findsOneWidget,
    );
    expect(find.textContaining('Trips toward Solna Torg'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nearby-1')), findsNothing);
    expect(find.byKey(const ValueKey<String>('nearby-2')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nearby-3')), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('Trip radar online and Go offline sheet flow is safe', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    expect(find.text('OFF'), findsOneWidget);
    await tester.tap(find.text('OFF'));
    await tester.pump(const Duration(milliseconds: 1550));

    expect(find.text('LIVE'), findsOneWidget);
    _expectNoException(tester);

    await _openPanel(tester);
    final goOfflineText = find.text('Go offline');
    expect(goOfflineText, findsOneWidget);
    final goOfflineButton = find.ancestor(
      of: goOfflineText,
      matching: find.byType(OutlinedButton),
    );
    expect(goOfflineButton, findsOneWidget);
    final button = tester.widget<OutlinedButton>(goOfflineButton);
    expect(button.onPressed, isNotNull);
    button.onPressed!.call();
    await _advanceAnimation(tester, const Duration(milliseconds: 520));

    expect(find.text('OFF'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('Online state survives Scheduled Rides navigation and return', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    await tester.tap(find.text('OFF'));
    await tester.pump(const Duration(milliseconds: 1550));
    expect(find.text('LIVE'), findsOneWidget);

    await _openPanel(tester);
    final scheduledTooltips = find.byTooltip('Scheduled');
    expect(scheduledTooltips, findsWidgets);
    final scheduledTaps = find.descendant(
      of: scheduledTooltips,
      matching: find.byType(InkWell),
    );
    final scheduledAction = tester
        .widgetList<InkWell>(scheduledTaps)
        .firstWhere((widget) => widget.onTap != null);
    scheduledAction.onTap!.call();
    await _advanceAnimation(tester, const Duration(milliseconds: 420));

    expect(find.byType(ScheduledRidesScreen), findsOneWidget);
    _expectNoException(tester);

    Navigator.of(tester.element(find.byType(ScheduledRidesScreen))).pop();
    await _advanceAnimation(tester, const Duration(milliseconds: 420));

    expect(find.byType(DriverHome), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('Go offline'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('Going offline cancels pending direct-offer state', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    await tester.tap(find.text('OFF'));
    await tester.pump(const Duration(milliseconds: 1550));
    expect(find.text('LIVE'), findsOneWidget);

    await _openPanel(tester);
    final goOfflineText = find.text('Go offline');
    final goOfflineButton = find.ancestor(
      of: goOfflineText,
      matching: find.byType(OutlinedButton),
    );
    final button = tester.widget<OutlinedButton>(goOfflineButton);
    button.onPressed!.call();
    await _advanceAnimation(tester, const Duration(milliseconds: 520));

    expect(find.text('OFF'), findsOneWidget);

    // Advance beyond the first direct-offer timer. Nothing may appear offline.
    await tester.pump(const Duration(milliseconds: 4200));
    expect(find.text('104,80 kr'), findsNothing);
    expect(find.text('Direct request outside radar'), findsNothing);
    expect(find.text('OFF'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('Direct offer timeout returns Home to scanning state', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    await tester.tap(find.text('OFF'));
    await tester.pump(const Duration(milliseconds: 3800));

    expect(find.text('104,80 kr'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);

    // Advance in small frames so the async route-preview continuation can
    // install and then fire the 8.5s timeout timer.
    for (var i = 0; i < 20; i++) {
      if (find.text('104,80 kr').evaluate().isEmpty) break;
      await tester.pump(const Duration(milliseconds: 500));
    }

    expect(find.text('104,80 kr'), findsNothing);
    expect(find.text('Direct request outside radar'), findsNothing);
    expect(find.text('LIVE'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('Today summary opens, closes, and resets when radar starts', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    final launcherInk = find.byKey(
      const ValueKey<String>('last-trip-launcher'),
    );
    expect(launcherInk, findsOneWidget);
    tester.widget<InkWell>(launcherInk).onTap!.call();
    await _advanceAnimation(tester, const Duration(milliseconds: 520));

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('183.25 kr'), findsOneWidget);
    expect(find.text('3 rides'), findsOneWidget);
    var summaryPointer = tester.widget<IgnorePointer>(
      find.byKey(const ValueKey<String>('today-summary-pointer')),
    );
    expect(summaryPointer.ignoring, isFalse);
    _expectNoException(tester);

    final closeIcon = find.byIcon(Icons.close_rounded);
    final closeInk = find.ancestor(
      of: closeIcon,
      matching: find.byType(InkWell),
    );
    tester.widget<InkWell>(closeInk).onTap!.call();
    await _advanceAnimation(tester, const Duration(milliseconds: 520));
    summaryPointer = tester.widget<IgnorePointer>(
      find.byKey(const ValueKey<String>('today-summary-pointer')),
    );
    expect(summaryPointer.ignoring, isTrue);
    expect(
      find.byKey(const ValueKey<String>('last-trip-launcher')),
      findsOneWidget,
    );
    _expectNoException(tester);

    final launcherAgain = find.byKey(
      const ValueKey<String>('last-trip-launcher'),
    );
    tester.widget<InkWell>(launcherAgain).onTap!.call();
    await _advanceAnimation(tester, const Duration(milliseconds: 520));
    summaryPointer = tester.widget<IgnorePointer>(
      find.byKey(const ValueKey<String>('today-summary-pointer')),
    );
    expect(summaryPointer.ignoring, isFalse);

    await tester.tap(find.text('OFF'));
    await tester.pump(const Duration(milliseconds: 1550));
    expect(find.text('LIVE'), findsOneWidget);
    summaryPointer = tester.widget<IgnorePointer>(
      find.byKey(const ValueKey<String>('today-summary-pointer')),
    );
    expect(summaryPointer.ignoring, isTrue);
    _expectNoException(tester);
  });

  testWidgets('Today summary uses compact card and closes when Home sheet expands', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    final launcher = find.byKey(
      const ValueKey<String>('last-trip-launcher'),
    );
    tester.widget<InkWell>(launcher).onTap!.call();
    await _advanceAnimation(tester, const Duration(milliseconds: 520));

    final card = find.byKey(
      const ValueKey<String>('today-summary-card'),
    );
    expect(card, findsOneWidget);
    expect(tester.getSize(card).width, 278);
    expect(find.text('Today'), findsOneWidget);
    _expectNoException(tester);

    final panel = tester.widget<SlidingUpPanel>(find.byType(SlidingUpPanel));
    panel.controller!.open();
    await _advanceAnimation(tester, const Duration(milliseconds: 520));

    final summaryPointer = tester.widget<IgnorePointer>(
      find.byKey(const ValueKey<String>('today-summary-pointer')),
    );
    expect(summaryPointer.ignoring, isTrue);
    _expectNoException(tester);
  });

  testWidgets('Outside-radar offer closes when Home sheet expands', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    await tester.tap(find.text('OFF'));
    await tester.pump(const Duration(milliseconds: 3800));
    expect(find.text('Direct request outside radar'), findsOneWidget);

    final panel = tester.widget<SlidingUpPanel>(find.byType(SlidingUpPanel));
    panel.controller!.open();
    await _advanceAnimation(tester, const Duration(milliseconds: 820));

    expect(find.text('Direct request outside radar'), findsNothing);
    expect(find.text('104,80 kr'), findsNothing);
    _expectNoException(tester);
  });

  testWidgets('Today summary History action opens Movera history', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    final launcher = find.byKey(
      const ValueKey<String>('last-trip-launcher'),
    );
    tester.widget<InkWell>(launcher).onTap!.call();
    await _advanceAnimation(tester, const Duration(milliseconds: 420));

    final historyButton = find.byKey(
      const ValueKey<String>('today-history-button'),
    );
    expect(historyButton, findsOneWidget);
    tester.widget<InkWell>(historyButton).onTap!.call();
    await _advanceAnimation(tester, const Duration(milliseconds: 360));

    expect(find.byType(DriverRideHistory), findsOneWidget);
    expect(find.text('Earnings & history'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('history-overview')),
      findsOneWidget,
    );
    _expectNoException(tester);
  });

  testWidgets('History exposes overview and full rides list on narrow phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 700));
    await tester.pumpWidget(
      const MaterialApp(home: DriverRideHistory()),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Earnings & history'), findsOneWidget);
    expect(find.text('1 482.75 kr'), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('history-view-all-rides')),
      findsOneWidget,
    );
    _expectNoException(tester);

    await tester.tap(
      find.byKey(const ValueKey<String>('history-view-all-rides')),
    );
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('All rides'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('history-all-rides')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('ride-001')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('ride-006')), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('History Today period aligns with Home daily summary', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(375, 812));
    await tester.pumpWidget(
      const MaterialApp(home: DriverRideHistory()),
    );
    await tester.pump(const Duration(milliseconds: 120));

    await tester.tap(find.text('Today'));
    await tester.pump(const Duration(milliseconds: 260));

    expect(find.text('183.25 kr'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('Safety button stays fixed when direct offer appears', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    AnimatedPositioned safetyPosition() {
      return tester.widget<AnimatedPositioned>(
        find.ancestor(
          of: find.byIcon(Icons.shield_outlined),
          matching: find.byType(AnimatedPositioned),
        ),
      );
    }

    expect(safetyPosition().bottom, 138);

    await tester.tap(find.text('OFF'));
    await tester.pump(const Duration(milliseconds: 3800));

    expect(find.text('Direct request outside radar'), findsOneWidget);
    expect(safetyPosition().bottom, 138);
    _expectNoException(tester);
  });

  testWidgets('Safety tools open from Home and basic actions remain usable', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(320, 700));

    final homeSafetyIcon = find.byIcon(Icons.shield_outlined);
    expect(homeSafetyIcon, findsOneWidget);
    final safetyInk = find.ancestor(
      of: homeSafetyIcon,
      matching: find.byType(InkWell),
    );
    tester.widget<InkWell>(safetyInk).onTap!.call();
    await _advanceAnimation(tester, const Duration(milliseconds: 420));

    expect(find.byType(SafetyToolKits), findsOneWidget);
    expect(find.text('Safety tools'), findsOneWidget);
    _expectNoException(tester);

    await tester.tap(find.text('Record audio'));
    await tester.pump();
    expect(find.text('Stop audio'), findsOneWidget);
    expect(
      find.text('Audio recording started. The file stays on this device.'),
      findsOneWidget,
    );
    _expectNoException(tester);

    await tester.tap(find.text('Share trip'));
    await tester.pump();
    expect(
      find.text('Trip sharing is ready for your trusted contacts.'),
      findsOneWidget,
    );
    _expectNoException(tester);

    await tester.tap(find.byTooltip('Close'));
    await _advanceAnimation(tester, const Duration(milliseconds: 420));
    expect(find.byType(SafetyToolKits), findsNothing);
    _expectNoException(tester);
  });

  testWidgets('Expanded Home quick actions navigate and return safely', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));
    await _openPanel(tester);

    _invokeTooltipAction(tester, 'Wallet');
    await _advanceAnimation(tester, const Duration(milliseconds: 420));
    expect(find.byType(WalletScreen), findsOneWidget);
    _expectNoException(tester);
    Navigator.of(tester.element(find.byType(WalletScreen))).pop();
    await _advanceAnimation(tester, const Duration(milliseconds: 420));

    expect(find.byType(DriverHome), findsOneWidget);
    _invokeTooltipAction(tester, 'Inbox');
    await _advanceAnimation(tester, const Duration(milliseconds: 420));
    expect(find.byType(SupportInboxScreen), findsOneWidget);
    _expectNoException(tester);
    Navigator.of(tester.element(find.byType(SupportInboxScreen))).pop();
    await _advanceAnimation(tester, const Duration(milliseconds: 420));

    expect(find.byType(DriverHome), findsOneWidget);
    _invokeTooltipAction(tester, 'Scheduled');
    await _advanceAnimation(tester, const Duration(milliseconds: 420));
    expect(find.byType(ScheduledRidesScreen), findsOneWidget);
    _expectNoException(tester);
    Navigator.of(tester.element(find.byType(ScheduledRidesScreen))).pop();
    await _advanceAnimation(tester, const Duration(milliseconds: 420));

    expect(find.byType(DriverHome), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('Direct Home offer Route and Accept path reaches active ride safely', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    await tester.tap(find.text('OFF'));
    await tester.pump(const Duration(milliseconds: 3800));

    expect(find.text('104,80 kr'), findsOneWidget);
    expect(find.text('Direct request outside radar'), findsOneWidget);

    final routeButton = find.ancestor(
      of: find.text('Route'),
      matching: find.byType(TextButton),
    );
    final route = tester.widget<TextButton>(routeButton);
    expect(route.onPressed, isNotNull);
    route.onPressed!.call();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('104,80 kr'), findsOneWidget);
    _expectNoException(tester);

    final acceptButton = find.ancestor(
      of: find.text('Accept'),
      matching: find.byType(FilledButton),
    );
    final accept = tester.widget<FilledButton>(acceptButton);
    expect(accept.onPressed, isNotNull);
    accept.onPressed!.call();
    await _advanceAnimation(tester, const Duration(milliseconds: 520));

    expect(find.byType(AcceptRide), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('Direct offer shows a visible expiry countdown', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    await tester.tap(find.text('OFF'));
    await tester.pump(const Duration(milliseconds: 3800));

    expect(find.text('Direct request outside radar'), findsOneWidget);
    expect(find.textContaining('Direct offer · '), findsOneWidget);
    expect(find.text('Limited time'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('Direct Home offer can appear without sheet/layout errors', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    await tester.tap(find.text('OFF'));
    await tester.pump(const Duration(milliseconds: 3800));

    expect(find.text('104,80 kr'), findsOneWidget);
    expect(find.text('Direct request outside radar'), findsOneWidget);
    _expectNoException(tester);
  });
}
