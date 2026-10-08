import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/session/driver_session_controller.dart';
import 'package:movera/core/session/driver_session_repository.dart';

class _Reads implements DriverSessionRepository {
  final reads = <Completer<bool?>>[];
  @override
  Future<bool?> readOnline() {
    final read = Completer<bool?>();
    reads.add(read);
    return read.future;
  }

  @override
  Future<void> saveOnline(bool value) async {}
  @override
  Future<void> clear() async {}
}

void main() {
  test('old restore failure cannot pollute explicit availability', () async {
    final repo = _Reads();
    final session = DriverSessionController(repository: repo);
    final restore = session.restore();
    session.setOnline(true);
    repo.reads.single.completeError(StateError('old read'));
    await restore;
    expect(session.availableForOffers, isTrue);
    expect(session.persistenceError, isNull);
    session.dispose();
  });
  test('newest restore owns its result and errors', () async {
    final repo = _Reads();
    final session = DriverSessionController(repository: repo);
    final old = session.restore();
    final current = session.restore();
    repo.reads.last.complete(false);
    await current;
    repo.reads.first.completeError(StateError('old read'));
    await old;
    expect(session.persistenceError, isNull);
    expect(session.isOnline, isFalse);
    session.dispose();
  });
  test('disposed session ignores a late restore failure', () async {
    final repo = _Reads();
    final session = DriverSessionController(repository: repo);
    final restore = session.restore();
    session.dispose();
    repo.reads.single.completeError(StateError('disposed read'));
    await restore;
    expect(session.persistenceError, isNull);
  });
  test('current restore failure remains observable', () async {
    final repo = _Reads();
    final session = DriverSessionController(repository: repo);
    final restore = session.restore();
    repo.reads.single.completeError(StateError('current read'));
    await restore;
    expect(session.persistenceError, isA<StateError>());
    expect(session.isOnline, isFalse);
    session.dispose();
  });
}
