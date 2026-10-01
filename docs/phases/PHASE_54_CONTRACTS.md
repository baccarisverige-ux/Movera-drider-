# Phase 54 — integration contract and realtime cache

Audit F27, F28, F38. Draft only; operational services remain unconnected.

Realtime sequence numbers are per trip. Reconnect retains lifecycle projection independently of later location messages. Terminal projection dominates subsequent live messages. Unsubscribe invalidates old delivery. Regression coverage exercises interleaved trips, cached projections and terminal dominance.

The proposed OpenAPI contract now specifies bearer authentication, actor ownership errors, request and response schemas, expected versions, idempotency semantics, trip arrival/start/completion/cancellation, queue, driver availability, exact money and location measurement evidence. The Dart gateway is interface-only. No token, endpoint or production client is installed.

## External production gates (cannot be certified in frontend CI)

- Backend owner accepts the contract and implements atomic offer claims and trip transitions, version checks, idempotent retries, authorization per driver/trip and admin role boundaries.
- Authentication provider, token refresh/revocation and logout are integrated and tested. Legacy demo previews remain disabled.
- PIN protection is enforced server-side with attempts/rate limits, short-lived verification proof and no PIN logging.
- Realtime subscription/resync is tested against disconnects, gaps, terminal events and multiple trips using server state, not the memory bus.
- Payments, scheduled rides, rider chat, support delivery, document review, trip sharing and recording remain unavailable until their actual adapters and backend ownership exist.
- End-to-end staging tests demonstrate those services and failure/retry behavior. UI copy must continue to identify local/demo outcomes until then.

These are explicit unresolved production dependencies, not claims that every backend hole is fixed. CI validates the frontend and contract structure only. No merges are authorized.
