import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reachable camera flows require an iOS camera usage description', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('NSCameraUsageDescription'));
    expect(plist, contains('vehicle and document photos'));
    final sources = [
      File('lib/presentation/driver/add vehicle/add_vehicle.dart'),
    ];
    final usesCamera = sources.any((file) => file.existsSync() && file.readAsStringSync().contains('ImageSource.camera'));
    expect(usesCamera, isTrue);
  });
}
