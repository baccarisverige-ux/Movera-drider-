import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:movera/widgets/custom_google_map.dart';

import '../../integration_test/headless_map_platform.dart';

void main() {
  testWidgets('gesture-locked map ignores pan and pinch then restores input',
      (tester) async {
    final original = GoogleMapsFlutterPlatform.instance;
    GoogleMapsFlutterPlatform.instance = HeadlessMapPlatform();
    addTearDown(() => GoogleMapsFlutterPlatform.instance = original);
    var claims = 0;
    Widget screen(bool enabled) => MaterialApp(
      home: Scaffold(
        body: CustomGoogleMap(
          key: const ValueKey('gesture-locked-map'),
          myLocationEnabled: false,
          scrollGesturesEnabled: enabled,
          zoomGesturesEnabled: enabled,
          rotateGesturesEnabled: enabled,
          tiltGesturesEnabled: enabled,
          onUserGesture: () => claims++,
        ),
      ),
    );

    await tester.pumpWidget(screen(false));
    await tester.pump();
    final center = tester.getCenter(find.byType(CustomGoogleMap));
    final drag = await tester.startGesture(center);
    await drag.moveBy(const Offset(24, 0));
    await tester.pump();
    await drag.up();
    final first = await tester.startGesture(
      center + const Offset(-20, 0), pointer: 21);
    final second = await tester.startGesture(
      center + const Offset(20, 0), pointer: 22);
    await tester.pump();
    await second.up();
    await first.up();
    expect(claims, 0, reason: 'Disabled gestures cannot pause following');

    await tester.pumpWidget(screen(true));
    await tester.pump();
    final enabledDrag = await tester.startGesture(center);
    await enabledDrag.moveBy(const Offset(30, 0));
    await tester.pump();
    expect(claims, 1, reason: 'Drag works again when map unlocks');
    await enabledDrag.up();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });


  testWidgets('map tap preserves following while drag and pinch claim camera',
      (tester) async {
    final original = GoogleMapsFlutterPlatform.instance;
    GoogleMapsFlutterPlatform.instance = HeadlessMapPlatform();
    addTearDown(() => GoogleMapsFlutterPlatform.instance = original);
    var gestureClaims = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CustomGoogleMap(
          myLocationEnabled: false,
          onUserGesture: () => gestureClaims++,
        ),
      ),
    ));
    await tester.pump();
    final center = tester.getCenter(find.byType(CustomGoogleMap));

    await tester.tapAt(center);
    await tester.pump();
    expect(gestureClaims, 0,
        reason: 'A tap must not disable navigation follow camera');

    final drag = await tester.startGesture(center);
    await drag.moveBy(const Offset(4, 0));
    await tester.pump();
    expect(gestureClaims, 0,
        reason: 'Finger jitter must not interrupt camera following');
    await drag.moveBy(const Offset(12, 0));
    await tester.pump();
    expect(gestureClaims, 1,
        reason: 'Physical drag releases camera follow ownership');
    await drag.moveBy(const Offset(20, 0));
    await tester.pump();
    expect(gestureClaims, 1,
        reason: 'One drag reports exactly one ownership transition');
    await drag.up();

    final first = await tester.startGesture(
      center + const Offset(-20, 0),
      pointer: 11,
    );
    await tester.pump();
    expect(gestureClaims, 1);
    final second = await tester.startGesture(
      center + const Offset(20, 0),
      pointer: 12,
    );
    await tester.pump();
    expect(gestureClaims, 2,
        reason: 'Two-finger pinch/rotation immediately claims camera');
    await second.up();
    await first.up();

    await tester.tapAt(center);
    await tester.pump();
    expect(gestureClaims, 2, reason: 'A later tap also stays non-gestural');
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
