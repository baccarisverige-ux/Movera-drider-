# Phase 4 — Complete Driver trip journeys

Status: GPS, acceptance ownership, elapsed waiting and delayed restore corrections proposed with controlled regressions. Automated journey coverage is expanded; physical-device and authorized staging execution remains pending.

Dependencies: phases 1–3, injectable location/realtime streams, delayed/failing repositories, and authorized staging services for real server outcomes.

| Journey | Required variants | Evidence |
| --- | --- | --- |
| Home → destination → preview | Rapid search, stationary destination replacement, no route, malformed response, offline/retry, cancel/back | PENDING |
| Offer → pickup | Double acceptance, expiry, revocation, competing taps, background during acceptance, restored trip | PENDING |
| Pickup → waiting → onboard | Fresh arrival gate, stale GPS, elapsed wait through lock/resume, duplicate onboard action | PENDING |
| Stops → drop-off | Multiple stops, arrival/wait/resume, bend/turn/reroute, recenter, stop/destination replacement | PENDING |
| Completion → receipt | Failed storage/server response, retry, restart during completion, journal replay, one receipt | PENDING |
| Cancellation | Driver/rider/admin outcome, delayed persistence, newer trip ownership, terminal UI once | PENDING |
| Logout → new session | Pending history/support/settings/trip writes, failed removal, retry, no old rider data | PENDING |

## Test method

Reproduce failures with controlled completion order, a deterministic clock, fault-counting storage and scripted location/realtime updates. Check state before and after each awaited operation, disposal and restart. Do not use production calls to generate cancellation/payment evidence.

## Exit gate

No duplicate acceptance or terminal outcome, no stale route/arrival state, no terminal resurrection and no lost recoverable trip. Every journey has normal, failure, retry and lifecycle evidence on the candidate commit. Add focused regressions for reproduced defects; retain the full suite and headless lifecycle tests.

## Included GPS lifecycle corrections

Home and active-trip location acquisition fenced successful results to the current visibility/generation, but failure handlers checked only whether the screen was mounted. A pending request from before pause could fail after resume and invalidate the newer fresh fix. Success and failure callbacks now share visibility/generation checks; subscription callbacks also reject stale owners.

The active trip also subscribed to GPS only after awaiting its initial road route. A slow route therefore prevented subsequent fresh fixes from reaching the arrival gate. GPS subscription now starts before the initial route request is awaited.

`test/audit/location_resume_failure_test.dart` exercises four controlled boundaries: an old request failing after a newer resumed fix, an old request succeeding from far away, a current GPS failure still blocking arrival, and a pending road route while streaming a fresh pickup fix. These tests use real arrival policy (`simulatedArrival: false`) and injected services; they make no production location or routing calls. Test-only commits precede the correction. Exact-head CI remains required.

Commands: `flutter test test/audit/location_resume_failure_test.dart`, `flutter analyze --fatal-infos`, full `flutter test`, and the existing headless lifecycle integration suite. These checks do not certify native background location, physical maps or all rows in the journey matrix.

## Acceptance, waiting and ownership corrections

Home and full Radar now convert thrown dispatch failures into a retryable UI outcome. Full Radar renders an inline error because it also appears as a sheet without its own Scaffold. Home keeps the winning claim locked until the active ride opens; removing another offer does not clear the matching owner or cancel the winning handoff. Pending and won Home claims survive pause; accepted-trip navigation waits for foreground/resume. Demo dispatch invalidates pending claims across reset and disposal, preventing a previous session from consuming a freshly restored offer.

Waiting uses an elapsed-time anchor instead of counting timer callbacks. It catches up after background/resume and delayed callbacks, retains accrued seconds across a backwards clock adjustment, starts restored paid-stop waits, and resets the anchor for each new stop. Authoritative projections start side effects from the current stage rather than the original stage passed to the widget.

The active-ride controller rejects disposed owners and fences delayed restore success/failure against newer operations. Current restore errors remain observable and retryable; stale restore results cannot regress a newly saved stage or a completed trip.

| Controlled verification | Coverage |
| --- | --- |
| `acceptance_session_races_test.dart` | Reset/dispose during claim, simultaneous claims, thrown transport failure and retry, expiry/unavailability, duplicate tap guard |
| `home_claim_ownership_test.dart` | Thrown error retry, unrelated offer removal during claim, winning claim locked through dispatch removal and navigation, pending/won claim across pause/resume |
| `active_ride_restore_races_test.dart` | Late restore after transition/completion, stale/current read errors, disposed commands |
| `wait_elapsed_lifecycle_test.dart` | Pickup and paid-stop waiting across lock/resume, delayed callbacks, backwards clock, repeated resume |
| `trip_journey_boundaries_test.dart` | Delayed duplicate onboard command, failed completion retry, authoritative arrival wait, two stops with independent paid waits |
| Existing `completion_journal_test.dart`, `terminal_retry_test.dart`, `authoritative_terminal_test.dart` | Interruption after every journal step, exactly one receipt, queued trip preservation, failed cancellation retry, authoritative terminal correction |
| Existing `frontend_storage_regression_test.dart`, `local_data_test.dart` | Failed cleanup and retry, pending history/support/settings writes, departing active-trip/journal owners, clean new session |
| Existing `navigation_lifetime_test.dart`, `navigation_test.dart`, headless lifecycle integration | Delayed routing/disposal, route failure/retry, navigation geometry, lifecycle persistence |

Before-correction proof branches retain the original algorithms and controlled tests. The only wait-time test seam is an injected clock; introducing that seam does not correct the original callback-counting algorithm. Exact candidate CI results are linked in PR #141. Simulated arrival is enabled only in the two-stop mechanics test; GPS arrival-policy regressions keep it disabled. No test substitutes a simulated arrival for native GPS evidence.

Still required: real dispatch/auth/payment outcomes, physical-device location and maps, native lock/background behavior, cross-browser visual evidence, measured performance and all remaining variants in the journey matrix. Passing controlled tests does not mark those rows complete.
