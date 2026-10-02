import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/vehicle/local_vehicle_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _photo(int bytes) => base64Encode(Uint8List(bytes));

Map<String, dynamic> _vehicle(String id, {String? registration, String? insurance}) => {
  'id': id,
  'make': 'Volvo',
  'model': 'XC60',
  'year': '2024',
  'plate': 'ABC 123',
  if (registration != null) 'registrationPhoto': registration,
  if (insurance != null) 'insurancePhoto': insurance,
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a new photo above the per-photo cap is refused', () async {
    final store = LocalVehicleStore();
    await expectLater(
      store.upsert(_vehicle('v1', registration: _photo(LocalVehicleStore.maxPhotoBytes + 1024))),
      throwsA(isA<VehiclePhotoBudgetExceeded>()),
    );
  });

  test('the total photo budget is enforced across vehicles', () async {
    final store = LocalVehicleStore();
    const each = 600 * 1024;
    await store.upsert(_vehicle('v1', registration: _photo(each), insurance: _photo(each)));
    await store.upsert(_vehicle('v2', registration: _photo(each)));
    await expectLater(
      store.upsert(_vehicle('v2', registration: _photo(each), insurance: _photo(each))),
      throwsA(isA<VehiclePhotoBudgetExceeded>()),
    );
    // Removing photos elsewhere frees the budget.
    await store.remove('v1');
    await store.upsert(_vehicle('v2', registration: _photo(each), insurance: _photo(each)));
    expect((await store.list()).where((row) => row['id'] == 'v2').single['insurancePhoto'], isNotNull);
  });

  test('editing text of a vehicle with existing photos is never blocked', () async {
    final store = LocalVehicleStore();
    final photo = _photo(600 * 1024);
    await store.upsert(_vehicle('v1', registration: photo, insurance: photo));
    await store.upsert({..._vehicle('v1', registration: photo, insurance: photo), 'plate': 'NEW 999'});
    expect((await store.list()).firstWhere((row) => row['id'] == 'v1')['plate'], 'NEW 999');
  });

  test('Android excludes app data from backup and device transfer', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:dataExtractionRules="@xml/data_extraction_rules"'));
    expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
    final rules = File('android/app/src/main/res/xml/data_extraction_rules.xml').readAsStringSync();
    expect(rules, contains('<cloud-backup>'));
    expect(rules, contains('<device-transfer>'));
  });

  test('PWA uses Movera colours, not the Flutter template blue', () {
    final manifest = jsonDecode(File('web/manifest.json').readAsStringSync()) as Map;
    expect(manifest['theme_color'], '#252E3A');
    expect(File('web/manifest.json').readAsStringSync(), isNot(contains('#0175C2')));
  });
}
