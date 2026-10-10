import 'package:flutter/material.dart';

/// Shared map-route appearance for destination preview and trip guidance.
/// Waze iPhone app route colour (#5235DF, sampled from Waze App Store
/// screenshots; the user's day screenshots contain no active route).
abstract final class DriverRouteStyle {
  static const Color color = Color(0xFF5235DF);
  static const int width = 12;
}
