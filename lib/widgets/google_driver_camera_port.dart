import 'dart:async';
import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:movera/core/navigation/driver_camera_controller.dart';
import 'package:movera/core/geo/geo_point.dart';

/// The only SDK-specific follow-camera command emitter.
class GoogleDriverCameraPort implements DriverCameraPort {
  GoogleDriverCameraPort(this.controller, {this.reducedMotion = false});
  final GoogleMapController controller;
  final bool reducedMotion;
  Completer<void>? _settled;
  bool _disposed = false;

  @override
  Future<void> animate(DriverCameraPose pose) async {
    if (_disposed) {
      return;
    }
    if (reducedMotion) {
      await controller.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(pose.target.latitude, pose.target.longitude),
            zoom: pose.zoom,
            bearing: pose.bearing,
            tilt: pose.tilt,
          ),
        ),
      );
      return;
    }
    final settled = Completer<void>();
    _settled = settled;
    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(pose.target.latitude, pose.target.longitude),
            zoom: pose.zoom,
            bearing: pose.bearing,
            tilt: pose.tilt,
          ),
        ),
      );
      // SDK futures can complete before the visual animation. Idle is preferred;
      // timeout protects platforms which do not emit idle for unchanged poses.
      await settled.future.timeout(
        const Duration(milliseconds: 900),
        onTimeout: () {},
      );
    } finally {
      if (identical(_settled, settled)) {
        _settled = null;
      }
    }
  }

  void onIdle() => interrupt();
  @override
  Future<void> overview(List<GeoPoint> points, double padding) async {
    if (_disposed || points.isEmpty) {
      return;
    }
    var south = points.first.latitude, north = south;
    var west = points.first.longitude, east = west;
    for (final p in points.skip(1)) {
      south = math.min(south, p.latitude);
      north = math.max(north, p.latitude);
      west = math.min(west, p.longitude);
      east = math.max(east, p.longitude);
    }
    if ((north - south).abs() < 0.00001) {
      south -= 0.0002;
      north += 0.0002;
    }
    if ((east - west).abs() < 0.00001) {
      west -= 0.0002;
      east += 0.0002;
    }
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(south, west),
          northeast: LatLng(north, east),
        ),
        padding,
      ),
    );
  }

  @override
  void interrupt() {
    final settled = _settled;
    if (settled != null && !settled.isCompleted) {
      settled.complete();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    interrupt();
  }
}
