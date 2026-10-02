# R11 - Driver contract coverage (proposed)

Source: deep re-audit of 2 October 2026 (F28 residual; prerequisite for F38, F23, F25).

`docs/contracts/openapi.yaml` 0.3.0 adds proposed operations for every Driver capability the screens show: offers feed, realtime resync with cursor, PIN verification (a short-lived token consumed by start), trip messages, rider rating, GPS sample batches (age and accuracy carried for arrival checks), history with typed money and outcomes, support tickets, vehicles, document upload (the client keeps no copy) and payouts. All state-changing driver commands require `Idempotency-Key` and share the error schema.

`test/audit/contract_test.dart` checks that references resolve, operation IDs are unique, every screen capability has an operation, and idempotency keys are present.

## Still required before operational use (Phase 11 / 12)

This is a **proposal**. No backend, authentication provider, realtime transport or adapter is installed by this change. Before any operational feature is enabled:
1. Backend, Rider and Admin teams review and agree the schema.
2. Server contract tests run against staging.
3. Driver adapters ship behind feature flags, with demo adapters kept for the public demo.
4. Two-client staging end-to-end tests pass, followed by device certification (release evidence matrix).
