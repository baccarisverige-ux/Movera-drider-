import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reachable camera capture declares NSCameraUsageDescription', () {
    const cameraFiles = <String>[
      'lib/presentation/driver/add vehicle/add_vehicle.dart',
      'lib/presentation/driver/auth/additional detail/screens/vehicle_document_upload.dart',
    ];
    for (final path in cameraFiles) {
      final source = File(path).readAsStringSync();
      expect(source, contains('ImageSource.camera'), reason: path);
      expect(source, isNot(contains('ImageSource.gallery')), reason: path);
    }
    for (final name in ['vehicle_insurance', 'vehicle_registeration']) {
      final source = File(
        'lib/presentation/driver/auth/additional detail/screens/$name.dart',
      ).readAsStringSync();
      expect(source, contains("import 'vehicle_document_upload.dart';"));
      expect(source, contains('VehicleDocumentUpload('));
    }

    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('<key>NSCameraUsageDescription</key>'));
    expect(plist, contains('vehicle and document photos'));
    final value = RegExp(
      r'<key>NSCameraUsageDescription</key>\s*<string>([^<]+)</string>',
    ).firstMatch(plist);
    expect(value, isNotNull);
    expect(value!.group(1)!.trim(), isNotEmpty);
    expect(value.group(1), contains('camera'));
    expect(plist, isNot(contains('NSPhotoLibraryUsageDescription')));
  });
}
