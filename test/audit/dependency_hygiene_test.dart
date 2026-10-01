import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the unused sliding panel package is not referenced', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('flutter_sliding_up_panel')));
    expect(pubspec, contains('sliding_up_panel:'));
    final hits = Directory('lib')
        .listSync(recursive: true)
        .followedBy(Directory('test').listSync(recursive: true))
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) => file.readAsStringSync().contains('flutter_sliding_up_panel'),
        )
        .map((file) => file.path)
        .toList();
    expect(hits, isEmpty);
  });
}
