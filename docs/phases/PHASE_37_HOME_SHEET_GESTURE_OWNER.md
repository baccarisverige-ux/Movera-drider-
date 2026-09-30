# Phase 37 — fix(sheets): establish one Home sheet gesture settle owner

Status: DRAFT / DO NOT MERGE

## Scope
- Apply the proven Phase 36 interaction model to Home.
- Preserve collapsed/middle/expanded positions and list scroll offset.
- Make map blocking deterministic and prevent between-snap resting states.

## Safety gate
- Depends on Phase 36. Physical-device regression required.
- This phase is intentionally isolated from unrelated redesign work.
- Required verification applies to the exact branch head after implementation changes land.

## Stack dependency
- Base: `audit/phase-36-active-sheet-gesture-owner`
- Head: `audit/phase-37-home-sheet-gesture-owner`
- Merge nothing without Houssem's explicit instruction.
