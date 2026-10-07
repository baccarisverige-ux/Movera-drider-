# Phase 5 — Secondary screen completion

Status: screen-state execution pending. Use the presentation inventory from phase 1; source references do not prove interaction coverage.

| Surface | Required work | Evidence |
| --- | --- | --- |
| Profile/photo | Permission denial, cancel, oversized/corrupt input, delayed decoding after leave, restart | PENDING |
| Vehicles | Add/edit/remove, required fields, long model/plate, year rollover, old saved year, failed save | PENDING |
| Documents | File/type/size validation, upload-preview truth, decode failure, close while pending, restart | PENDING |
| Schedule | Tabs/empty states, stale selection, detail double entry, ID-based changes, failed mutation | PENDING |
| Wallet | Amount formatting, empty/error, navigation, truthful local/preview actions, repeated taps | PENDING |
| History | Mixed corrupt rows, future schema, receipt details, duplicates, completion/cancellation labels | PENDING |
| Support/chat | Draft recovery, save failure, rapid compose/open/close, 1,000 messages, keyboard and scroll | PENDING |
| Settings/safety | Restore failure, toggles mid-save, write coalescing, semantic names, unavailable dialer | PENDING |

## Shared state checklist

For each reachable screen execute initial/loading/loaded/empty/error/retry/offline; small/large/null/malformed data; enter/leave/return/back/reopen; keyboard/focus/text scale/rotation; foreground/background; and slow/out-of-order responses. Mark unsupported states N/A with a reason. Check each visible control against current-state validity.

## Exit gate

Every reachable surface has evidence for its applicable states. Invalid inputs get actionable feedback, failures preserve recoverable user work and preview actions do not claim service delivery. Confirmed defects are fixed with regressions. Shared profile/settings/history/support state remains isolated across routes and sessions.
