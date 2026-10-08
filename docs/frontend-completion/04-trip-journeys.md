# Phase 4 — Complete Driver trip journeys

Status: GPS resume and slow-routing corrections proposed with controlled regressions. Broader journey and device execution remains pending.

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
