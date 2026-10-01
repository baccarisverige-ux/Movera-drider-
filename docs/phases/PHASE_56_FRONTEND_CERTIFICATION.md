# Frontend certification — code pass

This records what was executed on main after Phase 55, and what cannot be certified without a physical device.

Certified in this change:
- Wallet no longer presents invented balance, payout dates, payout rows, or a verified bank mask.
- Regression: test/presentation/wallet_truthfulness_test.dart.

Already on main from phases 47–55, not re-proven on a phone here:
- Confirmation cancel/retry, terminal-wins-during-pending-save, trip restore ownership, GPS stale failure, support restore unlock, reduced-motion hooks, contract seams only.

Explicitly not certified:
- Physical iPhone/Android sheet, GPS, 120 Hz, lock/unlock, PWA install.
- Browser matrix beyond CI web build.
- Visual screenshot diff.
- Full driver UAT (fast taps, one-hand, background mid-action).

Session online flag stays fail-closed: cold start forces offline even if a previous online value was stored. That is intentional, not a missing restore.
