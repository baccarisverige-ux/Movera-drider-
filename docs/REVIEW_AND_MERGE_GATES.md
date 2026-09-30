# Driver post-audit review and merge gates

## Safe merge rule

Post-audit phases are merged one at a time only after their own exact-head CI succeeds. Descendants are retargeted to the updated `main` before merge. A planning document or a green ancestor does not validate a newer implementation head.

## Post-audit sequence

| Phase | PR | Scope | Final handling |
| --- | --- | --- | --- |
| 32 | #48 | Post-audit baseline | merged |
| 33 | #49 | Active-surface ownership | merged |
| 34 | #50 | Driver session / on-trip lifecycle | merged |
| 35 | #51 | Real-device sheet evidence record | merged; no defect reproduced |
| 36 | #52 | Active Ride sheet rewrite | intentionally unmerged; no reproduced defect |
| 37 | #53 | Home sheet rewrite | intentionally unmerged; no reproduced defect |
| 38 | #54 | Rider contact truth | merged |
| 39 | #55 | Cancellation integrity | merged |
| 40 | #56 | History truth | merged |
| 41 | #57 | Operational/demo data truth | merged |
| 42 | #58 | Local storage hardening | merged |
| 43 | #59 | Realtime ordering/idempotency | merged |
| 44 | #60 | Terminal marker retention | merged |
| 45 | #61 | Conservative dead-code cleanup | predecessor of Phase 46; exact-head CI required |
| 46 | #62 | Final verification/docs | current final gate |

## Automated gate

- Resolve dependencies.
- Analyzer must pass.
- Full unit/widget/audit test suite must pass.
- Release web build must pass.
- Verification artifact must upload.
- The successful workflow must point to the exact PR head SHA being considered.

## Runtime/device evidence

The product owner reported a real-device sheet smoke test on 2026-09-30 with no problem observed. The device model, platform/browser build, 10-repeat gesture matrix and video traces were not captured. Therefore this evidence supports **no speculative sheet change**, but it is not a full iPhone+Android certification.

## Product truth gate

The repository remains a frontend/demo. Dispatch, reservations, payments, support transport, rider chat delivery, document review, OTP, safety recording/sharing and production authentication are not connected services. UI must not claim those actions succeeded when only local state changed.
