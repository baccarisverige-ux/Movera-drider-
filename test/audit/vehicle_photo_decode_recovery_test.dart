import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/vehicle/local_vehicle_store.dart';
import 'package:movera/presentation/driver/add vehicle/add_vehicle.dart';

class _BrokenPhotoStore extends LocalVehicleStore {
  @override
  Future<List<Map<String, dynamic>>> list() async => [
    {
      'id': 'broken',
      'make': 'Mercedes',
      'model': 'E220',
      'year': '2022',
      'plate': 'ABC123',
      'registrationPhoto': 'AQID',
      'insurancePhoto': 'AQID',
    },
  ];
}

void main() {
  testWidgets(
    'corrupt encoded photo has recoverable preview instead of framework error',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VehicleDocuments(
            vehicleId: 'broken',
            make: 'Mercedes',
            model: 'E220',
            year: '2022',
            plate: 'ABC123',
            store: _BrokenPhotoStore(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Saved photo cannot be displayed. Retake this document photo.',
        ),
        findsNWidgets(2),
      );
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Remove vehicle'),
            )
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
