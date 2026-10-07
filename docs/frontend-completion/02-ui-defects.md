# Phase 2 — Remaining UI defects and form validation

Status: support reply code fix proposed; broad UI review and legacy validation remain pending.

## Included change

The local support reply button observes composer text, rejects blank/whitespace input, disables during a save and disables after successful clearing. Its tooltip says "Save local reply". The new widget regression covers empty text, whitespace, valid trimmed text, one storage write and post-save disabling. Existing delayed-save tests still cover duplicate suppression and preservation of newer typed text.

## Remaining work

- [ ] Run the full Flutter suite on this PR head; record exact-head CI.
- [ ] Audit all enabled controls against the presentation inventory; detect silent/no-op and invalid-state actions.
- [ ] Verify all editable forms with blank, pasted, oversized, malformed and rapidly changed input.
- [ ] Confirm restore failures disable dependent actions and expose a working retry.
- [ ] Complete gated legacy vehicle/document prerequisites and field validation before enabling legacy onboarding.
- [ ] Verify open/back/reopen and rapid repeated actions across profile, vehicles, documents, support, schedule and settings.
- [ ] Verify listeners/controllers are disposed with their route and delayed results cannot update departed screens.

## Regression commands

`flutter test test/widget/support_reply_validation_test.dart test/audit/support_concurrency_test.dart`

`flutter analyze --fatal-infos` and `flutter test` remain required. A focused green test does not certify every form.

## Exit gate

Each actionable control performs its stated behavior exactly once, explains invalid input, preserves drafts on failure and offers recovery. Real service delivery is not claimed for local drafts. All confirmed defects found during this review have a regression and correction.
