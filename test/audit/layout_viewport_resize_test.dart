import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/widgets/layout_viewport.dart';

void main() {
  for (final next in [const Size(568, 320), const Size(375, 812)]) {
    testWidgets('root surface follows viewport growth to $next', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      const surface = ValueKey('allocated-surface');
      Size? reported;
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => LayoutViewport(child: child!),
          home: Builder(
            builder: (context) {
              reported = MediaQuery.sizeOf(context);
              return const ColoredBox(
                color: Colors.white,
                child: SizedBox.expand(key: surface),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(reported, const Size(320, 568));
      expect(tester.getSize(find.byKey(surface)), const Size(320, 568));

      tester.view.physicalSize = next;
      await tester.pumpAndSettle();
      expect(reported, next);
      expect(tester.getSize(find.byKey(surface)), next);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('test surface stays aligned when view metrics differ', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const surface = ValueKey('allocated-surface');
    Size? reported;
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => LayoutViewport(child: child!),
        home: Builder(
          builder: (context) {
            reported = MediaQuery.sizeOf(context);
            return const SizedBox.expand(key: surface);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(reported, const Size(320, 568));
    expect(tester.getSize(find.byKey(surface)), const Size(320, 568));
    await tester.binding.setSurfaceSize(const Size(568, 320));
    await tester.pumpAndSettle();
    expect(reported, const Size(568, 320));
    expect(tester.getSize(find.byKey(surface)), const Size(568, 320));
    expect(tester.takeException(), isNull);
  });
}
