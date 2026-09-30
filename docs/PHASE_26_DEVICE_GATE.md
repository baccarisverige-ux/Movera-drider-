# Phase 26 — single settle owner (blocked on device evidence)

This draft is the review gate required by the phase plan. No sheet behavior has been changed here.

Required before implementing/merging:
- Attach Phase 25 physical iPhone PWA and Android recordings and trace logs.
- Establish whether native snap or custom spring should own settling on each sheet.
- Remove the competing delayed normalization only after evidence reproduces the conflict.
- Specify inner scroll ↔ sheet handoff; verify all three targets, map pan, reduced motion, interrupted gestures, and persistent slide visibility.
- Attach matching after-change recordings and regression results.

Opening this PR is not evidence that Phase 26 is implemented or validated. Houssem must explicitly order any merge; this PR also needs the device evidence above.
