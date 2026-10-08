# Phase 2 — Remaining UI defects and form validation

Status: support draft/conversation fixes proposed with six additional regressions; broad UI review and legacy validation remain pending.

## Included change

The local support reply button observes composer text, rejects blank/whitespace input, disables during a save and disables after successful clearing. Its tooltip says "Save local reply". The new widget regression covers empty text, whitespace, valid trimmed text, one storage write and post-save disabling. Existing delayed-save tests still cover duplicate suppression and preservation of newer typed text.

## Browser findings and corrections

Tested the deployed baseline `ddf074a384dfb1ca3d32ce39b94393badb5d4deb` in Chrome on 2026-10-07 UTC, using synthetic local drafts only.

- Home raster map rendered and identified its unavailable 3D capability. The initial blank map resolved during startup; no map outage is claimed.
- Menu → Support → blank submission displayed both required-field errors. After typing valid text, the error remained until another submission. Fields now rebuild validation as the user corrects them.
- Local draft creation, reply persistence and return-to-inbox preview worked. An initial suspicion about stale inbox previews was ruled out by the browser test.
- With a conversation taller than its viewport, a newly saved long entry remained clipped at the bottom while the oldest entries stayed visible. Conversation history now opens at the newest entry, constructs rows lazily and returns to the newest reply after a successful save.
- The draft action was callable while loading/failed restore but silently returned. It now exposes a disabled action during restore, failure and composer opening.

[Baseline screenshot: clipped newest entry](evidence/support-history-before.jpg) shows the persisted long entry starting below older history and extending underneath the fixed composer. This is before-fix evidence, not a screenshot of a deployed correction.

Regression coverage adds a 500-message viewport, own-reply visibility after scrolling, storage-failure rollback/input preservation, pending-save single flight/newer draft preservation, disabled restore states with retry, and live validation correction. The first test-only CI run exposed a genuine newest-history failure and three test timing errors; text listeners are now pumped before tapping Save. The corrected test-only run must distinguish app defects from test mistakes before the fix is certified.

## Remaining work

- [ ] Run the full Flutter suite on this PR head; record exact-head CI.
- [ ] Audit all enabled controls against the presentation inventory; detect silent/no-op and invalid-state actions.
- [ ] Verify all editable forms with blank, pasted, oversized, malformed and rapidly changed input.
- [ ] Confirm restore failures disable dependent actions and expose a working retry.
- [ ] Complete gated legacy vehicle/document prerequisites and field validation before enabling legacy onboarding.
- [ ] Verify open/back/reopen and rapid repeated actions across profile, vehicles, documents, support, schedule and settings.
- [ ] Verify listeners/controllers are disposed with their route and delayed results cannot update departed screens.

## Regression commands

`flutter test test/widget/support_reply_validation_test.dart test/widget/support_conversation_regression_test.dart test/widget/support_draft_state_test.dart test/audit/support_concurrency_test.dart`

`flutter analyze --fatal-infos` and `flutter test` remain required. A focused green test does not certify every form.

## Exit gate

Each actionable control performs its stated behavior exactly once, explains invalid input, preserves drafts on failure and offers recovery. Real service delivery is not claimed for local drafts. All confirmed defects found during this review have a regression and correction.
