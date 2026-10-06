# Driver map camera

Driver only; no Rider changes, map palette changes or trip lifecycle changes.

## Ownership

- `DriverCameraPolicy`: SDK-neutral route tangent, maneuver framing and bounded
  zoom/bearing/tilt transitions. Uses existing monotonic route progress so loops
  and roundabouts do not restart progress at a nearby earlier road segment.
- `DriverCameraController`: one owner of following, browsing and route-overview
  modes. Retains the latest usable GPS fix; serializes/coalesces animation work,
  invalidates pending commands on gestures, suspend, map replacement and dispose.
- `GoogleDriverCameraPort`: map SDK adapter. Uses camera-idle settlement with a
  bounded fallback because the SDK animation future can finish before the visual
  animation. Does not own/dispose Google's platform map controller.
- `CustomGoogleMap`: physical gesture reporting, independent of camera callbacks.
  One-finger drag, two-finger pinch/pan/rotate/tilt and wheel input pause follow.
  Taps without movement do not. Existing map overlay insets are preserved.
- Home and trip screens feed location/route context and retain their own sheet,
  marker and trip-stage presentation. No camera command is emitted directly by
  those screens; explicit offer previews also use the camera controller/adapter.

## Behavior

Without a trip: flat driver-location follow; all map gestures remain available.
Destination mode: same route-direction policy as a trip after recentering from
the explicit destination preview. Home offer previews remain until recenter.
Pickup/dropoff/intermediate stops: local route tangent faces up. The camera
previews significant maneuvers from 250 m, widens toward zoom 16.1 at 70 m, then
closes toward 17.6 at the maneuver. After passing it, it recovers toward 16.8.
Each update limits zoom change to 0.25 and uses shortest-angle bearing blending.
Waiting at pickup/paid stop: flat, close framing (17.2), no maneuver zoom.
Off-route: use driver heading while routing recovers, not the stale route tangent.

Any physical map gesture retains free browsing until the existing recenter
button is tapped. GPS and routing continue without overriding that viewport.
Recenter immediately uses the latest usable location and current route direction,
zoom and tilt; it is not merely a position reset. Trip recenter pulses in manual
mode. One-finger browsing leaves the trip sheet visible; zoom preserves the
existing sheet-clearing behavior. Reduced-motion users receive immediate follow
camera moves. Background/covered Home and paused trip maps stop camera work;
resume preserves manual mode. Old async completions cannot replay camera work.

## Verification and limits

`tool/verify_driver_camera.dart` is a standalone domain contract suite, also run
by `test/core/driver_camera_controller_test.dart`. It covers maneuver preview and
close-up, route bearing, angle wrap, off-route fallback, waiting, coalescing,
manual browsing, recenter, stale GPS, background/resume, late completions and
map replacement/dispose. Existing trip gesture/sheet tests remain applicable.

Real Android/iOS drive testing is still required to tune distances, zoom and
tilt against screen size, speed, GPS cadence, provider geometry and platform
gesture delivery. No simulated traffic or route geometry is added. The camera
cannot anticipate a maneuver absent from the route repository's instructions.
Gesture interruption clears future app camera commands; the map SDK itself
handles interruption of its currently running native animation by user input.
