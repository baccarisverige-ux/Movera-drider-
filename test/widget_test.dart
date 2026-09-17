import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/main.dart';
import 'package:movera/presentation/common/onboarding/onboarding.dart';
import 'package:movera/presentation/common/splash/splash.dart';

void main() {
  testWidgets('Drider app boots from splash into onboarding', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MoveraApp());
    expect(find.byType(Splash), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
