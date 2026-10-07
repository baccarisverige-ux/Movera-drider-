import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:circle_progress_bar/circle_progress_bar.dart';
import 'package:movera/core/session/driver_composition_guard.dart';
import 'package:movera/presentation/driver/auth/additional%20detail/navigation.dart';

void main() {
  test('028 preview is allowed and production rejects demo composition', () {
    expect(() => validateDriverComposition(production: false), returnsNormally);
    expect(() => validateDriverComposition(production: true), throwsStateError);
    expect(driverProductionRequested, false);
  });
  testWidgets('026 independent page controllers reject duplicate advances', (
    tester,
  ) async {
    final first = AdditionalInfoNavigationController();
    final second = AdditionalInfoNavigationController();
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return Column(
              children: [
                for (final controller in [first, second])
                  Expanded(
                    child: PageView(
                      controller: controller.pageController,
                      children: const [
                        Text('One'),
                        Text('Two'),
                        Text('Three'),
                        Text('Four'),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
    final advance = first.moveToNextStep(context);
    final duplicate = first.moveToNextStep(context);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await advance;
    await duplicate;
    expect(first.currentPageIndex.value, 1);
    expect(second.currentPageIndex.value, 0);
    await tester.pumpWidget(const SizedBox());
    first.onClose();
    second.onClose();
    expect(tester.takeException(), isNull);
  });
  testWidgets('026 progress indicators retain independent ticker state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => const MaterialApp(
          home: Row(
            children: [
              ProgressWidget(currentPageIndex: 0, totalPages: 4),
              ProgressWidget(currentPageIndex: 2, totalPages: 4),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final bars = tester
        .widgetList<CircleProgressBar>(find.byType(CircleProgressBar))
        .toList();
    expect(bars[0].value, .25);
    expect(bars[1].value, .75);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
