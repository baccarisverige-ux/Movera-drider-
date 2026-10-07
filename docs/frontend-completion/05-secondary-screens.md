# Phase 5 — Secondary screen completion

Status: vehicle restore/action correction proposed; broad screen-state execution remains pending. Use the presentation inventory from phase 1; source references do not prove interaction coverage.

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

## Included vehicle correction

When a vehicle section contains a valid settings envelope with invalid vehicle rows, the list reports a restore failure but Add remained enabled. Entering Add cannot repair the unreadable list, and its later save also fails. Add and existing vehicle-management actions now remain disabled while the list loads or fails; the screen exposes progress and a guarded retry. A successful retry restores the actions.

`test/widget/vehicle_restore_action_test.dart` seeds malformed vehicle rows through SharedPreferences, checks the error and disabled Add, confirms the original stored text remains unchanged, repairs the test fixture, retries and checks that Add becomes enabled. The test-only commit precedes the correction. No real vehicle activation or document service is added.

Validation commands: `flutter analyze --fatal-infos`, `flutter test test/widget/vehicle_restore_action_test.dart`, and the full CI suite. Exact-head CI is required before calling the correction verified. Other matrix rows remain pending.
