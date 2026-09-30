# Verification scope and limits

CI makes analyzer warnings fatal where configured (informational lints remain nonfatal). The current suite covers active-trip lifecycle, terminal markers, stale recovery, storage faults, replayable completion/cancellation, history hardening, local drafts/settings, realtime ordering, auxiliary navigation/back, responsive layouts and release web compilation.

Post-audit phases added coverage for:

- foreground Home/active-trip ownership and explicit on-trip session state;
- truthful contact/chat behavior;
- cancellation reason persistence and terminal races;
- history fields that remain unavailable instead of fabricated;
- operational/demo-data labeling;
- settings section isolation and support rollback behavior;
- realtime duplicate/reorder/gap/terminal handling;
- bounded terminal-marker retention and legacy compatibility;
- conservative orphan cleanup validated by analyzer.

## Physical evidence

The product owner reported testing the current sheet behavior on a real device on 2026-09-30 and reported no problem. Device/platform details and the full protocol matrix were not captured. This is sufficient to avoid speculative sheet rewrites, but not to claim full cross-platform physical certification.

## Remaining product boundary

Legacy auth is gated and no production backend is connected. CI/widget tests do not establish live dispatch, payment, support transport, rider messaging delivery or other backend operations.
