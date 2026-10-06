# Driver camera architecture

Driver only. Rider, palette and trip business lifecycle are unchanged.

## Ownership

- `DriverCameraPose`: target, zoom, bearing, tilt and animation duration.
- `DriverCameraPolicy`: GPS course hold, speed zoom, route snapping,
  look-ahead bearing, maneuver framing and arrival flattening. No SDK/UI imports.
- `DriverCameraController`: Explore/Preview/Following/Free state, usable-fix
  validation, lifecycle and serialized/coalesced output. Route updates and car
  progress continue in Free but do not move its camera.
- `GoogleDriverCameraPort`: four-axis smoothstep interpolation. 900 ms on
  guidance entry/recenter, 450 ms driving; shortest-angle bearing. Physical input
  invalidates the frame producer immediately. Reduced motion is instant.
- `CustomGoogleMap`: physical input release, native gesture-arena ownership,
  SDK callbacks and conditional web bridge. Camera callbacks never imply input.
- `RouteCameraGeometry`: reusable along-route sampling for car, look-ahead and
  split route stroke. Remaining stroke starts at the car (5 dp, round caps);
  traveled stroke is thin/faded (3 dp, 18% alpha), never thick behind the car.

## Modes

| State | Framing | Car |
| --- | --- | --- |
| Explore | Driver-centered, north-up, flat, neighborhood zoom 16.8 | Real course |
| Preview | Entire destination route fitted, north-up/flat; no GPS follow | Real course |
| Following | Heading-up, 45 degrees, speed zoom; vehicle at 72% of unobstructed map | Real course, on-route snapped |
| Free | Driver owns pan/zoom/bearing/tilt until Recenter | Continues real course and snapping |

The anchor is measured within the **visible map above the collapsed trip sheet**,
not the part of the screen hidden behind that sheet. Horizontal anchor is 50%.
Native SDK padding realizes the anchor; web uses OverlayView projection because
the pinned Flutter web plugin does not implement camera padding.

Course is accepted only with valid speed >=1 m/s; otherwise retain the last good
course (unknown speed is not evidence of movement). Look-ahead is 3 seconds of
travel, clamped 40–250 m. Its shortest-angle delta from GPS course is clamped
to +/-30 degrees and blended at 70%. Entry/recenter aims directly down the route.
Auto Zoom defaults on: 17.5 below 20 km/h, 16.5 at 20–50, 15.5 at 50–80,
14.75 above 80. Inside 180 m of significant maneuvers, zoom tightens toward
17.8 and tilt eases toward 20 degrees, recovering after passing. Last 35 m
flattens for arrival. Waiting/paid stops use flat 17.2 framing.

Home destination selection remains Preview, not guidance. Entering the active
pickup/dropoff screen begins guidance. Reroute does not reset manual mode,
vehicle course or camera bearing. Recenter without a trip is flat/north-up.

## Web adapter

Pinned `google_maps_flutter_web` 0.5.14+2 does not expose vector rendering,
touch heading/tilt, camera padding or bitmap-marker rotation. A small Driver-only
bootstrap adapter initializes **only Flutter Maps elements** using Google's
public `RenderingType.VECTOR` constructor option. It preserves inline styles,
API-key loading, traffic and the original SDK instances. No cloud map ID is
created/required. The constructor interception is isolated in
`web/driver_map_camera.js`; upgrading the plugin requires rechecking this adapter
against its element-ID and marker-option contracts.

That adapter owns touch pan, simultaneous pinch/twist, two-finger vertical tilt
(0–60), double tap and two-finger tap, and reports first touch/wheel to Dart.
Mouse/keyboard interaction remains with Google Maps. A projected image overlay
rotates the existing vehicle asset by real course minus map heading; only the
explicitly titled vehicle marker is replaced. Flutter listeners and overlays are
released when their map is disposed. Google may clamp tilt based on zoom and
hardware; WebGL capability must be verified on the target device.

## Verification

- `tool/verify_driver_camera.dart` (also Flutter test): speed thresholds,
  shortest angles, bounded bend lead, stationary course, snapping, split stroke,
  maneuver recovery, arrival, preview/start, recenter, reroute in Free, stale
  location rejection, lifecycle and obsolete command completion.
- `tool/verify_driver_map_web.cjs` (CI): constructor/palette, first-touch release,
  pan, simultaneous pinch/twist, tilt limits, tap gestures, projection anchor,
  vehicle overlay and listener removal. Uses SDK doubles, not real map tiles.
- Repository CI: analyzer, Flutter tests, lifecycle integration, web build,
  Android release preview and iOS compile preflight.

Acceptance still requires real browser/device testing: explore gestures; choose
a destination; begin guidance; drive a gentle right bend; pan and recenter;
approach a sharp turn/roundabout; arrive; reroute while Free. Unit tests, native
compile and deployment success are **not** proof of this driving experience.
