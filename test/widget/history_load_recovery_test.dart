import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/history/trip_history.dart';
import 'package:movera/presentation/driver/ride history/ride_history.dart';

class _HistoryLoader {
  final reads = <Completer<List<TripHistoryRecord>>>[];

  Future<List<TripHistoryRecord>> load() {
    final result = Completer<List<TripHistoryRecord>>();
    reads.add(result);
    return result.future;
  }
}

TripHistoryRecord _ride() => TripHistoryRecord(
  tripId: 'stored-trip',
  riderName: 'Stored rider',
  whenLabel: 'Today',
  pickup: 'Stockholm',
  dropoff: 'Solna',
  fare: '128,40 kr',
  fareMinorUnits: 12840,
  category: 'Comfort',
  completedAt: DateTime.now(),
);

Future<GlobalKey<NavigatorState>> _open(
  WidgetTester tester,
  _HistoryLoader loader,
) async {
  tester.view.physicalSize = const Size(430, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      home: DriverRideHistory(loadHistory: loader.load),
    ),
  );
  await tester.pump();
  return navigator;
}

VoidCallback _retry(WidgetTester tester) => tester
    .widget<TextButton>(find.byKey(const ValueKey('history-retry')))
    .onPressed!;

void _expectNoSummary() {
  expect(find.byKey(const ValueKey('history-overview')), findsNothing);
  expect(find.text('No completed rides in this period.'), findsNothing);
  expect(find.text('Recorded fares'), findsNothing);
}

void main() {
  testWidgets('pending history load cannot display an empty earnings archive', (
    tester,
  ) async {
    final loader = _HistoryLoader();
    await _open(tester, loader);
    expect(find.text('Loading ride history…'), findsOneWidget);
    _expectNoSummary();
    loader.reads.single.complete([_ride()]);
    await tester.pumpAndSettle();
    expect(find.text('Loading ride history…'), findsNothing);
    expect(find.byKey(const ValueKey('stored-trip')), findsOneWidget);
    expect(find.text('128,40 kr'), findsWidgets);
    await tester.ensureVisible(
      find.byKey(const ValueKey('history-all-rides-button')),
    );
    await tester.tap(find.byKey(const ValueKey('history-all-rides-button')));
    await tester.pumpAndSettle();
    expect(find.text('All rides'), findsOneWidget);
    expect(find.byKey(const ValueKey('stored-trip')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history error persists and repeated Retry starts one read', (
    tester,
  ) async {
    final loader = _HistoryLoader();
    await _open(tester, loader);
    loader.reads.single.completeError(StateError('Storage unavailable'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('Could not load ride history.'), findsOneWidget);
    _expectNoSummary();
    final retry = _retry(tester);
    retry();
    retry();
    await tester.pump(const Duration(milliseconds: 350));
    expect(loader.reads, hasLength(2));
    expect(find.byKey(const ValueKey('history-retry')), findsNothing);
    expect(find.text('Loading ride history…'), findsOneWidget);
    _expectNoSummary();
    loader.reads.last.complete([_ride()]);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stored-trip')), findsOneWidget);
    expect(find.text('Could not load ride history.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed history Retry can recover to a genuine empty archive', (
    tester,
  ) async {
    final loader = _HistoryLoader();
    await _open(tester, loader);
    loader.reads.single.completeError(StateError('Storage unavailable'));
    await tester.pumpAndSettle();
    _retry(tester)();
    await tester.pump();
    loader.reads.last.completeError(StateError('Still unavailable'));
    await tester.pumpAndSettle();
    _expectNoSummary();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    _retry(tester)();
    await tester.pump();
    expect(loader.reads, hasLength(3));
    loader.reads.last.complete([]);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('history-overview')), findsOneWidget);
    expect(find.text('No completed rides in this period.'), findsOneWidget);
    expect(find.text('Could not load ride history.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'late history error does not show a snackbar on a covering route',
    (tester) async {
      final loader = _HistoryLoader();
      final navigator = await _open(tester, loader);
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Covering owner')),
        ),
      );
      // The loading screen continues animating underneath the incoming route.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      loader.reads.single.completeError(StateError('Storage unavailable'));
      await tester.pumpAndSettle();
      expect(find.text('Covering owner'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('Could not load ride history.'), findsOneWidget);
      expect(find.byKey(const ValueKey('history-retry')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('history read completion after disposal is ignored', (
    tester,
  ) async {
    for (final fail in [false, true]) {
      final loader = _HistoryLoader();
      await _open(tester, loader);
      await tester.pumpWidget(const SizedBox());
      if (fail) {
        loader.reads.single.completeError(StateError('Storage unavailable'));
      } else {
        loader.reads.single.complete([_ride()]);
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
