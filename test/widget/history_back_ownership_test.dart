import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/presentation/driver/ride history/ride_history.dart';

Future<GlobalKey<NavigatorState>> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      home: const Scaffold(body: Text('Root owner')),
    ),
  );
  navigator.currentState!.push(
    MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('Caller owner')),
    ),
  );
  await tester.pumpAndSettle();
  navigator.currentState!.push(
    MaterialPageRoute<void>(
      builder: (_) => DriverRideHistory(loadHistory: () async => []),
    ),
  );
  await tester.pumpAndSettle();
  return navigator;
}

VoidCallback _back(WidgetTester tester) => tester
    .widget<IconButton>(
      find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Back',
      ),
    )
    .onPressed!;

VoidCallback _allRides(WidgetTester tester) => tester
    .widget<TextButton>(find.byKey(const ValueKey('history-all-rides-button')))
    .onPressed!;

Future<void> _showList(WidgetTester tester) async {
  await tester.ensureVisible(
    find.byKey(const ValueKey('history-all-rides-button')),
  );
  await tester.tap(find.byKey(const ValueKey('history-all-rides-button')));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('history-all-rides')), findsOneWidget);
}

void main() {
  testWidgets('system Back returns from all rides to overview before exiting', (
    tester,
  ) async {
    final navigator = await _open(tester);
    await _showList(tester);
    expect(await navigator.currentState!.maybePop(), isTrue);
    // A second request before PopScope rebuilds must not close the page.
    expect(await navigator.currentState!.maybePop(), isTrue);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('history-overview')), findsOneWidget);
    expect(find.byType(DriverRideHistory), findsOneWidget);
    expect(await navigator.currentState!.maybePop(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Caller owner'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid header Back preserves overview and then caller route', (
    tester,
  ) async {
    await _open(tester);
    await _showList(tester);
    final overview = _back(tester);
    overview();
    overview();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('history-overview')), findsOneWidget);
    final close = _back(tester);
    close();
    close();
    await tester.pumpAndSettle();
    expect(find.text('Caller owner'), findsOneWidget);
    expect(find.byType(DriverRideHistory), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'covered history callbacks cannot change the view or pop its cover',
    (tester) async {
      final navigator = await _open(tester);
      final close = _back(tester);
      await _showList(tester);
      final overview = _back(tester);
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Covering owner')),
        ),
      );
      await tester.pumpAndSettle();
      overview();
      close();
      await tester.pumpAndSettle();
      expect(find.text('Covering owner'), findsOneWidget);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('history-all-rides')), findsOneWidget);
      // A callback captured from overview cannot exit the later list view.
      close();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('history-all-rides')), findsOneWidget);
      overview();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('history-overview')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('disposed history ignores captured navigation callbacks', (
    tester,
  ) async {
    await _open(tester);
    final close = _back(tester);
    final allRides = _allRides(tester);
    await tester.pumpWidget(const SizedBox());
    close();
    allRides();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
