import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movera/widgets/owned_route_exit.dart';
import 'package:movera/presentation/driver/analytics/analytics.dart';
import 'package:movera/presentation/driver/documents/documents.dart';
import 'package:movera/presentation/driver/driving%20logs/driving_logs.dart';
import 'package:movera/presentation/driver/my%20bank/my_bank.dart';
import 'package:movera/presentation/driver/pin%20verification/pin_verification.dart';
import 'package:movera/presentation/driver/preferences/preferences.dart';
import 'package:movera/presentation/driver/promotions/promotions.dart';
import 'package:movera/presentation/driver/settings/settings.dart';
import 'package:movera/presentation/driver/settings/accessibility/accessibility.dart';
import 'package:movera/presentation/driver/settings/sound%20&%20voice/sound_voice.dart';
import 'package:movera/presentation/driver/vehicles/vehicles.dart';

Future<GlobalKey<NavigatorState>> _root(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(
        navigatorKey: navigator,
        home: const Scaffold(body: Text('Root owner')),
      ),
    ),
  );
  navigator.currentState!.push(
    MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('Caller owner')),
    ),
  );
  await tester.pumpAndSettle();
  return navigator;
}

VoidCallback _back(WidgetTester tester) => tester
    .widget<IconButton>(
      find.byWidgetPredicate((w) => w is IconButton && w.tooltip == 'Back'),
    )
    .onPressed!;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final screens = <String, Widget>{
    'analytics': const Analytics(),
    'documents': const DriverDocuments(),
    'driving logs': const DrivingLogs(),
    'bank': const MyBank(),
    'pin': const PinVerification(),
    'preferences': const Preferences(),
    'promotions': const Promotions(),
    'settings': const Settings(),
    'accessibility': const Accessibility(),
    'sound': const SoundAndVoice(),
    'vehicles': const DriverVehicles(),
  };
  for (final screen in screens.entries) {
    testWidgets('E01 ${screen.key} covered Back preserves the covering route', (
      tester,
    ) async {
      final navigator = await _root(tester);
      navigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => screen.value),
      );
      await tester.pumpAndSettle();
      final back = _back(tester);
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Cover owner')),
        ),
      );
      await tester.pumpAndSettle();
      back();
      await tester.pumpAndSettle();
      expect(find.text('Cover owner'), findsOneWidget);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      back();
      await tester.pumpAndSettle();
      expect(find.text('Caller owner'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'E01 ${screen.key} repeated and disposed Back preserves its caller',
      (tester) async {
        final navigator = await _root(tester);
        navigator.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => screen.value),
        );
        await tester.pumpAndSettle();
        final back = _back(tester);
        back();
        back();
        await tester.pumpAndSettle();
        expect(find.text('Caller owner'), findsOneWidget);
        back();
        await tester.pumpAndSettle();
        expect(find.text('Caller owner'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'E01 owned maybePop honors PopScope and returns the route result',
    (tester) async {
      final navigator = await _root(tester);
      final canPop = ValueNotifier<bool>(false);
      addTearDown(canPop.dispose);
      late BuildContext owner;
      final result = navigator.currentState!.push<String>(
        MaterialPageRoute<String>(
          builder: (_) => ValueListenableBuilder<bool>(
            valueListenable: canPop,
            builder: (_, allowed, __) => PopScope(
              canPop: allowed,
              child: Builder(
                builder: (context) {
                  owner = context;
                  return const Scaffold(body: Text('Protected owner'));
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await maybePopOwned(owner, 'saved');
      await tester.pumpAndSettle();
      expect(find.text('Protected owner'), findsOneWidget);
      canPop.value = true;
      await tester.pump();
      await maybePopOwned(owner, 'saved');
      await tester.pumpAndSettle();
      expect(await result, 'saved');
      expect(find.text('Caller owner'), findsOneWidget);
    },
  );
}
