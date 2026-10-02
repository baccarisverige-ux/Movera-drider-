# R01 - Storage integrity and recovery

Source: deep re-audit of 2 October 2026 (findings N01, N04, N10, N13; residuals of F18, F20, F35, F37).

## Problem

Several earlier fixes made storage fail closed without a way out:

- A completion journal whose queued trip conflicted with a newer trip, or a corrupt journal, threw on every replay. Every later `finish()` replays first, so no trip could ever complete again, and Home recovery stayed on "needs a retry".
- An unreadable active-trip snapshot made `read()` throw forever and blocked every new `save()`.
- A malformed settings section was treated as empty and then overwritten by the next save.
- Terminal markers split on `|`, so a trip ID containing `|` was not protected from revival.

## Change

- `LocalQuarantine` stores unreadable or conflicting raw records under `movera_driver_quarantine_*` (newest 10, cleared on logout) instead of deleting them.
- `CompletionJournal` validates the whole entry before any side effect. Corrupt entries are quarantined. A handoff conflict keeps the newer trip, closes trip A exactly once, and quarantines the journal. `reconcile()` returns a `JournalReplayOutcome`; Home shows a one-time notice.
- `PrefsActiveRideRepository.read()` throws `ActiveRideUnreadable` for undecodable data (plugin failures still propagate for Retry). `quarantineUnreadable()` moves only an undecodable record aside. Home offers **Close unreadable trip**.
- Ownership refusals are `RideOwnershipConflict` (a `StateError`, so existing callers are unchanged).
- Terminal marker fields escape `%` and `|`; legacy markers parse unchanged.
- Malformed settings sections and legacy blobs are quarantined before they can be overwritten.
- Archived terminal trips are labelled by outcome (for example "Cancelled by rider") instead of always "Completed".

## Not in scope

Cross-tab coordination on web (F19 residual) needs a browser lease (BroadcastChannel). It is recorded for a follow-up and is not claimed here.

## Validation

`test/audit/storage_integrity_test.dart` covers conflict and corrupt journals, unreadable snapshots, delimiter IDs, settings quarantine, pruning and logout. Existing recovery tests are unchanged except that a malformed snapshot now raises the typed `ActiveRideUnreadable`.
