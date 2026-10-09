import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/presentation/driver/destination mode/destination_picker.dart';

void main() {
  testWidgets(
    'rapid destination selection returns once and preserves caller route',
    (tester) async {
      DriverDestinationResult? selected;
      var returns = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        body: Builder(
                          builder: (pickerContext) => TextButton(
                            onPressed: () async {
                              selected = await DriverDestinationPicker.open(
                                pickerContext,
                              );
                              returns++;
                            },
                            child: const Text('Choose destination'),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Open caller'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open caller'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose destination'));
      await tester.pumpAndSettle();
      final row = find.ancestor(
        of: find.text('Stockholm Central'),
        matching: find.byType(InkWell),
      );
      final callback = tester.widget<InkWell>(row).onTap!;
      callback();
      callback();
      await tester.pumpAndSettle();
      expect(returns, 1);
      expect(selected!.address, 'Centralplan 15, Stockholm');
      expect(
        find.text('Choose destination'),
        findsOneWidget,
        reason: 'Second selection must not close the route below the picker',
      );
      expect(find.byType(DriverDestinationPicker), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
