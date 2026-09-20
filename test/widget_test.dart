import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/main.dart';
import 'package:movera/presentation/driver/home/home.dart';
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

void _invokeSheetAction(WidgetTester tester, String tooltip) {
  final visibleTooltip = find.byTooltip(tooltip).hitTestable().first;
  final action = find.descendant(
    of: visibleTooltip,
    matching: find.byType(InkWell),
  );
  expect(action, findsOneWidget);

  final inkWell = tester.widget<InkWell>(action);
  expect(inkWell.onTap, isNotNull);
  inkWell.onTap!.call();
}

Future<void> _openPanel(WidgetTester tester) async {
  final panel = tester.widget<SlidingUpPanel>(find.byType(SlidingUpPanel));
  panel.controller!.open();
  await tester.pump(const Duration(milliseconds: 520));
}

Future<void> _closePanel(WidgetTester tester) async {
  final panel = tester.widget<SlidingUpPanel>(find.byType(SlidingUpPanel));
  panel.controller!.close();
  await tester.pump(const Duration(milliseconds: 520));
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

  testWidgets('Collapsed sheet quick actions are wired safely', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    _invokeSheetAction(tester, 'Wallet');
    await tester.pump(const Duration(milliseconds: 320));
    expect(find.byType(WalletScreen), findsOneWidget);
    _expectNoException(tester);
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 320));

    _invokeSheetAction(tester, 'Inbox');
    await tester.pump(const Duration(milliseconds: 320));
    expect(find.byType(SupportInboxScreen), findsOneWidget);
    _expectNoException(tester);
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 320));

    _invokeSheetAction(tester, 'Scheduled');
    await tester.pump(const Duration(milliseconds: 320));
    expect(find.byType(ScheduledRidesScreen), findsOneWidget);
    _expectNoException(tester);
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 320));

    _invokeSheetAction(tester, 'Menu');
    await tester.pump(const Duration(milliseconds: 320));
    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold).first);
    expect(scaffoldState.isDrawerOpen, isTrue);
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
    final goOffline = find.text('Go offline').hitTestable();
    expect(goOffline, findsOneWidget);
    await tester.tap(goOffline);
    await tester.pump(const Duration(milliseconds: 520));

    expect(find.text('OFFLINE'), findsOneWidget);
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
