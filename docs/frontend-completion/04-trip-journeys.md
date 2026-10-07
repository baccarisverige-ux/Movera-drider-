# Phase 4 — Complete Driver trip journeys

Status: execution pending. Existing headless tests are retained; this record requires expanded controlled-fault and device journeys.

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
