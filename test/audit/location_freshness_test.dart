import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/location/location_freshness.dart';
import 'package:movera/core/geo/geo_point.dart';
void main() { test('denied stale invalid and fresh GPS are distinguished', () {
 final now=DateTime(2026); expect(hasFreshLocation(null,null,now),false);
 expect(hasFreshLocation(const GeoPoint(59,18),now.subtract(const Duration(seconds:31)),now),false);
 expect(hasFreshLocation(const GeoPoint(999,18),now,now),false);
 expect(hasFreshLocation(const GeoPoint(59,18),now,now),true);
 }); }
