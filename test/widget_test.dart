import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/main.dart';
import 'package:movera/presentation/driver/home/home.dart';

void main() {
  testWidgets('Drider app boots directly into the map home', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MoveraApp());

    // ScreenUtilInit with ensureScreenSize initializes on the next frame.
    // Give the app one short frame before asserting the real startup screen.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(DriverHome), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
