import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/navigation/driver_map_zoom_change_detector.dart';

void main() {
  test('native zoom buttons register only when driver owns the map', () {
    final detector = DriverMapZoomChangeDetector(initialZoom: 15.8);
    expect(detector.observe(16.8, browsing: false), isFalse,
        reason: 'Following GPS can autozoom without pretending user browsed');
    expect(detector.observe(16.8, browsing: true), isFalse,
        reason: 'Pure pan does not alter zoom');
    expect(detector.observe(17.8, browsing: true), isTrue,
        reason: 'Google native zoom-in button triggers manual zoom');
    expect(detector.observe(16.8, browsing: true), isTrue,
        reason: 'Google native zoom-out button also triggers manual zoom');
    expect(detector.observe(16.8, browsing: true), isFalse);
  });

  test('fractional pinch increments accumulate without false pan triggers', () {
    final detector = DriverMapZoomChangeDetector(initialZoom: 16);
    expect(detector.observe(16.04, browsing: true), isFalse);
    expect(detector.observe(16.09, browsing: true), isFalse);
    expect(detector.observe(16.22, browsing: true), isTrue);
    expect(detector.observe(16.22, browsing: true), isFalse);
    expect(detector.observe(double.nan, browsing: true), isFalse);
    expect(detector.observe(16.32, browsing: true), isTrue,
        reason: 'Invalid SDK values must not poison zoom baseline');
  });

  test('late SDK follow changes do not enter manual zoom mode', () {
    final detector = DriverMapZoomChangeDetector(initialZoom: 15.8);
    expect(detector.observe(17.5, browsing: false), isFalse);
    expect(detector.observe(17.5, browsing: true), isFalse);
    expect(detector.observe(17.5, browsing: true), isFalse);
    expect(detector.observe(17.1, browsing: true), isTrue);
  });
}
