import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/main.dart';
import 'package:movera/presentation/driver/home/home.dart';

Future<void> _pumpHome(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(const MoveraApp());

  // ScreenUtilInit with ensureScreenSize initializes on the next frame.
  await tester.pump(const Duration(milliseconds: 120));
  expect(find.byType(DriverHome), findsOneWidget);

  final startupException = tester.takeException();
  expect(
    startupException,
    isNull,
    reason: startupException?.toString(),
  );
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

        // Drag the collapsed sheet upward from its empty centre/notch lane.
        await tester.dragFrom(
          Offset(size.width / 2, size.height - 24),
          Offset(0, -(size.height * 0.62)),
        );
        await tester.pump(const Duration(milliseconds: 520));

        expect(find.text('Driver overview'), findsOneWidget);
        final openException = tester.takeException();
        expect(openException, isNull, reason: openException?.toString());

        // Collapse it again and verify the transition stays layout-safe.
        await tester.dragFrom(
          Offset(size.width / 2, size.height * 0.30),
          Offset(0, size.height * 0.62),
        );
        await tester.pump(const Duration(milliseconds: 520));

        final closeException = tester.takeException();
        expect(closeException, isNull, reason: closeException?.toString());
      },
    );
  }
}
