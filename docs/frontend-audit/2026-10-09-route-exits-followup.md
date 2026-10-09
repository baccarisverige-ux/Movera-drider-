# Remaining route exits and stale actions

Base: PR #235, `a8e0b1f9f23f15a660c1c546f2e3d88e8c235d1c`. Three additional frontend findings, without counting each occurrence of a shared defect separately.

| ID | Trigger and failure | Correction | Regression coverage |
| --- | --- | --- | --- |
| E01 | A retained custom Back callback from a covered secondary screen calls Navigator.maybePop and closes the newer route. Similar callbacks can outlive their screen. | Add maybePopOwned: require a mounted, current route before requesting maybePop. Apply it to the remaining explicit maybePop exits in 16 presentation files, including settings, analytics, documents, vehicles, profile, preferences, bank/account, vehicle forms, promotions, reservation map and driver events. | Eleven screens tested with a covering route and repeated/disposed callbacks (22 tests). Shared helper test verifies PopScope blocks Back and a permitted Back returns the supplied route result. |
| E02 | Retained Add Contact callback opens a composer above another screen or calls setState after contacts are disposed. | Require the current mounted contacts route before setting the opening flag or showing the composer. | Covered and disposed callbacks cannot open a composer; current Add still opens normally (two tests). |
| E03 | Retained vehicle Retry calls setState after the failed vehicles screen has been disposed. | Check mounted before starting vehicle restore. | Failed restore, route removal, retained Retry: no new restore or exception (one test). |

Total: 26 behavior regressions across two new widget test files. Scope preserves maybePop and its PopScope/willPop protections; it does not replace guarded Back requests with unconditional pop. Full analysis, regression suite and platform builds are verified through repository CI. Physical-device checks are outside this run. No backend or deployment changes.

Stacked merge order: #233, #234, #235, then this PR; retarget each successor to main after its predecessor lands.
