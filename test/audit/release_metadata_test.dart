import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release metadata is Movera Driver, not the Flutter template', () {
    final files = <String>[
      'pubspec.yaml',
      'web/index.html',
      'web/manifest.json',
      'README.md',
      'android/app/src/main/AndroidManifest.xml',
      'ios/Runner/Info.plist',
    ];
    for (final path in files) {
      final text = File(path).readAsStringSync();
      expect(text, isNot(contains('A new Flutter project')), reason: path);
    }
    expect(File('web/index.html').readAsStringSync(), contains('Movera Driver'));
    expect(File('web/manifest.json').readAsStringSync(), contains('Movera Driver'));
    expect(
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
      contains('android:label="Movera Driver"'),
    );
    expect(
      File('ios/Runner/Info.plist').readAsStringSync(),
      contains('<string>Movera Driver</string>'),
    );
    expect(
      File('android/app/build.gradle.kts').readAsStringSync(),
      contains('se.movera.driver'),
    );
  });
}
