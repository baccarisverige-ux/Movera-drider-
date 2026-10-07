import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/history/prefs_trip_history_repository.dart';
import 'package:movera/core/privacy/local_data.dart';
import 'package:movera/core/ride/prefs_active_ride_repository.dart';
import 'package:movera/core/ride/active_ride_repository.dart';
import 'package:movera/core/ride/completion_journal.dart';
import 'package:movera/core/settings/settings_repository.dart';
import 'package:movera/core/storage/local_quarantine.dart';
import 'package:movera/core/support/local_support_repository.dart';
import 'package:movera/core/waybill/waybill.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

WaybillRecord receipt() => WaybillRecord(
  tripId: 'new',
  statusLabel: 'Completed',
  issuedAt: DateTime(2026),
  fare: '10 kr',
  service: 'Demo',
  riderName: 'R',
  pickup: 'P',
  dropoff: 'D',
  source: 'Demo',
  driverName: 'Driver',
  vehicle: 'Car',
  licensePlate: 'ABC',
  passengerCapacity: 4,
);
Map<String, Object> row(String id) => {
  'tripId': id,
  'riderName': 'R',
  'whenLabel': 'Today',
  'pickup': 'P',
  'dropoff': 'D',
  'fare': '10 kr',
  'category': 'Demo',
};

class RemoveFault extends SharedPreferencesStorePlatform {
  bool fail = true;
  @override
  Future<Map<String, Object>> getAll() async => {};
  @override
  Future<bool> setValue(String type, String key, Object value) async => true;
  @override
  Future<bool> remove(String key) async => !fail;
  @override
  Future<bool> clear() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('003 every optional field and enum is validated per receipt', () async {
    final prefs = await SharedPreferences.getInstance();
    final rows = [
      row('good'),
      {...row('enum'), 'status': 'unknown'},
      {...row('money'), 'fareMinorUnits': '10'},
      {...row('distance'), 'distance': 7},
      {...row('date'), 'completedAt': 'invalid'},
      row('good'),
    ];
    final raw = jsonEncode(rows);
    await prefs.setString(PrefsTripHistoryRepository.key, raw);
    final repo = PrefsTripHistoryRepository();
    expect((await repo.list()).map((r) => r.tripId), ['good']);
    await repo.list();
    expect(LocalQuarantine.keys(prefs), hasLength(1));
    expect(
      (jsonDecode(prefs.getString(LocalQuarantine.keys(prefs).single)!)
          as Map)['raw'],
      raw,
    );
  });
  test('004 corrupt blob remains recoverable after archive', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsTripHistoryRepository.key, '{broken');
    final repo = PrefsTripHistoryRepository();
    expect(await repo.list(), isEmpty);
    await repo.archive(receipt());
    expect((await repo.list()).single.tripId, 'new');
    expect(LocalQuarantine.keys(prefs), hasLength(1));
    expect(
      (jsonDecode(prefs.getString(LocalQuarantine.keys(prefs).single)!)
          as Map)['raw'],
      '{broken',
    );
  });
  test('004 future schema is preserved and cannot be overwritten', () async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode({
      'schemaVersion': 999,
      'rows': [row('future')],
    });
    await prefs.setString(PrefsTripHistoryRepository.key, raw);
    await expectLater(
      PrefsTripHistoryRepository().archive(receipt()),
      throwsStateError,
    );
    expect(prefs.getString(PrefsTripHistoryRepository.key), raw);
  });
  for (final raw in [
    '{broken',
    '{"schemaVersion":999}',
    '{"schemaVersion":1,"draft":{"subject":42}}',
    '{"schemaVersion":1,"tickets":[{"messages":"wrong"}]}',
  ]) {
    test(
      '005 unreadable support reports recovery and preserves original: $raw',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(LocalSupportRepository.key, raw);
        final repo = LocalSupportRepository();
        await expectLater(repo.read(), throwsA(isA<SupportDataUnreadable>()));
        await expectLater(
          repo.update('draft', {'subject': 'new'}),
          throwsA(isA<SupportDataUnreadable>()),
        );
        expect(prefs.getString(LocalSupportRepository.key), raw);
        expect(LocalQuarantine.keys(prefs), hasLength(1));
        await repo.recover();
        await repo.update('draft', {'subject': 'new'});
        expect((await repo.read())['draft'], {'subject': 'new'});
      },
    );
  }
  test('006 failed cleanup is reported and retry can succeed', () async {
    final original = SharedPreferencesStorePlatform.instance;
    final faulty = RemoveFault();
    SharedPreferencesStorePlatform.instance = faulty;
    addTearDown(() => SharedPreferencesStorePlatform.instance = original);
    await expectLater(clearLocalUserData(), throwsStateError);
    faulty.fail = false;
    await clearLocalUserData();
  });
  for (final history in [false, true]) {
    test(
      '007 pending ${history ? 'history' : 'support'} write cannot resurrect cleared data',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final entered = Completer<void>();
        final release = Completer<SharedPreferences>();
        Future<SharedPreferences> load() {
          if (!entered.isCompleted) entered.complete();
          return release.future;
        }

        final historyRepo = PrefsTripHistoryRepository(load: load);
        final supportRepo = LocalSupportRepository(load: load);
        final pending = history
            ? historyRepo.archive(receipt())
            : supportRepo.update('draft', {'subject': 'old'});
        final rejected = expectLater(pending, throwsStateError);
        await entered.future;
        final cleanup = clearLocalUserData();
        release.complete(prefs);
        await rejected;
        await cleanup;
        expect(prefs.getString(PrefsTripHistoryRepository.key), isNull);
        expect(prefs.getString(LocalSupportRepository.key), isNull);
        await expectLater(historyRepo.archive(receipt()), throwsStateError);
        await expectLater(
          supportRepo.update('draft', {'subject': 'late'}),
          throwsStateError,
        );
        await LocalSupportRepository().update('draft', {
          'subject': 'new session',
        });
      },
    );
  }
  test('007 old settings instance cannot write after logout', () async {
    final old = SettingsRepository();
    await clearLocalUserData();
    await expectLater(old.save('contacts', {'rows': []}), throwsStateError);
    await SettingsRepository().save('contacts', {'rows': []});
  });
  test('007 pending settings recovery is fenced before cleanup', () async {
    final prefs = await SharedPreferences.getInstance();
    final entered = Completer<void>();
    final release = Completer<SharedPreferences>();
    final repo = SettingsRepository(
      load: () {
        entered.complete();
        return release.future;
      },
    );
    final read = repo.read('contacts');
    final rejected = expectLater(read, throwsStateError);
    await entered.future;
    final cleanup = clearLocalUserData();
    release.complete(prefs);
    await rejected;
    await cleanup;
    expect(LocalQuarantine.keys(prefs), isEmpty);
  });
  test(
    '007 old active-trip and completion owners cannot revive logout data',
    () async {
      final active = PrefsActiveRideRepository();
      final journal = CompletionJournal(active: active);
      await clearLocalUserData();
      await expectLater(
        active.save(
          const PersistedActiveRide(
            tripId: 'old',
            stage: ActiveRideStage.onTrip,
          ),
        ),
        throwsStateError,
      );
      await expectLater(journal.finish(receipt()), throwsStateError);
      final fresh = PrefsActiveRideRepository();
      await fresh.save(
        const PersistedActiveRide(
          tripId: 'new',
          stage: ActiveRideStage.headingToPickup,
        ),
      );
      expect((await fresh.read())?.tripId, 'new');
    },
  );
}
