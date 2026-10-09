import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/widgets/color_picker.dart';

Future<GlobalKey<NavigatorState>> _open(
  WidgetTester tester,
  Size size,
  ValueChanged<String> selected,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => ColorPickerDialog.show(context, selected),
              child: const Text('Colors'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Colors'));
  await tester.pumpAndSettle();
  return navigator;
}

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(568, 320),
    const Size(375, 812),
  ]) {
    testWidgets(
      'color picker at 200% text fits $size and final color is reachable',
      (tester) async {
        String? selected;
        await _open(tester, size, (color) => selected = color);
        expect(tester.takeException(), isNull);
        final pink = find.byKey(const ValueKey('vehicle-color-Pink'));
        await tester.scrollUntilVisible(
          pink,
          120,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(pink);
        await tester.pumpAndSettle();
        expect(selected, 'Pink');
        expect(find.text('Choose vehicle color'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'double selection returns once and cannot close a route opened by its callback',
    (tester) async {
      var selections = 0;
      late GlobalKey<NavigatorState> navigator;
      navigator = await _open(tester, const Size(430, 1000), (_) {
        selections++;
        navigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('New owner')),
          ),
        );
      });
      final select = tester
          .widget<TextButton>(find.byKey(const ValueKey('vehicle-color-Red')))
          .onPressed!;
      select();
      select();
      await tester.pumpAndSettle();
      expect(selections, 1);
      expect(find.text('New owner'), findsOneWidget);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('Colors'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('repeated opening and cancellation preserve the caller', (
    tester,
  ) async {
    var selections = 0;
    await _open(tester, const Size(430, 1000), (_) => selections++);
    final close = tester
        .widget<IconButton>(find.byTooltip('Close color picker'))
        .onPressed!;
    close();
    close();
    await tester.pumpAndSettle();
    expect(selections, 0);
    expect(find.text('Colors'), findsOneWidget);
    final open = tester
        .widget<TextButton>(find.widgetWithText(TextButton, 'Colors'))
        .onPressed!;
    open();
    open();
    await tester.pumpAndSettle();
    expect(find.text('Choose vehicle color'), findsOneWidget);
    await tester.tap(find.byTooltip('Close color picker'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
