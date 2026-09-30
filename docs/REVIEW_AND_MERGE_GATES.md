# Driver audit stack review and merge gates

The current series is draft only: phases 14–31 are PRs #30–#47. Review in phase order. Phase 14 targets main; each successor targets the preceding phase branch. Earlier PRs #16–#29 are already part of the main baseline. Opening or updating this stack does not authorize any merge.

## Automated gate on each exact head

- Flutter dependency resolution, analyzer, widget and unit tests, and release web build must pass.
- Rerun the checks after any fix to a phase or descendant. A successful run on an older SHA does not validate a newer SHA.
- Check the changed-file diff for each PR against its declared base. If an earlier draft branch moves, refresh descendant branches before merging so each diff stays limited to its phase.

## Device gate before any merge

Use a narrow Android viewport and an iPhone Safari PWA, with normal and large text. Check Home collapsed/middle/open sheet dragging against scrolling content; activation actions above the dock; offer timeout, refresh, competing claims, and offline teardown. On an active trip check pickup arrival, wait, stop arrival, final drop-off, quick-finish confirmation, map pan while sliding, background/restart, completion archive, and queued trip promotion. Exercise Back, keyboard and sheet dismissal on auxiliary screens.

## Product gate

The repository is a frontend demo. Dispatch, reservations, payments, support, document review, safety recording/sharing, and OTP are not connected production services. Do not present local state as a sent request, captured payment, verified account, or safety event. Production authentication and service integrations need their own backend contracts and end-to-end checks.

## Merge sequence

| Phase | PR | Scope |
| --- | --- | --- |
| 14 | #30 | Wallet simulation |
| 15 | #31 | Document previews |
| 16 | #32 | Demo boundary and emergency dialer |
| 17 | #33 | Identity preview |
| 18 | #34 | Unavailable controls |
| 19 | #35 | Observable storage |
| 20 | #36 | Terminal and stale recovery |
| 21 | #37 | Completion and cancellation journal |
| 22 | #38 | History hardening |
| 23 | #39 | Radar location freshness |
| 24 | #40 | Destination teardown guard |
| 25 | #41 | Passive sheet traces |
| 26 | #42 | Physical-device evidence gate; no motion change |
| 27 | #43 | Scheduled ride preview |
| 28 | #44 | Local support drafts |
| 29 | #45 | Local settings |
| 30 | #46 | Route inventory and legacy auth gate |
| 31 | #47 | Fault, navigation, large-text and CI verification |


Merge one at a time only after its gate passes, retarget or refresh the next draft against the updated base, and inspect its diff and CI again. Keep rollback at the phase commit boundary. No automation merges these drafts.
