import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/navigation/driver_camera_controller.dart';
import 'package:movera/widgets/google_driver_camera_port.dart';

import '../../integration_test/headless_map_platform.dart';

class RecordingMapPlatform extends HeadlessMapPlatform {
  final List<CameraUpdate> moves = [];
  @override
  Future<void> moveCamera(CameraUpdate update, {required int mapId}) async {
    moves.add(update);
  }
}

void main() {
  testWidgets('four axes interpolate shortest-angle and input cancels frames', (
    tester,
  ) async {
    final original = GoogleMapsFlutterPlatform.instance;
    final platform = RecordingMapPlatform();
    GoogleMapsFlutterPlatform.instance = platform;
    addTearDown(() => GoogleMapsFlutterPlatform.instance = original);
    GoogleMapController? controller;
    const start = CameraPosition(
      target: LatLng(59, 18),
      zoom: 16,
      bearing: 359,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GoogleMap(
          initialCameraPosition: start,
          onMapCreated: (value) => controller = value,
        ),
      ),
    );
    await tester.pump();
    expect(controller, isNotNull);
    final port = GoogleDriverCameraPort(controller!, initialPosition: start);
    final animation = port.animate(
      const DriverCameraPose(GeoPoint(59.001, 18.001), 17, 1, 45),
    );
    await tester.pump();
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final payload = platform.moves.last.toJson() as List<dynamic>;
    final pose = payload[1] as Map<String, dynamic>;
    expect(pose['zoom'], greaterThan(16));
    expect(pose['tilt'], greaterThan(0));
    final bearing = pose['bearing'] as double;
    expect(bearing > 358 || bearing < 2, isTrue);
    port.interrupt();
    final count = platform.moves.length;
    await tester.pump(const Duration(seconds: 1));
    await animation;
    expect(
      platform.moves.length,
      count,
      reason: 'Interrupt cancels actual future camera moves',
    );
    final reduced = GoogleDriverCameraPort(controller!, reducedMotion: true);
    await reduced.animate(
      const DriverCameraPose(GeoPoint(59, 18), 17.5, 90, 45),
    );
    expect(platform.moves.length, count + 1);
    reduced.dispose();
    port.dispose();
    await tester.pumpWidget(const SizedBox());
  });
}
