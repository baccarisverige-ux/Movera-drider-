import 'dart:async';
import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/core/navigation/driver_camera_controller.dart';
import 'package:movera/core/geo/geo_point.dart';

import 'driver_map_web_bridge_stub.dart'
    if (dart.library.js_interop) 'driver_map_web_bridge.dart'
    as web;

/// Four-axis interpolation with cancellation of the actual frame producer.
class GoogleDriverCameraPort implements DriverCameraPort {
  GoogleDriverCameraPort(
    this.controller, {
    this.reducedMotion = false,
    this.onFrame,
    CameraPosition? initialPosition,
  }) : _position = initialPosition;
  final GoogleMapController controller;
  final bool reducedMotion;
  final void Function(CameraPosition)? onFrame;
  CameraPosition? _position;
  int _generation = 0;
  bool _disposed = false;
  bool _producingFrames = false;
  void onMove(CameraPosition position) {
    if (!_producingFrames) {
      _position = position;
    }
  }

  void onIdle() {} // Idle is not evidence of a user gesture.

  Future<void> _move(CameraPosition position) async {
    await controller.moveCamera(CameraUpdate.newCameraPosition(position));
    _position = position;
    web.applyAnchor(controller.mapId);
    onFrame?.call(position);
  }

  @override
  Future<void> animate(DriverCameraPose pose) async {
    if (_disposed) {
      return;
    }
    final generation = ++_generation;
    _producingFrames = true;
    final from = _position;
    final to = CameraPosition(
      target: LatLng(pose.target.latitude, pose.target.longitude),
      zoom: pose.zoom,
      bearing: pose.bearing,
      tilt: pose.tilt,
    );
    if (reducedMotion || from == null) {
      await _move(to);
      if (generation == _generation) {
        _producingFrames = false;
      }
      return;
    }
    var elapsed = 0;
    final duration = pose.duration.inMicroseconds;
    while (!_disposed && generation == _generation) {
      final fraction = (elapsed / duration).clamp(0.0, 1.0);
      final t = fraction * fraction * (3 - 2 * fraction);
      await _move(
        CameraPosition(
          target: LatLng(
            from.target.latitude +
                (to.target.latitude - from.target.latitude) * t,
            from.target.longitude +
                (to.target.longitude - from.target.longitude) * t,
          ),
          zoom: from.zoom + (to.zoom - from.zoom) * t,
          bearing: GeoPoint.shortestAngleLerp(from.bearing, to.bearing, t),
          tilt: from.tilt + (to.tilt - from.tilt) * t,
        ),
      );
      if (fraction >= 1 || generation != _generation) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 16));
      elapsed += 16000;
    }
    if (generation == _generation) {
      _producingFrames = false;
    }
  }

  @override
  Future<void> overview(List<GeoPoint> points, double padding) async {
    if (_disposed || points.isEmpty) {
      return;
    }
    interrupt();
    final generation = _generation;
    var south = points.first.latitude, north = south;
    var west = points.first.longitude, east = west;
    for (final p in points.skip(1)) {
      south = math.min(south, p.latitude);
      north = math.max(north, p.latitude);
      west = math.min(west, p.longitude);
      east = math.max(east, p.longitude);
    }
    if ((north - south).abs() < .00001) {
      south -= .0002;
      north += .0002;
    }
    if ((east - west).abs() < .00001) {
      west -= .0002;
      east += .0002;
    }
    final position = _position;
    if (position != null) {
      await _move(CameraPosition(target: position.target, zoom: position.zoom));
    }
    if (_disposed || generation != _generation) {
      return;
    }
    await controller.moveCamera(
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
    _generation++;
    _producingFrames = false;
  }

  @override
  void dispose() {
    _disposed = true;
    interrupt();
  }
}
