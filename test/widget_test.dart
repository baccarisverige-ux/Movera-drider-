import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/main.dart';
import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/routing/route_repository.dart';
import 'package:movera/core/routing/route_instruction.dart';
import 'package:movera/core/waybill/waybill.dart';
import 'package:movera/presentation/driver/accept%20ride/accept_ride.dart';
import 'package:movera/presentation/driver/accept%20ride/navigation_instruction_banner.dart';
import 'package:movera/presentation/driver/destination%20mode/destination_picker.dart';
import 'package:movera/presentation/driver/home/home.dart';
import 'package:movera/presentation/driver/home/components/driver_sheet_nav.dart';
import 'package:movera/presentation/driver/home/components/radar_edge_dash.dart';
import 'package:movera/presentation/driver/my%20wallet/wallet.dart';
import 'package:movera/presentation/driver/ride%20history/ride_history.dart';
import 'package:movera/presentation/driver/ride%20requests/ride_requests.dart';
import 'package:movera/presentation/driver/ride%20completed/ride_completed.dart';
import 'package:movera/presentation/driver/scheduled%20rides/scheduled_rides.dart';
import 'package:movera/presentation/driver/safety%20toolkits/safety_toolkits.dart';
import 'package:movera/presentation/driver/support/support_inbox.dart';
import 'package:movera/widgets/custom_google_map.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

Future<void> _pumpHome(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(const MoveraApp());

  // Allow responsive layout and map placeholders to settle.
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

Future<void> _slideActiveRideAction(WidgetTester tester) async {
  final action =
      find.byKey(const ValueKey<String>('active-ride-primary-action'));
  expect(action, findsOneWidget);
  await tester.ensureVisible(action);
  await tester.drag(action, const Offset(320, 0));
  await tester.pump(const Duration(milliseconds: 240));
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

SlidingUpPanel _activeRidePanel(WidgetTester tester) {
  return tester.widgetList<SlidingUpPanel>(find.byType(SlidingUpPanel)).last;
}

Future<void> _collapseActiveRideSheet(WidgetTester tester) async {
  _activeRidePanel(tester).controller!.close();
  await _advanceAnimation(tester, const Duration(milliseconds: 520));
}

Future<void> _expandActiveRideSheet(WidgetTester tester) async {
  _activeRidePanel(tester).controller!.open();
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

  testWidgets('Driver menu is full-height, closes on scrim, and Back returns to menu', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(320, 700));

    final scaffoldState =
        tester.state<ScaffoldState>(find.byType(Scaffold).first);
    scaffoldState.openDrawer();
    await _advanceAnimation(tester, const Duration(milliseconds: 420));

    expect(scaffoldState.isDrawerOpen, isTrue);
    final drawer = find.byKey(const ValueKey<String>('driver-side-menu'));
    expect(drawer, findsOneWidget);
    expect(tester.getSize(drawer).height, 700);
    expect(find.byTooltip('Close menu'), findsNothing);
    _expectNoException(tester);

    // The uncovered map/scrim area closes the menu; no X button is required.
    await tester.tapAt(const Offset(316, 350));
    await _advanceAnimation(tester, const Duration(milliseconds: 420));
    expect(scaffoldState.isDrawerOpen, isFalse);
    _expectNoException(tester);

    // Top-level menu destinations keep the drawer open underneath. Back from
    // the destination therefore returns to the menu, not directly to the map.
    scaffoldState.openDrawer();
    await _advanceAnimation(tester, const Duration(milliseconds: 420));
    await tester.tap(find.text('Ride history'));
    await _advanceAnimation(tester, const Duration(milliseconds: 420));

    expect(find.byType(DriverRideHistory), findsOneWidget);
    _expectNoException(tester);

    Navigator.of(tester.element(find.byType(DriverRideHistory))).pop();
    await _advanceAnimation(tester, const Duration(milliseconds: 420));

    expect(find.byType(DriverRideHistory), findsNothing);
    expect(scaffoldState.isDrawerOpen, isTrue);
    expect(find.text('Ride history'), findsOneWidget);
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
                  hasRideOffers: false,
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

  testWidgets('Outside Radar stays separate and Radar offers survive list open-close', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    await tester.tap(find.text('OFF'));
    await tester.pump(const Duration(milliseconds: 1550));
    expect(find.text('LIVE'), findsOneWidget);

    // Outside-Radar offer uses its own exclusive surface.
    await tester.pump(const Duration(milliseconds: 2300));
    expect(find.text('104,80 kr'), findsOneWidget);
    expect(find.text('Outside Radar'), findsOneWidget);
    expect(find.text('Trip Radar offers'), findsNothing);
    _expectNoException(tester);

    // Let the outside offer expire, then allow the first Radar offer to arrive.
    await tester.pump(const Duration(milliseconds: 8500));
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Trip Radar offers'), findsOneWidget);
    expect(find.text('1 live'), findsOneWidget);
    expect(find.text('Outside Radar'), findsNothing);
    expect(find.text('Trip found'), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget);
    _expectNoException(tester);

    // Radar orb still opens the legacy/full Radar list.
    await tester.tap(find.text('Trip found'));
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.byType(RideRequests), findsOneWidget);
    _expectNoException(tester);

    await tester.tap(find.byTooltip('Back'));
    await tester.pump(const Duration(milliseconds: 160));

    // Returning to Home keeps the Home Radar opportunity alive.
    expect(find.byType(RideRequests), findsNothing);
    expect(find.text('Trip Radar offers'), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('Home Radar keeps a stable snapshot until driver refreshes', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(320, 700));

    await tester.tap(find.text('OFF'));
    await tester.pump(const Duration(milliseconds: 1550));

    // Outside offer first, still isolated from Radar.
    await tester.pump(const Duration(milliseconds: 2300));
    expect(find.text('104,80 kr'), findsOneWidget);
    expect(find.text('Trip Radar offers'), findsNothing);
    _expectNoException(tester);

    // Expire outside offer and receive the first Radar offer.
    await tester.pump(const Duration(milliseconds: 8500));
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('1 live'), findsOneWidget);
    _expectNoException(tester);

    // A second Radar match must NOT mutate the visible list.
    await tester.pump(const Duration(milliseconds: 3100));
    expect(find.text('Refresh · 1 new'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('radar-offer-home-radar-match-2')),
      findsNothing,
    );
    _expectNoException(tester);

    // A third match also waits behind the refresh action.
    await tester.pump(const Duration(milliseconds: 3100));
    expect(find.text('Refresh · 2 new'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('radar-offer-home-radar-match-3')),
      findsNothing,
    );
    _expectNoException(tester);

    // One explicit refresh updates the snapshot atomically.
    await tester.tap(
      find.byKey(const ValueKey<String>('radar-home-refresh')),
    );
    await tester.pump(const Duration(milliseconds: 160));

    expect(find.text('3 live'), findsOneWidget);
    expect(find.textContaining('Refresh · '), findsNothing);
    expect(find.text('Match'), findsWidgets);
    _expectNoException(tester);

    final radarList = find.byKey(
      const PageStorageKey<String>('radar-home-offers-list'),
    );
    expect(radarList, findsOneWidget);
    await tester.drag(radarList, const Offset(0, -360));
    await tester.pump(const Duration(milliseconds: 160));
    expect(
      find.byKey(const ValueKey<String>('radar-offer-home-radar-match-3')),
      findsOneWidget,
    );
    _expectNoException(tester);

    await tester.pump(const Duration(milliseconds: 4300));
    expect(find.text('Matched by another driver'), findsOneWidget);
    expect(find.text('Matched'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('Radar edge dash ignores outside offers and alerts on Radar offers', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    await tester.tap(find.text('OFF'));
    await tester.pump(const Duration(milliseconds: 1550));
    await tester.pump(const Duration(milliseconds: 2300));

    // Outside-Radar offer must not turn the Radar dash amber.
    final outsideDashes = tester.widgetList<RadarEdgeDash>(
      find.byType(RadarEdgeDash),
    );
    expect(outsideDashes, isNotEmpty);
    expect(
      outsideDashes.every(
        (dash) => dash.color == const Color(0xFF2FBE7B),
      ),
      isTrue,
    );

    await tester.pump(const Duration(milliseconds: 8500));
    await tester.pump(const Duration(milliseconds: 900));

    final radarDashes = tester.widgetList<RadarEdgeDash>(
      find.byType(RadarEdgeDash),
    );
    expect(
      radarDashes.any(
        (dash) => dash.color == const Color(0xFFFFA94D),
      ),
      isTrue,
    );
    _expectNoException(tester);
  });

  testWidgets('Full Radar disables a trip when another driver matches it', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(375, 812));
    await tester.pumpWidget(const MaterialApp(home: RideRequests()));
    await tester.pump(const Duration(milliseconds: 120));

    // Demo: nearby-3 is claimed remotely after 13 seconds.
    await tester.pump(const Duration(seconds: 13));
    final card = find.byKey(const ValueKey<String>('nearby-3'));
    expect(card, findsOneWidget);
    expect(
      find.descendant(
        of: card,
        matching: find.text('Matched by another driver'),
      ),
      findsOneWidget,
    );

    final button = tester.widget<FilledButton>(
      find.descendant(of: card, matching: find.byType(FilledButton)),
    );
    expect(button.onPressed, isNull);
    expect(
      find.descendant(of: card, matching: find.text('Matched')),
      findsOneWidget,
    );
    _expectNoException(tester);

    await tester.pump(const Duration(milliseconds: 2900));
    expect(card, findsNothing);
    _expectNoException(tester);
  });

  testWidgets('Full Radar resolves a simultaneous claim as request taken', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(375, 812));
    await tester.pumpWidget(const MaterialApp(home: RideRequests()));
    await tester.pump(const Duration(milliseconds: 120));

    // Demo: nearby-2 represents two drivers tapping Match at nearly
    // the same time, with the other driver winning the atomic claim.
    final card = find.byKey(const ValueKey<String>('nearby-2'));
    final match = find.descendant(of: card, matching: find.text('Match'));
    await tester.tap(match);
    await tester.pump();

    expect(find.text('Matching trip'), findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.text('Matching…')),
      findsOneWidget,
    );
    _expectNoException(tester);

    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('Request taken'), findsOneWidget);
    expect(
      find.descendant(
        of: card,
        matching: find.text('Matched by another driver'),
      ),
      findsOneWidget,
    );
    expect(find.byType(AcceptRide), findsNothing);
    _expectNoException(tester);
  });

  testWidgets('Full Radar winning Match opens the assigned ride', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(375, 812));
    await tester.pumpWidget(const MaterialApp(home: RideRequests()));
    await tester.pump(const Duration(milliseconds: 120));

    final card = find.byKey(const ValueKey<String>('nearby-1'));
    await tester.tap(
      find.descendant(of: card, matching: find.text('Match')),
    );
    await tester.pump();

    expect(find.text('Matching trip'), findsOneWidget);
    _expectNoException(tester);

    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('Trip matched'), findsOneWidget);
    final notice = tester.getRect(
      find.byKey(const ValueKey<String>('radar-match-notice')),
    );
    expect(notice.top, closeTo(0, 0.5));
    expect(notice.left, closeTo(0, 0.5));
    expect(notice.width, closeTo(375, 1));
    _expectNoException(tester);

    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byType(AcceptRide), findsOneWidget);
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
    // Routing is real-road only. In widget tests there is no live GPS/provider,
    // so Destination Mode must not invent a straight two-point route.
    expect(
      map.polylines!.any(
        (polyline) => polyline.polylineId.value == 'destination_mode_route',
      ),
      isFalse,
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

  testWidgets('Driver overview shows performance rates and scheduled card opens', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));
    await _openPanel(tester);

    expect(find.text('Performance'), findsOneWidget);
    expect(find.text('Acceptance'), findsOneWidget);
    expect(find.text('94%'), findsOneWidget);
    expect(find.text('Cancellation'), findsOneWidget);
    expect(find.text('2.4%'), findsOneWidget);
    _expectNoException(tester);

    final overviewList = find.byKey(
      const PageStorageKey<String>('driver-overview-list'),
    );
    expect(overviewList, findsOneWidget);
    await tester.drag(overviewList, const Offset(0, -360));
    await tester.pump(const Duration(milliseconds: 180));
    expect(find.text('What’s happening'), findsOneWidget);

    final scheduled = find.text('Scheduled rides available');
    await tester.ensureVisible(scheduled);
    await tester.tap(scheduled);
    await _advanceAnimation(tester, const Duration(milliseconds: 420));

    expect(find.byType(ScheduledRidesScreen), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('Home sheet shows Stockholm work areas under What’s happening', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));
    await _openPanel(tester);

    final overviewList = find.byKey(
      const PageStorageKey<String>('driver-overview-list'),
    );
    await tester.drag(overviewList, const Offset(0, -720));
    await tester.pump(const Duration(milliseconds: 220));

    expect(
      find.byKey(const ValueKey<String>('stockholm-work-stats')),
      findsOneWidget,
    );
    expect(find.text('Work in Stockholm'), findsOneWidget);
    expect(find.text('Södermalm'), findsOneWidget);
    expect(find.text('Norrmalm'), findsOneWidget);
    expect(find.text('Östermalm'), findsOneWidget);
    expect(find.text('Kungsholmen'), findsOneWidget);
    expect(find.text('Around Stockholm'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('Event details show date time and recommended driving window', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));
    await _openPanel(tester);

    final overviewList = find.byKey(
      const PageStorageKey<String>('driver-overview-list'),
    );
    expect(overviewList, findsOneWidget);
    await tester.drag(overviewList, const Offset(0, -520));
    await tester.pump(const Duration(milliseconds: 180));

    final event = find.text('Stockholm evening demand');
    expect(event, findsOneWidget);
    await tester.ensureVisible(event);
    await tester.tap(event);
    await _advanceAnimation(tester, const Duration(milliseconds: 420));

    expect(find.text('Fri 25 Sep'), findsOneWidget);
    expect(find.text('18:00–22:30'), findsOneWidget);
    expect(find.text('Best time to be online'), findsOneWidget);
    expect(find.text('18:30–22:00'), findsOneWidget);
    expect(find.text('Higher demand expected'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('Home sheet exposes the last completed waybill', (
    WidgetTester tester,
  ) async {
    WaybillStore.reset();
    WaybillStore.last = WaybillRecord(
      tripId: 'last-waybill-test',
      statusLabel: 'Completed',
      issuedAt: DateTime(2026, 9, 20, 20, 2),
      fare: '259,00 kr',
      service: 'Movera',
      riderName: 'Nicole',
      pickup: 'Hägersten, Stockholm',
      dropoff: 'Södertälje, Stockholm',
      source: 'Movera Radar',
      driverName: 'Movera Driver',
      vehicle: 'Movera partner vehicle',
      licensePlate: 'MVR 418',
      passengerCapacity: 4,
    );
    addTearDown(() {
      WaybillStore.reset();
      tester.binding.setSurfaceSize(null);
    });

    await _pumpHome(tester, const Size(375, 812));
    await _openPanel(tester);

    final lastWaybill = find.text('Last waybill');
    await tester.ensureVisible(lastWaybill);
    expect(lastWaybill, findsOneWidget);

    await tester.tap(lastWaybill);
    await tester.pump(const Duration(milliseconds: 320));

    expect(
      find.byKey(const ValueKey<String>('waybill-last-waybill-test')),
      findsOneWidget,
    );
    expect(find.text('259,00 kr'), findsWidgets);
    _expectNoException(tester);
  });

  testWidgets('Home exposes a dedicated driver location recenter control', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    expect(
      find.byKey(const ValueKey<String>('driver-location-zoom')),
      findsOneWidget,
    );
    final location = tester.getRect(
      find.byKey(const ValueKey<String>('driver-location-zoom')),
    );
    final safety = tester.getRect(find.byIcon(Icons.shield_outlined));
    expect(location.center.dy, closeTo(safety.center.dy, 16));
    expect(location.left, lessThan(safety.left));
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
    expect(find.text('Directly matched outside Trip Radar'), findsNothing);
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
    expect(find.text('Directly matched outside Trip Radar'), findsNothing);
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

    await tester.tap(find.byKey(const ValueKey<String>('today-summary-scrim')));
    await _advanceAnimation(tester, const Duration(milliseconds: 520));
    summaryPointer = tester.widget<IgnorePointer>(
      find.byKey(const ValueKey<String>('today-summary-pointer')),
    );
    expect(summaryPointer.ignoring, isTrue);
    _expectNoException(tester);

    tester.widget<InkWell>(launcherInk).onTap!.call();
    await _advanceAnimation(tester, const Duration(milliseconds: 520));

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

    await tester.tap(find.byKey(const ValueKey<String>('today-summary-scrim')));
    await tester.pump(const Duration(milliseconds: 200));
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
    expect(find.text('Directly matched outside Trip Radar'), findsOneWidget);

    final panel = tester.widget<SlidingUpPanel>(find.byType(SlidingUpPanel));
    panel.controller!.open();
    await _advanceAnimation(tester, const Duration(milliseconds: 820));

    expect(find.text('Directly matched outside Trip Radar'), findsNothing);
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
    _expectNoException(tester);

    await tester.drag(
      find.byKey(const ValueKey<String>('history-overview')),
      const Offset(0, -520),
    );
    await tester.pump(const Duration(milliseconds: 160));

    expect(
      find.byKey(const ValueKey<String>('history-view-all-rides')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('history-view-all-rides')),
    );
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('All rides'), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('history-all-rides')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('ride-001')), findsWidgets);

    await tester.drag(
      find.byKey(const ValueKey<String>('history-all-rides')),
      const Offset(0, -520),
    );
    await tester.pump(const Duration(milliseconds: 160));

    expect(
      find.byKey(const ValueKey<String>('history-all-rides')),
      findsOneWidget,
    );
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

    expect(find.text('Directly matched outside Trip Radar'), findsOneWidget);
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
    expect(find.text('Directly matched outside Trip Radar'), findsOneWidget);

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

  testWidgets('Matched ride flow moves safely through pickup, waiting and trip', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 700));
    await tester.pumpWidget(const MaterialApp(home: AcceptRide()));
    await tester.pump(const Duration(milliseconds: 160));

    expect(find.text('Heading to pickup'), findsOneWidget);
    expect(find.text('Slide to confirm pickup'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('active-ride-panel-headingToPickup')),
      findsOneWidget,
    );
    _expectNoException(tester);

    await _slideActiveRideAction(tester);

    expect(find.text('Waiting for rider'), findsWidgets);
    expect(find.text('Slide to start trip'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('active-ride-panel-waitingForRider')),
      findsOneWidget,
    );
    _expectNoException(tester);

    await _slideActiveRideAction(tester);

    expect(find.textContaining('Dropping off'), findsOneWidget);
    expect(find.text('Slide to complete trip'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('active-ride-panel-onTrip')),
      findsOneWidget,
    );
    _expectNoException(tester);

    await _slideActiveRideAction(tester);

    expect(find.byType(DriverRideCompleted), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('Completing a trip returns to the same online Home session', (
    WidgetTester tester,
  ) async {
    WaybillStore.reset();
    addTearDown(() {
      WaybillStore.reset();
      tester.binding.setSurfaceSize(null);
    });

    await _pumpHome(tester, const Size(375, 812));
    await tester.tap(find.text('OFF'));
    await tester.pump(const Duration(milliseconds: 3800));

    final acceptButton = find.ancestor(
      of: find.text('Accept'),
      matching: find.byType(FilledButton),
    );
    final accept = tester.widget<FilledButton>(acceptButton);
    accept.onPressed!.call();
    await _advanceAnimation(tester, const Duration(milliseconds: 520));

    expect(find.byType(AcceptRide), findsOneWidget);

    await _slideActiveRideAction(tester);
    await _slideActiveRideAction(tester);
    await _slideActiveRideAction(tester);
    await tester.pump(const Duration(milliseconds: 520));

    expect(find.byType(DriverRideCompleted), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pump(const Duration(milliseconds: 420));

    expect(find.byType(DriverHome), findsOneWidget);
    await _openPanel(tester);
    expect(find.text('Go offline'), findsOneWidget);
    await tester.ensureVisible(find.text('Last waybill'));
    expect(find.text('Last waybill'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('home-sheet-last-waybill')),
      findsOneWidget,
    );
    _expectNoException(tester);
  });

  testWidgets('Active ride blocks system back so the trip does not snap Home', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(375, 812));
    await tester.pumpWidget(const MaterialApp(home: AcceptRide()));
    await tester.pump(const Duration(milliseconds: 160));

    final popScope = tester.allWidgets.firstWhere(
      (widget) => widget.runtimeType.toString().startsWith('PopScope'),
    );
    expect((popScope as dynamic).canPop, isFalse);
    expect(find.byType(AcceptRide), findsOneWidget);
    expect(find.text('Heading to pickup'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('On-trip Radar stays hidden until a near-dropoff offer exists', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(375, 812));
    await tester.pumpWidget(const MaterialApp(home: AcceptRide()));
    await tester.pump(const Duration(milliseconds: 160));

    await _slideActiveRideAction(tester);
    await _slideActiveRideAction(tester);

    expect(find.textContaining('Dropping off'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('on-trip-radar-offer-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('on-trip-radar-offer-sheet')),
      findsNothing,
    );
    _expectNoException(tester);

    await tester.pump(const Duration(milliseconds: 2400));

    expect(
      find.byKey(const ValueKey<String>('on-trip-radar-offer-button')),
      findsOneWidget,
    );
    expect(find.textContaining('Dropping off'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('on-trip-radar-offer-sheet')),
      findsNothing,
    );
    _expectNoException(tester);

    await _collapseActiveRideSheet(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('on-trip-radar-offer-button')),
    );
    await tester.pump(const Duration(milliseconds: 260));

    expect(
      find.byKey(const ValueKey<String>('on-trip-radar-offer-sheet')),
      findsOneWidget,
    );
    expect(find.text('Available after your current drop-off'), findsOneWidget);
    expect(
      find.text(
        'Silent Radar does not change your map, route or current-trip controls.',
      ),
      findsOneWidget,
    );
    _expectNoException(tester);
  });

  testWidgets('Active ride slide blocks map pan while the finger is down', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(375, 812));
    await tester.pumpWidget(const MaterialApp(home: AcceptRide()));
    await tester.pump(const Duration(milliseconds: 160));

    expect(find.byType(PointerInterceptor), findsWidgets);
    CustomGoogleMap map = tester.widget<CustomGoogleMap>(
      find.byType(CustomGoogleMap),
    );
    expect(map.scrollGesturesEnabled, isTrue);

    final action =
        find.byKey(const ValueKey<String>('active-ride-primary-action'));
    final gesture = await tester.startGesture(tester.getCenter(action));
    await tester.pump();

    map = tester.widget<CustomGoogleMap>(find.byType(CustomGoogleMap));
    expect(map.scrollGesturesEnabled, isFalse);

    await gesture.up();
    await tester.pump();
    _expectNoException(tester);
  });

  testWidgets('On-trip Radar demo appears toward a city drop-off', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(375, 812));
    await tester.pumpWidget(
      const MaterialApp(
        home: AcceptRide(
          pickupPosition: LatLng(59.3295, 18.0475),
          dropoffPosition: LatLng(59.2705, 18.0515),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 160));

    await _slideActiveRideAction(tester);
    await _slideActiveRideAction(tester);
    await tester.pump(const Duration(milliseconds: 2400));

    expect(
      find.byKey(const ValueKey<String>('on-trip-radar-offer-button')),
      findsOneWidget,
    );
    _expectNoException(tester);
  });

  testWidgets('Secured next trip stays inside current ride panel and exposes waybill', (
    WidgetTester tester,
  ) async {
    WaybillStore.reset();
    addTearDown(() {
      WaybillStore.reset();
      tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(375, 812));
    await tester.pumpWidget(
      const MaterialApp(
        home: AcceptRide(
          fare: '156,80 kr',
          category: 'Comfort',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 160));

    await _slideActiveRideAction(tester);

    await _slideActiveRideAction(tester);

    await tester.pump(const Duration(milliseconds: 2400));
    await _collapseActiveRideSheet(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('on-trip-radar-offer-button')),
    );
    await tester.pump(const Duration(milliseconds: 260));

    final matchNext =
        find.byKey(const ValueKey<String>('on-trip-radar-match-next'));
    await tester.ensureVisible(matchNext);
    await tester.tap(matchNext);
    await tester.pump(const Duration(milliseconds: 1600));
    await _expandActiveRideSheet(tester);

    expect(
      find.byKey(const ValueKey<String>('secured-next-trip-details')),
      findsOneWidget,
    );
    expect(find.text('Next trip secured'), findsWidgets);
    expect(find.text('Vasagatan 10, Stockholm'), findsOneWidget);
    expect(find.text('Södermalm, Stockholm'), findsOneWidget);
    expect(WaybillStore.next, isNotNull);
    _expectNoException(tester);

    final waybillButton =
        find.byKey(const ValueKey<String>('next-trip-waybill'));
    await tester.ensureVisible(waybillButton);
    await tester.tap(waybillButton);
    await tester.pump(const Duration(milliseconds: 320));

    expect(
      find.byKey(
        ValueKey<String>('waybill-${WaybillStore.next!.tripId}'),
      ),
      findsOneWidget,
    );
    expect(find.text('Next trip waybill'), findsOneWidget);
    expect(find.text('Movera Radar'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('Secured next trip starts after the current drop-off is completed', (
    WidgetTester tester,
  ) async {
    WaybillStore.reset();
    addTearDown(() {
      WaybillStore.reset();
      tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(375, 812));
    await tester.pumpWidget(
      const MaterialApp(
        home: AcceptRide(
          fare: '156,80 kr',
          category: 'Comfort',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 160));

    await _slideActiveRideAction(tester);
    await _slideActiveRideAction(tester);
    await tester.pump(const Duration(milliseconds: 2400));
    await _collapseActiveRideSheet(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('on-trip-radar-offer-button')),
    );
    await tester.pump(const Duration(milliseconds: 260));

    final matchNext =
        find.byKey(const ValueKey<String>('on-trip-radar-match-next'));
    await tester.ensureVisible(matchNext);
    await tester.tap(matchNext);
    await tester.pump(const Duration(milliseconds: 1600));
    await _expandActiveRideSheet(tester);

    expect(find.text('Next trip secured'), findsWidgets);

    await _slideActiveRideAction(tester);
    await tester.pump(const Duration(milliseconds: 520));
    expect(find.byType(DriverRideCompleted), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pump(const Duration(milliseconds: 520));

    expect(find.byType(AcceptRide), findsOneWidget);
    expect(find.text('Heading to pickup'), findsOneWidget);
    expect(find.textContaining('Maya'), findsWidgets);
    expect(find.textContaining('Vasagatan 10'), findsWidgets);
    _expectNoException(tester);
  });

  testWidgets('Current trip waybill is directly visible in the active ride sheet', (
    WidgetTester tester,
  ) async {
    WaybillStore.reset();
    addTearDown(() {
      WaybillStore.reset();
      tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(375, 812));
    await tester.pumpWidget(
      const MaterialApp(
        home: AcceptRide(
          offerId: 'waybill-current-test',
          fare: '111,02 kr',
          category: 'Comfort',
          matchedVia: 'Movera Radar',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 160));

    final shortcut =
        find.byKey(const ValueKey<String>('current-waybill-shortcut'));
    await tester.ensureVisible(shortcut);
    expect(shortcut, findsOneWidget);

    await tester.tap(shortcut);
    await tester.pump(const Duration(milliseconds: 320));

    expect(
      find.byKey(
        const ValueKey<String>('waybill-waybill-current-test'),
      ),
      findsOneWidget,
    );
    expect(find.text('Current trip waybill'), findsOneWidget);
    expect(find.text('111,02 kr'), findsWidgets);
    _expectNoException(tester);
  });

  testWidgets('On-trip options allow safe early cancellation with reasons', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(375, 812));
    await tester.pumpWidget(const MaterialApp(home: AcceptRide()));
    await tester.pump(const Duration(milliseconds: 160));

    await _slideActiveRideAction(tester);

    await _slideActiveRideAction(tester);

    expect(find.textContaining('Dropping off'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('active-ride-trip-options')),
    );
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.text('End trip early'), findsOneWidget);
    expect(find.text('Stop safely first · reason required'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('active-ride-cancel-option')),
    );
    await tester.pump(const Duration(milliseconds: 260));

    expect(
      find.byKey(const ValueKey<String>('trip-cancellation-reasons-sheet')),
      findsOneWidget,
    );
    expect(find.text('Rider asked to end the trip'), findsOneWidget);
    expect(find.text('Safety concern'), findsOneWidget);
    expect(find.text('Vehicle problem'), findsOneWidget);
    expect(find.text('Accident or road emergency'), findsOneWidget);
    expect(find.text('Rider behavior'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const ValueKey<String>('trip-cancel-reason-rider_requested_early_end'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 260));

    expect(
      find.byKey(const ValueKey<String>('trip-cancellation-confirmation')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Only end the trip after you have stopped in a safe place and the rider can exit safely.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Keep trip'));
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.textContaining('Dropping off'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('Direct offer shows a visible expiry countdown', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    await tester.tap(find.text('OFF'));
    await tester.pump(const Duration(milliseconds: 3800));

    expect(find.text('Directly matched outside Trip Radar'), findsOneWidget);
    expect(find.textContaining('Exclusive offer · '), findsOneWidget);
    expect(find.text('Outside Radar'), findsOneWidget);
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
    expect(find.text('Directly matched outside Trip Radar'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('Home sheet exposes three snap positions', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    final panel = tester.widget<SlidingUpPanel>(find.byType(SlidingUpPanel));
    expect(panel.minHeight, 108);
    expect(panel.maxHeight, closeTo(812 * 0.90, 0.5));
    expect(panel.snapPoint, isNotNull);
    expect(panel.snapPoint!, inInclusiveRange(0.08, 0.92));
    expect(panel.panelSnapping, isFalse);
    _expectNoException(tester);
  });

  testWidgets('Active ride keeps a live navigation banner and a collapsible sheet', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(375, 812));
    await tester.pumpWidget(const MaterialApp(home: AcceptRide()));
    await tester.pump(const Duration(milliseconds: 160));

    expect(
      find.byKey(const ValueKey<String>('active-ride-navigation-card')),
      findsOneWidget,
    );
    expect(find.text('Heading to pickup'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('active-ride-primary-action')),
      findsOneWidget,
    );

    final panel = tester.widget<SlidingUpPanel>(find.byType(SlidingUpPanel));
    expect(panel.minHeight, 148);
    expect(panel.snapPoint, isNotNull);
    expect(panel.panelSnapping, isFalse);

    final banner = tester.getRect(
      find.byKey(const ValueKey<String>('active-ride-navigation-card')),
    );
    expect(banner.top, closeTo(0, 0.5));
    expect(banner.left, closeTo(0, 0.5));
    expect(banner.width, closeTo(375, 1));

    final mapControls = find.byKey(
      const ValueKey<String>('active-ride-map-controls'),
    );
    expect(mapControls, findsOneWidget);
    final openY = tester.getTopLeft(mapControls).dy;

    await _collapseActiveRideSheet(tester);
    expect(find.text('Heading to pickup'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('active-ride-primary-action')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('active-ride-compact-dock')),
      findsOneWidget,
    );
    expect(find.text('Odlarvägen 22'), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('active-ride-navigation-card')),
      findsOneWidget,
    );
    expect(tester.getTopLeft(mapControls).dy, closeTo(openY, 0.5));
    _expectNoException(tester);
  });

  testWidgets('Routing failure keeps the driver on the active trip', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 700));
    await tester.pumpWidget(
      MaterialApp(
        home: AcceptRide(routeRepository: _FailingRouteRepository()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 160));

    expect(find.byType(AcceptRide), findsOneWidget);
    expect(find.text('Heading to pickup'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('active-ride-navigation-card')),
      findsOneWidget,
    );
    _expectNoException(tester);
  });

  testWidgets('On-trip Radar orb is smaller with an accessible touch target', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(375, 812));
    await tester.pumpWidget(const MaterialApp(home: AcceptRide()));
    await tester.pump(const Duration(milliseconds: 160));

    await _slideActiveRideAction(tester);
    await _slideActiveRideAction(tester);
    await tester.pump(const Duration(milliseconds: 2400));
    await _collapseActiveRideSheet(tester);

    final radar = find.byKey(
      const ValueKey<String>('on-trip-radar-offer-button'),
    );
    expect(radar, findsOneWidget);
    expect(tester.getSize(radar), const Size(88, 88));
    expect(tester.getTopLeft(radar).dx, lessThan(40));
    _expectNoException(tester);
  });

  testWidgets('Live navigation banner shows turn-by-turn copy at the extreme top', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(375, 812));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NavigationInstructionBanner(
            banner: NavigationBanner(
              primary: 'Turn left in 300 m',
              distanceLabel: '300 m',
              roadName: 'Sveavägen',
              symbol: NavigationBannerSymbol.left,
            ),
            etaLabel: '4 min',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Turn left in 300 m'), findsOneWidget);
    expect(find.text('Sveavägen'), findsOneWidget);
    final banner = tester.getRect(
      find.byKey(const ValueKey<String>('active-ride-navigation-card')),
    );
    expect(banner.top, closeTo(0, 0.5));
    expect(banner.left, closeTo(0, 0.5));
    expect(banner.width, closeTo(375, 1));
    _expectNoException(tester);
  });
}

class _FailingRouteRepository implements RouteRepository {
  @override
  Future<RoadRoute> drivingRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  }) async {
    throw Exception('offline');
  }
}
