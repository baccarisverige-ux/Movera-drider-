# Additional 30 frontend findings — reviewed 9 October 2026

Baseline: `0a67d7ac756326e28ce472b2362b55a7a08b10a1` (`main`, after PR #228).
Frontend only. This patch consolidates the fixes in unmerged PRs #229–#232
and adds 26 distinct fixes. Do not merge the four overlapping drafts separately
from this consolidated patch. Findings already fixed in #225–#228 are excluded.
Each row counts one root defect, including grouped manifestations of one defect.

| ID | Trigger and observable failure | Correction | Regression |
| --- | --- | --- | --- |
| R01 | Caller mutates nested support values while a queued save waits; persisted draft changes silently. | Snapshot the submitted nested data before awaiting. | next30_storage R01 |
| R02 | Caller edits a vehicle map during storage read; a different plate is saved. | Snapshot the vehicle before entering the async queue. | next30_storage R02 |
| R03 | Logout invalidates a support read waiting for preferences; the departing session still receives data. | Recheck session generation after preferences load. | next30_storage R03 |
| R04 | Logout invalidates a history read waiting for preferences; the departing session still receives receipts. | Recheck session generation after preferences load. | next30_storage R04 |
| R05 | Ongoing trip statuses enter completed-trip history via archive or restore. | Require terminal statuses at both boundaries. | next30_storage R05 |
| R06 | Whitespace trip IDs produce unusable archive identities. | Reject whitespace IDs on write and restore. | next30_storage R06 |
| R07 | Adding an old backfilled receipt at capacity evicts a newer receipt. | Sort the combined records before applying retention. | next30_storage R07 |
| R08 | Queued map refresh reuses the first callback rather than the latest GPS/destination closure. | Retain the latest queued callback. | next30_navigation R08; overlaps #232 |
| R09 | A failed running refresh silently drops its queued recovery. | Drain the queued recovery before propagating the first failure. | next30_navigation R09 |
| R10 | An older but fresh GPS event rewinds the vehicle and clears its recovery banner. | Reject timestamps older than the last accepted measurement. | next30_navigation R10 |
| R11 | Driver rejoins the road before debounce; an obsolete reroute and recalculating banner remain. | Cancel pending reroute and clear transient copy when back on route. | next30_navigation R11 |
| R12 | Provider distance differs from polyline length; midpoint progress/ETA is wrong. | Divide projected progress by actual polyline length. | next30_navigation R12; overlaps #231 |
| R13 | Custom route adapter returns invalid coordinates or maneuver metrics; navigation accepts corrupt guidance. | Validate geometry and maneuver data at controller acceptance. | next30_navigation R13 |
| R14 | Ride stage changes but Retry retains the previous stage's destination. | Clear stage-owned destination, label and throttle metadata. | next30_navigation R14 |
| R15 | Trip starts during goingOnline and ends before connection completes; driver becomes available. | Restore online availability only when previously online. | next30_session R15 |
| R16 | Calling cold-start restore during an active trip changes occupancy to offline. | Skip availability restore while a trip owns the session. | next30_session R16 |
| R17 | Programmatic dropdown controller edit leaves the displayed selection stale. | Bind controller changes, including replacement and disposal. | next30_shared_form R17 |
| R18 | Duplicate dropdown options cause a selected-value assertion. | Deduplicate options in original order. | next30_shared_form R18 |
| R19 | Captured dropdown callback runs after disposal/controller replacement or beneath a new route. | Validate widget, controller, route and option ownership before writing. | next30_shared_form R19 |
| R20 | Shared input ignores a supplied callback without a second flag; flag with null callback throws. | Invoke the optional callback directly. | next30_shared_form R20 |
| R21 | Nullable obscure setting is force-unwrapped. | Treat null as false. | next30_shared_form R21 |
| R22 | Obscured multiline input causes a framework assertion. | Force one line for obscured input. | next30_shared_form R22 |
| R23 | Loading button remains enabled and submits duplicate pending work. | Disable its action during loading. | next30_shared_form R23 |
| R24 | NaN/negative progress hints bias projection onto an earlier nearby road pass. | Fall back to global projection for invalid progress hints. | frontend_route_progress_corruption; overlaps #229 |
| R25 | Empty route stroke builders call at() and throw. | Return empty traveled/remaining strokes for empty geometry. | frontend_empty_route_geometry; overlaps #230 |
| R26 | Invalid requested origin/destination is passed to the routing adapter and retained for Retry. | Reject coordinates, invalidate pending requests and clear invalid destination. | next30_navigation R26 |
| R27 | GPS course above 360 is normalized into a fictitious direction despite being invalid. | Retain previous course for values outside the valid compass domain. | next30_navigation R27 |
| R28 | Route provider reuses mutable lists; displayed geometry differs from cached projection or guidance. | Accept an immutable owned snapshot. | next30_navigation R28 |
| R29 | Legacy duplicate receipt ordered oldest first hides its newer corrected version. | Sort valid rows before deduplicating by trip ID. | next30_storage R29 |
| R30 | Fork/end-of-road guidance with missing direction invents a right turn. | Use neutral copy until an explicit direction is available. | next30_navigation R30 |

## Validation

Local: 14 Python release/deployment contract tests pass; web camera/gesture
contracts pass; Dart formatting and git whitespace checks pass. Six pure-Dart
regressions reproduce on main and pass with this patch, including a parallel-road
case for invalid progress hints.
Flutter dependency setup is unavailable in this checkout. Repository CI must
verify fatal-info analysis, complete unit/widget suite, critical lifecycle,
release web build, Android preview/signing checks and iOS compile preflight.
No physical-device, real-map or deployed verification is claimed by these tests.
