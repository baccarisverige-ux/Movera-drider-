import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/main.dart';
import 'package:movera/presentation/driver/home/home.dart';
import 'package:movera/presentation/driver/my%20wallet/wallet.dart';
import 'package:movera/presentation/driver/scheduled%20rides/scheduled_rides.dart';
import 'package:movera/presentation/driver/support/support_inbox.dart';

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

Finder _visibleTooltip(String message) =>
    find.byTooltip(message).hitTestable().first;

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

        // Drag the collapsed sheet upward from its empty centre/notch lane.
        await tester.dragFrom(
          Offset(size.width / 2, size.height - 24),
          Offset(0, -(size.height * 0.62)),
        );
        await tester.pump(const Duration(milliseconds: 520));

        expect(find.text('Driver overview'), findsOneWidget);
        _expectNoException(tester);

        // Collapse it again and verify the transition stays layout-safe.
        await tester.dragFrom(
          Offset(size.width / 2, size.height * 0.30),
          Offset(0, size.height * 0.62),
        );
        await tester.pump(const Duration(milliseconds: 520));
        _expectNoException(tester);
      },
    );
  }

  testWidgets('Collapsed sheet quick actions navigate safely', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    await tester.tap(_visibleTooltip('Wallet'));
    await tester.pump(const Duration(milliseconds: 320));
    expect(find.byType(WalletScreen), findsOneWidget);
    _expectNoException(tester);
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 320));

    await tester.tap(_visibleTooltip('Inbox'));
    await tester.pump(const Duration(milliseconds: 320));
    expect(find.byType(SupportInboxScreen), findsOneWidget);
    _expectNoException(tester);
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 320));

    await tester.tap(_visibleTooltip('Scheduled'));
    await tester.pump(const Duration(milliseconds: 320));
    expect(find.byType(ScheduledRidesScreen), findsOneWidget);
    _expectNoException(tester);
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 320));

    await tester.tap(_visibleTooltip('Menu'));
    await tester.pump(const Duration(milliseconds: 320));
    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold).first);
    expect(scaffoldState.isDrawerOpen, isTrue);
    _expectNoException(tester);
  });

  testWidgets('Trip radar online and Go offline sheet flow is safe', (
    WidgetTester tester,
  ) async {
    const size = Size(375, 812);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, size);

    expect(find.text('OFFLINE'), findsOneWidget);
    await tester.tap(find.text('OFFLINE'));
    await tester.pump(const Duration(milliseconds: 1550));

    expect(find.text('SCANNING'), findsOneWidget);
    _expectNoException(tester);

    await tester.dragFrom(
      Offset(size.width / 2, size.height - 24),
      Offset(0, -(size.height * 0.62)),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final goOffline = find.text('Go offline').hitTestable();
    expect(goOffline, findsOneWidget);
    await tester.tap(goOffline);
    await tester.pump(const Duration(milliseconds: 520));

    expect(find.text('OFFLINE'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('Home safety and Today summary overlays open without layout errors', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester, const Size(375, 812));

    await tester.tap(find.byIcon(Icons.insights_rounded).hitTestable());
    await tester.pump(const Duration(milliseconds: 500));
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
