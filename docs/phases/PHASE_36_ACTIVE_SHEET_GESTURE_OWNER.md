# Phase 36 — fix(sheets): establish one active-ride gesture settle owner

Status: DRAFT / DO NOT MERGE

## Scope
- Implement the settle owner selected by Phase 35 evidence.
- Coordinate active ride content scrolling with panel dragging.
- Keep map gestures independent and the main slide action visible when collapsed.
- Remove corrective second-motion behavior if evidence confirms competing settle ownership.

## Safety gate
- Strictly depends on Phase 35 evidence. Do not merge while Phase 35 is blocked.
- This phase is intentionally isolated from unrelated redesign work.
- Required verification applies to the exact branch head after implementation changes land.

## Stack dependency
- Base: `audit/phase-35-active-sheet-device-evidence`
- Head: `audit/phase-36-active-sheet-gesture-owner`
- Merge nothing without Houssem's explicit instruction.
