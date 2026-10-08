import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/vehicle/local_vehicle_store.dart';
import 'package:movera/presentation/driver/add vehicle/add_vehicle.dart';

class _ControlledStore extends LocalVehicleStore {
  final restore = Completer<List<Map<String, dynamic>>>();
  final removal = Completer<void>();
  int removes = 0;

  @override
  Future<List<Map<String, dynamic>>> list() => restore.future;

  @override
  Future<void> remove(String id) {
    removes++;
    return removal.future;
  }
}

const _draft = <String, dynamic>{
  'id': 'test',
  'make': 'Mercedes',
  'model': 'E220',
  'year': '2022',
  'plate': 'ABC123',
};

Finder get _removeButton =>
    find.widgetWithText(TextButton, 'Remove vehicle', skipOffstage: false);

Future<void> _open(WidgetTester tester, _ControlledStore store) async {
  await tester.pumpWidget(
    MaterialApp(
      home: VehicleDocuments(
        vehicleId: 'test',
        make: 'Mercedes',
        model: 'E220',
        year: '2022',
        plate: 'ABC123',
        store: store,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _tapRemove(WidgetTester tester) async {
  final button = find.text('Remove vehicle').first;
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('document removal is disabled during restore', (tester) async {
    final store = _ControlledStore();
    await _open(tester, store);
    final button = tester.widget<TextButton>(_removeButton);
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    store.restore.complete([Map.of(_draft)]);
    await tester.pumpAndSettle();
    expect(tester.widget<TextButton>(_removeButton).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed restore is visible and cannot remove a draft', (
    tester,
  ) async {
    final store = _ControlledStore();
    await _open(tester, store);
    store.restore.completeError(StateError('storage unavailable'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextButton>(_removeButton).onPressed, isNull);
    expect(find.text('Retry'), findsOneWidget);
    expect(store.removes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing restored draft disables destructive action', (
    tester,
  ) async {
    final store = _ControlledStore();
    await _open(tester, store);
    store.restore.complete([]);
    await tester.pumpAndSettle();
    expect(tester.widget<TextButton>(_removeButton).onPressed, isNull);
    expect(
      find.text('This local vehicle draft is no longer available.'),
      findsOneWidget,
    );
  });

  testWidgets('removal confirmation owns all document actions', (tester) async {
    final store = _ControlledStore();
    store.restore.complete([Map.of(_draft)]);
    await _open(tester, store);
    await tester.pumpAndSettle();
    await _tapRemove(tester);
    expect(tester.widget<TextButton>(_removeButton).onPressed, isNull);
    await tester.tap(find.text('Keep vehicle'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextButton>(_removeButton).onPressed, isNotNull);
    expect(store.removes, 0);
  });

  testWidgets(
    'pending removal remains single-flight until failure then retries',
    (tester) async {
      final store = _ControlledStore();
      store.restore.complete([Map.of(_draft)]);
      await _open(tester, store);
      await tester.pumpAndSettle();
      await _tapRemove(tester);
      await tester.tap(find.text('Remove vehicle').last);
      await tester.pumpAndSettle();
      expect(store.removes, 1);
      expect(tester.widget<TextButton>(_removeButton).onPressed, isNull);
      store.removal.completeError(StateError('write failed'));
      await tester.pumpAndSettle();
      expect(find.text('Could not remove local draft. Retry.'), findsOneWidget);
      expect(tester.widget<TextButton>(_removeButton).onPressed, isNotNull);
      await _tapRemove(tester);
      expect(find.text('Keep vehicle'), findsOneWidget);
      await tester.tap(find.text('Keep vehicle'));
      await tester.pumpAndSettle();
      expect(store.removes, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('open photo route retains ownership until it returns', (
    tester,
  ) async {
    final store = _ControlledStore();
    store.restore.complete([Map.of(_draft)]);
    await _open(tester, store);
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('Vehicle Registration Certificate (Front Page)'),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<TextButton>(_removeButton).onPressed, isNull);
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.pop();
    await tester.pumpAndSettle();
    expect(tester.widget<TextButton>(_removeButton).onPressed, isNotNull);
    expect(store.removes, 0);
    expect(tester.takeException(), isNull);
  });
}
