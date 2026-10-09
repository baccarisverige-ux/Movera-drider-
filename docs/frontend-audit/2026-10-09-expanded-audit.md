# Expanded frontend audit — 9 October 2026

Scope: frontend only. Target: ten distinct findings in each requested category. Categories organize findings; each root defect is counted once, even when several screens or tests are affected. This inventory does not claim the target is complete. Earlier PRs are not retrospectively counted here.

| Category | Confirmed findings | Target |
| --- | ---: | ---: |
| Bug | 5 | 10 |
| Error | 4 | 10 |
| Problem | 3 | 10 |
| Wrong code | 3 | 10 |
| Critique | 3 | 10 |

| ID | Category | Trigger / incorrect behavior | Fix | Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| F01 | Bug | Repeated or stale screen/sheet dismissals can pop the caller or repeat post-dismissal actions. | Owned exits and gated actions across the frontend. | global_route_exit_test.dart; global_sheet_exit_test.dart | 215 — merged, all CI green |
| F02 | Bug | History detail reconstruction drops stored tip, payment method, timestamp and original metadata. | Pass the original immutable record. | history_record_handoff_test.dart | 216 — merged, all CI green |
| F03 | Bug | Repeated safety actions can stack emergency confirmations and duplicate dialer handoffs. | Single-flight emergency workflow and owned entry checks. | safety_tool_ownership_test.dart | 216 — merged, all CI green |
| F04 | Bug | Document file selection can race another file selection or camera capture. | One pending selection lock for both entry points. | vehicle_document_picker_ownership_test.dart | 217 — verification pending |
| F05 | Error | Document/photo byte completion can call setState after screen disposal. | Check owner after every asynchronous boundary and before feedback. | vehicle_document_picker_ownership_test.dart | 217 — verification pending |
| F06 | Error | History detail rows overflow for long timestamp and cancellation content. | Constrain and wrap both label and value columns. | history_record_handoff_test.dart | 216 — merged, all CI green; overflow reproduced in first CI |
| F07 | Error | Update-link launcher exceptions escape the button callback; false results show no recovery. | Catch failed launches and retain a visible Retry state. | app_update_sheet_test.dart | 216 — merged, all CI green |
| F08 | Error | File with no readable bytes is presented as successfully selected. | Reject missing/empty byte payloads and allow retry. | vehicle_document_picker_ownership_test.dart | 217 — verification pending |
| F09 | Problem | Mandatory update sheet can be dismissed with system Back; missing link also dismisses it. | Consistent PopScope dismissal policy; failed handoff keeps prompt visible. | app_update_sheet_test.dart | 216 — merged, all CI green |
| F10 | Problem | History detail claims a 5.0 rider rating even though no rating exists in its data record. | Remove the fabricated rating badge. | history_record_handoff_test.dart | 216 — merged, all CI green |
| F11 | Problem | Failed preference writes leave changed controls looking saved after transient feedback disappears. | Persistent unsaved feedback and single-flight Retry. | settings_save_recovery_test.dart | 217 — verification pending |
| F12 | Wrong code | Legacy fare parser accepts doubled signs and inconsistent grouping as known amounts. | One optional sign and a consistent grouping separator. | money_label_validation_test.dart | 216 — merged, all CI green; also reproduced with standalone Dart |
| F13 | Wrong code | History outcomes expose enum wire names and missing internal actor/reason metadata in user copy. | Readable outcome labels bound to the actual status. | history_record_handoff_test.dart | 216 — merged, all CI green |
| F14 | Wrong code | Captured preference editing callbacks can mutate a disposed or covered screen. | Check current ownership when executing edits and persistence. | settings_save_recovery_test.dart | 217 — verification pending |
| F15 | Critique | Upload copy states an 800 by 400 pixel maximum for PDFs/files without enforcing such a rule. | Show supported formats without the false maximum. | Vehicle document source review | 217 — verification pending |
| F16 | Critique | Update button uses near-black text on a dark background. | Use white action text. | app_update_sheet_test.dart | 216 — merged, all CI green |
| F17 | Critique | Document picker actions are bare gestures without standard button keyboard/focus behavior. | Use Material text buttons for both actions. | vehicle_document_picker_ownership_test.dart | 217 — verification pending |
| F18 | Bug | Promotion copy claims success before the clipboard write completes and leaves failures unhandled. | Await clipboard completion, guard ownership, lock repeated copies and report failures. | promotion_clipboard_test.dart | 217 — verification pending |

Widget test filenames are under `test/widget/`, except money validation under `test/core/`. CI runs full analysis, Flutter tests, lifecycle and release contracts, web build, Android preview/signing guards and iOS compile preflight. Browser and physical-device interaction are still unverified in this environment. No backend changes are included.
