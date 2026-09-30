# Verification scope and limits

CI makes analyzer warnings fatal (informational lints remain nonfatal). Test coverage includes terminal markers, stale recovery with a fake clock, faulting set/remove acknowledgements, completion interruption at each write, malformed/large history, local drafts/preferences, document truthfulness, and auxiliary screen navigation/back at 320×700, 375×812, 430×932 with 200% text. A PNG screenshot smoke artifact is uploaded from CI.

Existing active trip tests cover pickup/wait/start/stops/completion/queued handoff and Home/active sheets. Neither widget tests nor PNG smoke establish physical animation smoothness or backend operation. Device protocol and Phase 26 remain outstanding. Legacy auth is gated; no backend connected. No PR may merge without explicit user instruction.
