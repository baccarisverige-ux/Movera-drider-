import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/main.dart';
import 'package:movera/presentation/driver/home/home.dart';
import 'package:movera/presentation/driver/home/components/driver_sheet_nav.dart';
import 'package:movera/presentation/driver/my%20wallet/wallet.dart';
import 'package:movera/presentation/driver/scheduled%20rides/scheduled_rides.dart';
import 'package:movera/presentation/driver/support/support_inbox.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

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

  testWidgets('Trip radar online and Go offline sheet flow is safe', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    expect(find.text('OFFLINE'), findsOneWidget);
    await tester.tap(find.text('OFFLINE'));
    await tester.pump(const Duration(milliseconds: 1550));

    expect(find.text('SCANNING'), findsOneWidget);
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

    expect(find.text('OFFLINE'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('Online state survives Scheduled Rides navigation and return', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    await tester.tap(find.text('OFFLINE'));
    await tester.pump(const Duration(milliseconds: 1550));
    expect(find.text('SCANNING'), findsOneWidget);

    await _openPanel(tester);
    final scheduled = find.byTooltip('Scheduled').hitTestable();
    expect(scheduled, findsOneWidget);
    await tester.tap(scheduled);
    await _advanceAnimation(tester, const Duration(milliseconds: 420));

    expect(find.byType(ScheduledRidesScreen), findsOneWidget);
    _expectNoException(tester);

    Navigator.of(tester.element(find.byType(ScheduledRidesScreen))).pop();
    await _advanceAnimation(tester, const Duration(milliseconds: 420));

    expect(find.byType(DriverHome), findsOneWidget);
    expect(find.text('SCANNING'), findsOneWidget);
    expect(find.text('Go offline'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('Going offline cancels pending direct-offer state', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    await tester.tap(find.text('OFFLINE'));
    await tester.pump(const Duration(milliseconds: 1550));
    expect(find.text('SCANNING'), findsOneWidget);

    await _openPanel(tester);
    final goOfflineText = find.text('Go offline');
    final goOfflineButton = find.ancestor(
      of: goOfflineText,
      matching: find.byType(OutlinedButton),
    );
    final button = tester.widget<OutlinedButton>(goOfflineButton);
    button.onPressed!.call();
    await _advanceAnimation(tester, const Duration(milliseconds: 520));

    expect(find.text('OFFLINE'), findsOneWidget);

    // Advance beyond the first direct-offer timer. Nothing may appear offline.
    await tester.pump(const Duration(milliseconds: 4200));
    expect(find.text('104,80 kr'), findsNothing);
    expect(find.text('Direct request outside radar'), findsNothing);
    expect(find.text('OFFLINE'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('Direct offer timeout returns Home to scanning state', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    await tester.tap(find.text('OFFLINE'));
    await tester.pump(const Duration(milliseconds: 3800));

    expect(find.text('104,80 kr'), findsOneWidget);
    expect(find.text('SCANNING'), findsOneWidget);

    // The direct offer auto-dismisses 8.5s after it appears.
    await tester.pump(const Duration(milliseconds: 8700));

    expect(find.text('104,80 kr'), findsNothing);
    expect(find.text('Direct request outside radar'), findsNothing);
    expect(find.text('SCANNING'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('Direct Home offer can appear without sheet/layout errors', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    await tester.tap(find.text('OFFLINE'));
    await tester.pump(const Duration(milliseconds: 3800));

    expect(find.text('104,80 kr'), findsOneWidget);
    expect(find.text('Direct request outside radar'), findsOneWidget);
    _expectNoException(tester);
  });
}
