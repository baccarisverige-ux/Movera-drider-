import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/vehicle/local_vehicle_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _vehicle(String id) => {
  'id': id,
  'make': 'Volvo',
  'model': id,
  'year': '2024',
  'plate': id.toUpperCase(),
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'saving primary vehicle photos preserves Profile and waybill identity',
    () async {
      final store = LocalVehicleStore();
      await store.upsert(_vehicle('second'));
      final before = await store.primaryIdentity();
      final primary = (await store.list()).first;
      await LocalVehicleStore().upsert({
        ...primary,
        'registrationPhoto': 'AQID',
      });
      final restored = LocalVehicleStore();
      expect(await restored.primaryIdentity(), before);
      final rows = await restored.list();
      expect(rows.map((r) => r['id']), [
        LocalVehicleStore.demo['id'],
        'second',
      ]);
      expect(rows.first['registrationPhoto'], 'AQID');
      expect(rows.last['plate'], 'SECOND');
    },
  );

  test(
    'updating a secondary vehicle preserves its position and other rows',
    () async {
      final store = LocalVehicleStore();
      await store.upsert(_vehicle('second'));
      await store.upsert(_vehicle('third'));
      await store.upsert({
        ..._vehicle('second'),
        'model': 'XC60',
        'insurancePhoto': 'AQID',
      });
      final rows = await LocalVehicleStore().list();
      expect(rows.map((r) => r['id']), [
        LocalVehicleStore.demo['id'],
        'second',
        'third',
      ]);
      expect(rows[1]['model'], 'XC60');
      expect(rows[1]['insurancePhoto'], 'AQID');
      expect(rows[2]['model'], 'third');
      expect(await store.primaryIdentity(), (
        vehicle: 'Mercedes-Benz E 220',
        plate: 'MVR 418',
      ));
    },
  );
}
