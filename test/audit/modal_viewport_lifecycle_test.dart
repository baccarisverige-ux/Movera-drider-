import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/widgets/layout_viewport.dart';
import 'package:movera/widgets/movera_modal_sheet.dart';

void main() {
  for (final fit in [false, true]) {
    Future<void> open(WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => LayoutViewport(child: child!),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  showMoveraModalSheet<void>(
                    context: context,
                    fitContent: fit,
                    builder: (_) => SizedBox(
                      key: const ValueKey('sheet-body'),
                      height: fit ? 100 : null,
                      child: const ColoredBox(color: Colors.white),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('open modal follows rotation, fitContent=$fit', (tester) async {
      await open(tester);
      tester.view.physicalSize = const Size(568, 320);
      await tester.pumpAndSettle();
      final body = find.byKey(const ValueKey('sheet-body'));
      expect(tester.getSize(body).width, 568);
      expect(tester.getSize(body).height, closeTo(fit ? 100 : 320 * .78, .01));
      expect(tester.getBottomLeft(body).dy, closeTo(320, .01));
      expect(tester.takeException(), isNull);
    });

    testWidgets('open modal keeps controls above keyboard, fitContent=$fit', (
      tester,
    ) async {
      await open(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 200);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      final body = find.byKey(const ValueKey('sheet-body'));
      expect(tester.getBottomLeft(body).dy, closeTo(368, .01));
      expect(tester.getSize(body).height, closeTo(fit ? 100 : 368 * .78, .01));
      expect(tester.takeException(), isNull);
    });
  }
}
