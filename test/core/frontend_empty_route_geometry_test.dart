import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/navigation/route_camera_geometry.dart';

void main() {
  test('empty route strokes are safe', () {
    final geometry = RouteCameraGeometry(const <GeoPoint>[]);
    expect(geometry.remaining(0), isEmpty);
    expect(geometry.traveled(0), isEmpty);
    expect(geometry.remaining(double.nan), isEmpty);
    expect(geometry.traveled(double.infinity), isEmpty);
  });

  test('single-point route strokes preserve the point', () {
    final geometry = RouteCameraGeometry(const [GeoPoint(59.3, 18.0)]);
    expect(geometry.remaining(0), hasLength(1));
    expect(geometry.traveled(0), hasLength(1));
  });
}
