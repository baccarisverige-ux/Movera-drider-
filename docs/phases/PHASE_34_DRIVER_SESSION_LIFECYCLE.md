# Phase 34 — fix(session): model on-trip driver lifecycle explicitly

Status: DRAFT / DO NOT MERGE

## Scope
- Use canonical offline → goingOnline → online → onTrip transitions.
- Define completion, driver cancellation, rider cancellation, queued-next-trip, recovery and suspension transitions.
- Preserve D11: cold start never silently restores online availability.

## Safety gate
- Depends on Phase 33. Verify all terminal and queued-handoff paths.
- This phase is intentionally isolated from unrelated redesign work.
- Required verification applies to the exact branch head after implementation changes land.

## Stack dependency
- Base: `audit/phase-33-active-surface-ownership`
- Head: `audit/phase-34-driver-session-lifecycle`
- Merge nothing without Houssem's explicit instruction.
