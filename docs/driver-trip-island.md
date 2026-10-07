# Driver trip island

The active trip has one top information surface, `AdaptiveTripIsland`. It receives immutable display values and callbacks; it does not transition trip stages, route the vehicle, or own the camera. `AcceptRide` remains responsible for navigation, waiting persistence and actions.

## Faces

- Guidance: one maneuver cue and instruction, supporting distance/road, route progress and ETA/distance. Arrival replaces the instruction with arrival information and the destination address. Route/options, safety and payment indicators sit beside the route; on-trip radar retains its existing toggle.
- Waiting: eight seconds of elapsed time, then two seconds of rider status, repeating. The cycle is independent of one-second waiting updates. Stop waits identify the stop instead of claiming the driver is waiting for a rider.
- Default: a completed touch reveals the existing money/menu/search island. The live face returns after two seconds with no interaction. Active pointers suspend this timeout. Touch callbacks complete before the face changes so icon actions work.

Size follows measured primary text and its wrapping, including timer/message changes. Secondary GPS distance updates do not resize the island. `IslandMorph` owns one critically damped spring controller for width, height and corner geometry. Interrupted motion starts from the visible dimensions and projects the current velocity onto the new target. Content is laid out at its target size, clipped and faded independently; glyphs never stretch. The top center remains anchored. Reduced-motion settings resolve geometry directly. Timers and controllers are disposed. Guidance has one primary instruction and supporting road/distance plus a compact route/control strip; unrelated status and address lines are omitted. Arrival replaces guidance with the address. Blue is guidance/progress, lavender is waiting, red is arrival. Stop waits use the existing stop-specific message.

## Sheet and camera

The trip opens with a visible collapsed dock: preferences, time, rider glyph, distance and rider status. Its summary/details control lifts the sheet to the action. Arrival never appears in the collapsed dock; the middle sheet retains the existing arrival confirmation and slide controls. Waiting retains its phase information in a centered pill timer.

The active route is black at 4 dp with round caps; traveled geometry remains faded. Gestures do not hide the collapsed sheet. The island and sheet reserve space in the existing map padding and follow-anchor adapter. The four-axis camera controller, cancellation, heading interpolation and web gesture bridge are unchanged.

## Data limits

Maneuver icons use the routing provider's existing symbols. Roundabouts display the provider's exit number. No traffic lights or regulatory signs are invented: the current route model does not provide those attributes. Roundabout exit arrows use entry and explicit exit bearings when available; missing bearings show a circular cue and exit number without guessing the outgoing road. The cue remains a schematic, not a surveyed junction.

## Restore

The version live before this refinement is saved remotely at branch `backup/driver-before-island-morph-20261007`, commit `b6ad9d10254d41e8ff155f316b91c81ac7857526`. The earlier pre-redesign backup remains available separately. Before merge, closing the PR leaves production unchanged. After merge, revert the merge commit in a new PR and run the normal deployment checks; never force-reset main.

## Verification

Widget tests cover intermediate width/height frames, interruption continuity, same-face updates without animation restarts, reduced motion, island actions, two-second return, timer/name alternation, disposal, compact summaries and preferences/details callbacks. Existing trip lifecycle tests open the sheet before confirming an action. JavaScript camera contract checks still exercise pan, combined zoom/rotation, tilt, anchor and heading. Native and real Google Maps driving remain device QA requirements; headless tests cannot certify real GPS driving.
