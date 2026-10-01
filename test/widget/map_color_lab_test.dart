import 'package:flutter_test/flutter_test.dart';
import 'package:movera/widgets/movera_map_style_lab.dart';

void main() {
  final style = MoveraMapStyleController.instance;

  tearDown(style.resetDefaults);

  test('map color lab defaults match the current Movera palette', () {
    style.resetDefaults();

    expect(style.colorHex('land'), '#E6EAED');
    expect(style.colorHex('water'), '#9FD2F3');
    expect(style.colorHex('highway'), '#8FA8DC');
    expect(style.styleJson, contains('"featureType":"water"'));
    expect(style.styleJson, contains('"color":"#9fd2f3"'));
  });

  test('map color lab validates HEX input before updating live style', () {
    style.resetDefaults();

    expect(style.setHex('water', '#123ABC'), isTrue);
    expect(style.colorHex('water'), '#123ABC');
    expect(style.styleJson, contains('"color":"#123abc"'));

    expect(style.setHex('water', '#XYZ123'), isFalse);
    expect(style.colorHex('water'), '#123ABC');
  });
}
