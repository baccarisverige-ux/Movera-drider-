# Driver audit stack review and merge gates

This series is draft only. Review PR 16 through PR 29 in numerical order. Each PR targets the preceding phase branch, and no phase has been merged by opening the stack.

## Automated gate on each exact head

- Flutter dependency resolution, analyzer, widget and unit tests, and release web build must pass.
- Rerun the checks after any fix to a phase or descendant. A successful run on an older SHA does not validate a newer SHA.
- Check the changed-file diff for each PR against its declared base. If an earlier draft branch moves, refresh descendant branches before merging so each diff stays limited to its phase.

## Device gate before any merge

Use a narrow Android viewport and an iPhone Safari PWA, with normal and large text. Check Home collapsed/middle/open sheet dragging against scrolling content; activation actions above the dock; offer timeout, refresh, competing claims, and offline teardown. On an active trip check pickup arrival, wait, stop arrival, final drop-off, quick-finish confirmation, map pan while sliding, background/restart, completion archive, and queued trip promotion. Exercise Back, keyboard and sheet dismissal on auxiliary screens.

## Product gate

The repository is a frontend demo. Dispatch, reservations, payments, support, document review, safety recording/sharing, and OTP are not connected production services. Do not present local state as a sent request, captured payment, verified account, or safety event. Production authentication and service integrations need their own backend contracts and end-to-end checks.

## Merge sequence

16 baseline → 17 storage → 18 snapshot → 19 stops → 20 history → 21 queued ride → 22 shared offers → 23 Home sheet → 24 active sheet → 25 safety → 26 support demo → 27 settings → 28 auth boundary → 29 regression gate.

Merge one at a time only after its gate passes, retarget or refresh the next draft against the updated base, and inspect its diff and CI again. Keep rollback at the phase commit boundary. No automation merges these drafts.
