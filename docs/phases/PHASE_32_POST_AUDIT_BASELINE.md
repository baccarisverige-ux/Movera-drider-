# Phase 32 — test(audit): add post-audit regression baseline

Status: DRAFT / DO NOT MERGE

## Scope
- Add regression coverage for newly identified P1/P2 findings before behavior changes.
- Protect Home/active-trip ownership, session lifecycle, call truth, cancellation data, history truth, sheet ownership, realtime ordering, and persistence boundaries.
- No product behavior change.

## Safety gate
- CI must pass on the exact PR head. No merge.
- This phase is intentionally isolated from unrelated redesign work.
- Required verification applies to the exact branch head after implementation changes land.

## Stack dependency
- Base: `main`
- Head: `audit/phase-32-post-audit-baseline`
- Merge nothing without Houssem's explicit instruction.
