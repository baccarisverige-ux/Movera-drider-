import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movera/widgets/layout_viewport.dart';
import 'package:movera/presentation/driver/my%20wallet/wallet.dart';
import 'package:movera/presentation/driver/earning%20stats/earning_stats.dart';
import 'package:movera/presentation/driver/promotions/promotions.dart';
import 'package:movera/presentation/driver/safety%20toolkits/safety_toolkits.dart';
import 'package:movera/presentation/driver/analytics/acceptance%20rate/acceptance_rate.dart';
import 'package:movera/presentation/driver/analytics/cancelation%20rate/cancelation_rate.dart';
import 'package:movera/presentation/driver/add%20vehicle/add_vehicle.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final screens = <String, Widget>{
    'WalletScreen': const WalletScreen(),
    'EarningStatsScreen': const EarningStatsScreen(),
    'Promotions': const Promotions(),
    'SafetyToolKits': const SafetyToolKits(),
    'AcceptanceRate': const AcceptanceRate(),
    'CancelationRate': const CancelationRate(),
    'AddVehicle': const AddVehicle(),
  };
  for (final size in [
    const Size(320, 568),
    const Size(568, 320),
    const Size(768, 1024),
  ]) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} large text and route return at $size', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final nav = GlobalKey<NavigatorState>();
        final previous = FlutterError.onError;
        FlutterError.onError = (details) {
          FlutterError.dumpErrorToConsole(details, forceReport: true);
          previous?.call(details);
        };
        addTearDown(() => FlutterError.onError = previous);
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, __) => MaterialApp(
              navigatorKey: nav,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(2)),
                child: LayoutViewport(child: child!),
              ),
              home: const Scaffold(body: Text('Route root')),
            ),
          ),
        );
        nav.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => entry.value),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${entry.key} $size');
        nav.currentState!.pop();
        await tester.pumpAndSettle();
        expect(find.text('Route root'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
