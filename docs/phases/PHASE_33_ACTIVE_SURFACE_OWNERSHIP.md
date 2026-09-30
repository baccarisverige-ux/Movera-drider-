# Phase 33 — fix(lifecycle): make active trip own foreground driver activity

Status: DRAFT / DO NOT MERGE

## Scope
- Suspend Home dispatch/radar and unnecessary Home GPS work while AcceptRide is foreground.
- Resume Home-owned activity only after the active ride route returns.
- Prevent duplicate driver-location and dispatch workloads without redesigning UI.

## Safety gate
- Depends on Phase 32. Verify accept/cancel/complete/restore lifecycle and no duplicate foreground subscriptions.
- This phase is intentionally isolated from unrelated redesign work.
- Required verification applies to the exact branch head after implementation changes land.

## Stack dependency
- Base: `audit/phase-32-post-audit-baseline`
- Head: `audit/phase-33-active-surface-ownership`
- Merge nothing without Houssem's explicit instruction.
