# Phase 46 — final global verification

Phase 46 introduces no product feature and no sheet redesign. It consolidates the post-audit verification baseline after Phases 32–45.

## Required exact-head CI

The Phase 46 head must pass:

- dependency resolution;
- Flutter analyzer;
- full test suite;
- release web build;
- verification artifact upload.

A successful run on an ancestor SHA does not satisfy this gate.

## Lifecycle coverage expected from the repository suite

The final suite must continue covering:

- offline → online → offered/claimed → active trip;
- driver-to-pickup → arrived/waiting → rider onboard → in trip → completion;
- driver cancellation and rider cancellation terminal outcomes;
- queued-next-trip handoff;
- stale/restart recovery and exact-trip cleanup;
- completion journal interruption/replay;
- history idempotency and unavailable financial metadata;
- settings/support persistence failure behavior;
- realtime duplicate/reorder/gap handling and terminal dominance;
- bounded terminal markers and legacy compatibility;
- reachable-screen/navigation regression checks.

## Sheet decision

User-reported real-device smoke testing found no sheet issue. Because the full device matrix was not captured, this phase does not claim cross-platform sheet certification. It does establish that no evidence currently justifies rewriting the working Home or Active Ride sheets.

## Backend/product limit

Passing Phase 46 does not convert the demo adapters into production services. Live backend, dispatch, payments, support transport, chat delivery, reservations, OTP, safety recording/sharing and document review require their own integration and end-to-end validation.
