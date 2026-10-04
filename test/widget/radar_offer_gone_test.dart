import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/dispatch/demo_dispatch_repository.dart';
import 'package:movera/core/session/driver_session_controller.dart';
import 'package:movera/presentation/driver/home/home.dart';
import 'package:movera/widgets/layout_viewport.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a Radar trip that disappears shows No longer available', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // nearby-1 is the first Radar trip on Home; here it vanishes from the
    // feed (rider cancelled, expired…) shortly after it appears.
    final dispatch = DemoDispatchRepository(
      externalClaimOfferId: 'nearby-1',
      externalClaimDelay: const Duration(milliseconds: 12500),
    );
    await tester.pumpWidget(
      LayoutViewport(
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          useInheritedMediaQuery: true,
          builder: (_, __) => MaterialApp(
            home: DriverHome(
              sessionController: DriverSessionController(),
              dispatchRepository: dispatch,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    tester
        .widget<GestureDetector>(
          find.byKey(const ValueKey<String>('trip-radar-touch-target')),
        )
        .onTap!
        .call();
    await tester.pump(const Duration(milliseconds: 1550));
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pump(const Duration(milliseconds: 8500));
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('Radar offers · 1'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('No longer available'), findsOneWidget);
    expect(find.text('Taken by another driver'), findsNothing);

    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('No longer available'), findsNothing);
    tester.takeException();
    await tester.pumpWidget(const SizedBox());
    dispatch.dispose();
  });

  testWidgets('a Radar trip not picked in time keeps its card but Match fades', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final dispatch = DemoDispatchRepository(
      externalClaimDelay: const Duration(minutes: 5),
    );
    await tester.pumpWidget(
      LayoutViewport(
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          useInheritedMediaQuery: true,
          builder: (_, __) => MaterialApp(
            home: DriverHome(
              sessionController: DriverSessionController(),
              dispatchRepository: dispatch,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    tester
        .widget<GestureDetector>(
          find.byKey(const ValueKey<String>('trip-radar-touch-target')),
        )
        .onTap!
        .call();
    await tester.pump(const Duration(milliseconds: 1550));
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pump(const Duration(milliseconds: 8500));
    await tester.pump(const Duration(milliseconds: 900));
    final match = find.byKey(const ValueKey<String>('radar-match-nearby-1'));
    expect(tester.widget<FilledButton>(match).onPressed, isNotNull);

    await tester.pump(const Duration(seconds: 31));
    await tester.pump(const Duration(milliseconds: 100));
    expect(match, findsOneWidget);
    expect(tester.widget<FilledButton>(match).onPressed, isNull);
    expect(find.text('Radar offers · 1'), findsOneWidget);
    tester.takeException();
    await tester.pumpWidget(const SizedBox());
    dispatch.dispose();
  });

  testWidgets('new Radar trips open the offers popup by themselves', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final dispatch = DemoDispatchRepository(
      externalClaimDelay: const Duration(minutes: 5),
    );
    await tester.pumpWidget(
      LayoutViewport(
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          useInheritedMediaQuery: true,
          builder: (_, __) => MaterialApp(
            home: DriverHome(
              sessionController: DriverSessionController(),
              dispatchRepository: dispatch,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    tester
        .widget<GestureDetector>(
          find.byKey(const ValueKey<String>('trip-radar-touch-target')),
        )
        .onTap!
        .call();
    await tester.pump(const Duration(milliseconds: 1550));
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pump(const Duration(milliseconds: 8500));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 6200));
    // One trip listed, more waiting: the Radar button counts every open
    // Radar trip, the same ones the full Radar screen lists.
    expect(find.text('Radar offers · 1'), findsOneWidget);
    expect(find.text('4 trips'), findsOneWidget);
    expect(find.text('New Radar trips'), findsNothing);

    // The driver hides the listed trip: the waiting ones open by themselves.
    final hide = find.byTooltip('Hide offer');
    tester
        .widget<InkWell>(
          find.descendant(of: hide, matching: find.byType(InkWell)).first,
        )
        .onTap!
        .call();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Radar offers · 2'), findsOneWidget);
    // Hiding a trip on Home does not take it off Radar: the count stays.
    expect(find.text('4 trips'), findsOneWidget);
    expect(find.text('New Radar trips'), findsNothing);
    tester.takeException();
    await tester.pumpWidget(const SizedBox());
    dispatch.dispose();
  });
}
