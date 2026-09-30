import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movera/core/settings/settings_repository.dart';
void main() { test('settings sections persist without overwriting one another', () async {
 SharedPreferences.setMockInitialValues({});final repo=SettingsRepository();
 await Future.wait([repo.save('categories',{'selected':[true,false]}),repo.save('sound',{'generalVolume':.7}),repo.save('accessibility',{'flash':true})]);
 final fresh=SettingsRepository();expect((await fresh.read('sound'))['generalVolume'],.7);
 expect((await fresh.read('categories'))['selected'],[true,false]);expect((await fresh.read('accessibility'))['flash'],true);
 }); }
