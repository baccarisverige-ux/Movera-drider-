import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/vehicle/local_vehicle_store.dart';
import 'package:movera/presentation/driver/add vehicle/add_vehicle.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DelayedStore extends LocalVehicleStore {
  final writes = <Map<String, dynamic>>[];
  final pending = <Completer<void>>[];

  @override
  Future<void> upsert(Map<String, dynamic> vehicle) {
    writes.add(Map.of(vehicle));
    final done = Completer<void>();
    pending.add(done);
    return done.future;
  }

  @override
  Future<List<Map<String, dynamic>>> list() async => writes;
}

Future<void> _fill(WidgetTester tester, _DelayedStore store) async {
  await tester.pumpWidget(MaterialApp(home: AddVehicle(store: store)));
  await tester.enterText(find.byType(TextField).first, 'Mercedes');
  await tester.pump();
  await tester.enterText(find.byType(TextField).at(1), 'E220');
  await tester.pump();
  final yearSelector = find.byWidgetPredicate(
    (widget) => widget is InkWell && widget.child is InputDecorator,
  );
  await tester.ensureVisible(yearSelector);
  await tester.tap(yearSelector);
  await tester.pumpAndSettle();
  await tester.tap(find.text(DateTime.now().year.toString()));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byType(TextField).at(2));
  await tester.enterText(find.byType(TextField).at(2), 'ABC123');
  await tester.pump();
}

FilledButton _continue(WidgetTester tester) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('document handoff uses the exact submitted snapshot', (
    tester,
  ) async {
    final store = _DelayedStore();
    await _fill(tester, store);
    _continue(tester).onPressed!();
    await tester.pump();
    // Simulate edits arriving while the acknowledged storage write is delayed.
    tester.widget<TextField>(find.byType(TextField).first).controller!.text =
        'Volvo';
    tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text =
        'XC90';
    tester.widget<TextField>(find.byType(TextField).at(2)).controller!.text =
        'NEW999';
    await tester.pump();
    store.pending.single.complete();
    await tester.pumpAndSettle();
    final documents = tester.widget<VehicleDocuments>(
      find.byType(VehicleDocuments),
    );
    expect(documents.make, store.writes.single['make']);
    expect(documents.model, store.writes.single['model']);
    expect(documents.plate, store.writes.single['plate']);
    expect(documents.year, store.writes.single['year']);
    expect(documents.vehicleId, store.writes.single['id']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a repeated callback before rebuild submits only once', (
    tester,
  ) async {
    final store = _DelayedStore();
    await _fill(tester, store);
    final submit = _continue(tester).onPressed!;
    submit();
    submit();
    expect(store.writes, hasLength(1));
    await tester.pump();
    expect(_continue(tester).onPressed, isNull);
    store.pending.single.complete();
    await tester.pumpAndSettle();
    expect(find.byType(VehicleDocuments), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed save stays on form and a retry can succeed', (
    tester,
  ) async {
    final store = _DelayedStore();
    await _fill(tester, store);
    _continue(tester).onPressed!();
    store.pending.single.completeError(StateError('write failed'));
    await tester.pumpAndSettle();
    expect(find.byType(VehicleDocuments), findsNothing);
    expect(
      find.text('Could not save local vehicle draft. Retry.'),
      findsOneWidget,
    );
    expect(_continue(tester).onPressed, isNotNull);
    _continue(tester).onPressed!();
    expect(store.writes, hasLength(2));
    store.pending.last.complete();
    await tester.pumpAndSettle();
    expect(find.byType(VehicleDocuments), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'late save after disposal does not navigate or read controllers',
    (tester) async {
      final store = _DelayedStore();
      await _fill(tester, store);
      _continue(tester).onPressed!();
      await tester.pumpWidget(const SizedBox());
      store.pending.single.complete();
      await tester.pumpAndSettle();
      expect(find.byType(VehicleDocuments), findsNothing);
      expect(store.writes, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );
}
