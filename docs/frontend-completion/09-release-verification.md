# Phase 9 — Final candidate and release evidence

Status: pending all applicable preceding phases. The new release checker validates evidence metadata; it does not execute device or backend tests.

## Candidate manifest

Copy `09-release-candidate.json` into an evidence record for the actual release candidate. Set `commit` to its full Git SHA. Each required check has `result`, `commit`, `artifact` and `detail`; retain PENDING until performed. PASS requires a matching candidate SHA, a nonempty artifact and recorded context. N/A requires a concrete reason and human review; required checks in the template cannot be skipped.

Run `python3 tool/check_frontend_release.py path/to/candidate.json`. Without `--require-complete`, the command validates the manifest but prints incomplete checks. For final sign-off use `--require-complete`; any pending required row or any failed row rejects completion, including additional regressions outside the required list. Schema version must be integer 1 and results must be supported strings; malformed values are rejected with an actionable validation error. The checker cannot prove an artifact is truthful, so review the linked logs/screenshots/traces.

## Release sequence

- [ ] Fix all reproduced defects; retain focused regressions and the full existing suite.
- [ ] Finish the screen-state and original audit finding matrices.
- [ ] Run analysis, unit/widget tests, headless lifecycle, map contracts and web/Android/iOS builds on the candidate.
- [ ] Attach browser, real-SDK, physical-device, visual, accessibility, lifecycle and performance evidence for the same candidate.
- [ ] Complete staging integration evidence before production sign-off.
- [ ] Merge one reviewed phase at a time with exact-head CI; retarget/synchronize dependent work and inspect remaining diffs.
- [ ] Verify final main CI and deployment commit; smoke-test the deployed candidate, including cache/update behavior.
- [ ] Record rollback to a known deployed commit and verify recovery steps without deleting user work.

## Exit gate

All confirmed frontend defects are resolved and all applicable required checks are passed on the candidate. Deployment and smoke evidence match that commit. A documentation merge, compile or metadata-check success alone never means frontend or production completion.
