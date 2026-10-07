import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/presentation/driver/accept%20ride/island_morph.dart';

Widget surface(Size size, String face, {bool reduced = false}) => MaterialApp(
  home: Align(
    alignment: Alignment.topCenter,
    child: IslandMorph(
      size: size,
      face: face,
      reducedMotion: reduced,
      child: Center(child: Text(face, key: ValueKey(face))),
    ),
  ),
);

Size shell(WidgetTester tester) =>
    tester.getSize(find.byKey(const ValueKey('island-morph-shell')));

void main() {
  testWidgets('Width and height morph progressively, retarget without a jump', (
    tester,
  ) async {
    await tester.pumpWidget(surface(const Size(220, 70), 'waiting'));
    await tester.pumpWidget(surface(const Size(340, 150), 'guidance'));
    expect(shell(tester), const Size(220, 70));
    await tester.pump(const Duration(milliseconds: 100));
    final intermediate = shell(tester);
    expect(intermediate.width, greaterThan(220));
    expect(intermediate.width, lessThan(340));
    expect(intermediate.height, greaterThan(70));
    expect(intermediate.height, lessThan(150));
    await tester.pumpWidget(surface(const Size(260, 80), 'arrival'));
    expect(shell(tester).width, closeTo(intermediate.width, .01));
    expect(shell(tester).height, closeTo(intermediate.height, .01));
    await tester.pump(const Duration(seconds: 1));
    expect(shell(tester).width, closeTo(260, .1));
    expect(shell(tester).height, closeTo(80, .1));
    expect(find.text('guidance'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Same face updates do not restart an active size morph', (
    tester,
  ) async {
    await tester.pumpWidget(surface(const Size(220, 70), 'waiting'));
    await tester.pumpWidget(surface(const Size(340, 150), 'guidance'));
    await tester.pump(const Duration(milliseconds: 150));
    final intermediate = shell(tester);
    await tester.pumpWidget(surface(const Size(340, 150), 'guidance'));
    expect(shell(tester), intermediate);
    await tester.pump(const Duration(milliseconds: 100));
    expect(shell(tester).width, greaterThan(intermediate.width));
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduced motion resolves size directly and removes old content', (
    tester,
  ) async {
    await tester.pumpWidget(surface(const Size(220, 70), 'waiting'));
    await tester.pumpWidget(
      surface(const Size(340, 150), 'guidance', reduced: true),
    );
    expect(shell(tester), const Size(340, 150));
    expect(find.text('waiting'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
