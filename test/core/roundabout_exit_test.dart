import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/routing/osrm_route_parser.dart';

Map<String, dynamic> route({double? before, double? after}) => {
  'legs': [
    {
      'steps': [
        {
          'name': 'Circle',
          'distance': 30,
          'maneuver': {
            'type': 'roundabout',
            'exit': 3,
            'location': [18.0, 59.0],
            if (before != null) 'bearing_before': before,
            'bearing_after': 90,
          },
        },
        {
          'name': 'Exit road',
          'distance': 100,
          'maneuver': {
            'type': 'exit roundabout',
            'location': [18.001, 59.001],
            if (after != null) 'bearing_after': after,
          },
        },
      ],
    },
  ],
};
void main() {
  test('Roundabout arrow uses outgoing exit bearing, not entry tangent', () {
    const parser = OsrmRouteParser();
    for (final pair in [(0.0, 0.0), (90.0, 90.0), (270.0, -90.0)]) {
      final instruction = parser
          .parseInstructions(route(before: 0, after: pair.$1))
          .first;
      expect(instruction.exitAngleDegrees, pair.$2);
      expect(instruction.exitNumber, '3');
      expect(
        instruction.copyWith(distanceMeters: 42).exitAngleDegrees,
        pair.$2,
      );
    }
    final wrap = parser.parseInstructions(route(before: 350, after: 10)).first;
    expect(wrap.exitAngleDegrees, 20);
  });
  test('Missing or invalid bearings never fabricate an outgoing arrow', () {
    const parser = OsrmRouteParser();
    expect(
      parser.parseInstructions(route(after: 90)).first.exitAngleDegrees,
      isNull,
    );
    expect(
      parser.parseInstructions(route(before: 0)).first.exitAngleDegrees,
      isNull,
    );
    expect(
      parser
          .parseInstructions(route(before: double.nan, after: 90))
          .first
          .exitAngleDegrees,
      isNull,
    );
    expect(
      parser
          .parseInstructions(route(before: 0, after: 999))
          .first
          .exitAngleDegrees,
      isNull,
    );
  });
}
