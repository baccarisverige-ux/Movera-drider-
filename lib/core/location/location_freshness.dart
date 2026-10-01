import 'package:movera/core/geo/geo_point.dart';
bool hasFreshLocation(GeoPoint? point, DateTime? observedAt, DateTime now) {
 if(point==null || observedAt==null || !point.latitude.isFinite || !point.longitude.isFinite
 || point.latitude.abs()>90 || point.longitude.abs()>180) { return false; }
 final age=now.difference(observedAt);
 return !age.isNegative && age<=const Duration(seconds:30);
}
