# Phase 35 — test(sheets): collect active-sheet physical-device evidence

Status: DRAFT / DO NOT MERGE

## Scope
- Evidence-only phase; no sheet motion redesign.
- Use the existing sheet trace protocol on physical iPhone Safari/PWA and Android.
- Record collapsed/middle/expanded, flicks, interrupted springs, list scroll positions, map pan, pointer cancellation, large text and reduced motion.

## Safety gate
- BLOCKED until physical-device evidence is actually collected. Opening this PR is not evidence.
- This phase is intentionally isolated from unrelated redesign work.
- Required verification applies to the exact branch head after implementation changes land.

## Stack dependency
- Base: `audit/phase-34-driver-session-lifecycle`
- Head: `audit/phase-35-active-sheet-device-evidence`
- Merge nothing without Houssem's explicit instruction.
