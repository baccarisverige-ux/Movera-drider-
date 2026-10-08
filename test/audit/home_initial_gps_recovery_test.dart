import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/location/driver_location_repository.dart';
import 'package:movera/core/session/driver_runtime_config.dart';
import 'package:movera/presentation/driver/home/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../integration_test/headless_map_platform.dart';

class _RecoveringHomeLocation implements DriverLocationRepository {
  final updates = StreamController<DriverLocation>.broadcast();
  int currentRequests = 0;

  @override
  Future<DriverLocation> getCurrentPosition() async {
    currentRequests++;
    throw StateError('GPS provider briefly unavailable');
  }

  @override
  Stream<DriverLocation> watchPosition({int distanceFilterMeters = 8}) =>
      updates.stream;
}

class _CameraRecordingMaps extends HeadlessMapPlatform {
  final moves = <CameraUpdate>[];

  @override
  Future<void> moveCamera(CameraUpdate update, {required int mapId}) async {
    moves.add(update);
  }
}

void main() {
  final previous = DriverRuntimeConfig.current;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DriverRuntimeConfig.current = const DriverRuntimeConfig(
      externalRouting: false,
      liveMapTicker: false,
      reservationPopup: false,
      islandHint: false,
      simulatedArrival: false,
      skipAccountActivation: false,
    );
  });
  tearDown(() => DriverRuntimeConfig.current = previous);

  testWidgets('Home reconnects live GPS after its initial fix fails', (
    tester,
  ) async {
    final originalMaps = GoogleMapsFlutterPlatform.instance;
    final maps = _CameraRecordingMaps();
    GoogleMapsFlutterPlatform.instance = maps;
    addTearDown(() => GoogleMapsFlutterPlatform.instance = originalMaps);

    final location = _RecoveringHomeLocation();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(
        home: DriverHome(locationRepository: location),
      ),
    ));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(location.currentRequests, greaterThanOrEqualTo(1));
    expect(location.updates.hasListener, isTrue,
        reason: 'Stream must recover from a one-shot GPS request failure');

    const live = LatLng(59.34, 18.07);
    location.updates.add(DriverLocation(
      point: const GeoPoint(live.latitude, live.longitude),
      measuredAt: DateTime.now(),
      accuracyMeters: 5,
      speedMetersPerSecond: 4,
    ));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final mapsOnScreen = tester.widgetList<GoogleMap>(find.byType(GoogleMap));
    expect(mapsOnScreen, isNotEmpty);
    expect(mapsOnScreen.any((map) => map.markers.any((marker) =>
      marker.markerId.value == 'driver_location' &&
      marker.position == live)), isTrue,
      reason: 'Recovered live GPS must replace the fallback driver marker');
    expect(maps.moves, isNotEmpty,
        reason: 'Recovered GPS must also issue a camera move');
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
    await location.updates.close();
  });
}
