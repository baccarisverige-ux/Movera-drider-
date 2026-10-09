import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/presentation/driver/promotions/promotions.dart';

Future<GlobalKey<NavigatorState>> _open(
  WidgetTester tester,
  Future<void> Function(String) copy,
) async {
  tester.view.physicalSize = const Size(430, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      home: Promotions(copyCode: copy),
    ),
  );
  await tester.pumpAndSettle();
  return navigator;
}

VoidCallback _copy(WidgetTester tester) => tester
    .widget<TextButton>(find.widgetWithText(TextButton, 'PEAK80'))
    .onPressed!;

void main() {
  testWidgets(
    'copy reports success only after completion and rejects repeated taps',
    (tester) async {
      var copies = 0;
      final pending = Completer<void>();
      await _open(tester, (code) {
        expect(code, 'PEAK80');
        copies++;
        return pending.future;
      });
      final copy = _copy(tester);
      copy();
      copy();
      await tester.pumpAndSettle();
      expect(copies, 1);
      expect(find.text('Demo code PEAK80 copied'), findsNothing);
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('Demo code PEAK80 copied'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed clipboard copy has truthful feedback and can retry', (
    tester,
  ) async {
    var copies = 0;
    await _open(tester, (_) async {
      if (++copies == 1) throw StateError('Clipboard unavailable');
    });
    _copy(tester)();
    await tester.pumpAndSettle();
    expect(
      find.text('Could not copy the code. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Demo code PEAK80 copied'), findsNothing);
    _copy(tester)();
    await tester.pumpAndSettle();
    expect(copies, 2);
    // Remove the earlier error snackbar from the presentation queue.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Demo code PEAK80 copied'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final disposed in [false, true]) {
    testWidgets(
      'clipboard completion is ignored after owner is ${disposed ? 'disposed' : 'covered'}',
      (tester) async {
        final pending = Completer<void>();
        final navigator = await _open(tester, (_) => pending.future);
        final copy = _copy(tester);
        copy();
        if (disposed) {
          await tester.pumpWidget(const SizedBox());
        } else {
          navigator.currentState!.push(
            MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Covering owner')),
            ),
          );
        }
        await tester.pumpAndSettle();
        copy();
        pending.completeError(StateError('Late failure'));
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
