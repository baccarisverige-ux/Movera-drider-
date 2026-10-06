# Driver trip island

The active trip has one top information surface, `AdaptiveTripIsland`. It receives immutable display values and callbacks; it does not transition trip stages, route the vehicle, or own the camera. `AcceptRide` remains responsible for navigation, waiting persistence and actions.

## Faces

- Guidance: maneuver cue, distance, road, trip status, destination, route progress and ETA/distance. Route/options, safety and payment indicators sit beside the route; on-trip radar retains its existing toggle.
- Waiting: eight seconds of elapsed time, then two seconds of rider status, repeating. The cycle is independent of one-second waiting updates. Stop waits identify the stop instead of claiming the driver is waiting for a rider.
- Default: a completed touch reveals the existing money/menu/search island. The live face returns after two seconds with no interaction. Active pointers suspend this timeout. Touch callbacks complete before the face changes so icon actions work.

Size follows content, not a random timer. Waiting uses a fixed-height timer/message slot; that alternation never resizes the island. Guidance can grow for two-line instructions. `AnimatedSize` and fades morph to/from the original island. Reduced-motion settings bypass those transitions. Timers are canceled on disposal.

## Sheet and camera

The trip opens with a visible collapsed dock: preferences, time, rider glyph, distance and rider status. Its summary/details control lifts the sheet to the action. Arrival never appears in the collapsed dock; the middle sheet retains the existing arrival confirmation and slide controls. Waiting retains its phase information in a centered pill timer.

The active route is black at 4 dp with round caps; traveled geometry remains faded. Gestures do not hide the collapsed sheet. The island and sheet reserve space in the existing map padding and follow-anchor adapter. The four-axis camera controller, cancellation, heading interpolation and web gesture bridge are unchanged.

## Data limits

Maneuver icons use the routing provider's existing symbols. Roundabouts display the provider's exit number. No traffic lights or regulatory signs are invented: the current route model does not provide those attributes. The circular cue is a schematic, not a geometrically surveyed junction.

## Restore

The original version is saved remotely at branch `backup/driver-before-adaptive-island-20261007`, commit `9e8a195d8943ec0f2c461049dd3f1e272f61e1b5`. Before merge, closing the PR leaves production unchanged. After merge, revert the merge commit in a new PR and run the normal deployment checks; never force-reset main.

## Verification

Widget tests cover island actions, two-second return, timer/name alternation, disposal, compact summaries and preferences/details callbacks. Existing trip lifecycle tests open the sheet before confirming an action. JavaScript camera contract checks still exercise pan, combined zoom/rotation, tilt, anchor and heading. Native and real Google Maps driving remain device QA requirements; headless tests cannot certify real GPS driving.
