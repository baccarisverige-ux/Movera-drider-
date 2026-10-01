# Phase 48 — trip projections and session lifecycle

Audit: F01, F02, F03, F15, F16, F17. Draft; do not merge automatically.

Authoritative live projections can skip stages; all seven terminal outcomes are supported. Accepted events are retained while local persistence is busy and cancellation storage failures remain retryable. Initial subscription and lifecycle resume request resynchronization; transport/resync failures are visible. The shared session tracks occupied trips, excludes occupied drivers from Home offers, serializes storage writes, and ignores stale asynchronous restore results. Logout clears the shared availability session and the starter can return to the existing demo composition root.

Cold start still does not restore available-online status. A restored active trip is occupied, not available for new Home offers.

Validation: lifecycle projection and delayed-restore regressions added. Exact-head Flutter analyze, tests, and web build are required. Server projections are still an injectable seam, not an installed backend.
