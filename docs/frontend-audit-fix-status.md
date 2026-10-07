# 7 October frontend correction status

Original audit baseline: `55026d5211bb41b921f819b9f6b88be5f8619811`. The authorized correction PRs #132–#137 are merged. Current deployed baseline: `ddf074a384dfb1ca3d32ce39b94393badb5d4deb`.

[Main CI 37696353966](https://github.com/baccarisverige-ux/Movera-drider-/actions/runs/37696353966) passed analysis, 416 tests, 2 headless lifecycle tests, web build, Android safeguards/preview and iOS compile. [Pages deployment 37697043119](https://github.com/baccarisverige-ux/Movera-drider-/actions/runs/37697043119) succeeded on the same commit. These records do not certify physical devices, real SDK behavior, full browser journeys or production services. See `frontend-completion/01-baseline.md` for the next coverage work.

| Audit IDs | Patch | Verification |
| --- | --- | --- |
| 003–007 | Phase 1: validated history, preserved originals, support recovery, checked logout, stale-session fence | Merged; automated regressions pass; device/restart chaos pending |
| 008–010 | Phase 2: destination identity, full geometry comparison, route failure/retry | Merged; automated regressions pass; device journeys pending |
| 001–002 | Phase 3: cloud-style vector construction and observed raster fallback | JS contract passes; cloud configuration and real SDK screenshots pending |
| 014, 022–023 | Phase 3: owned service disposal, settled scheduler stop, camera retry feedback | Merged; port regressions pass; device profiling pending |
| 011–013 | Phase 4: route entry guards, composer single flight, spring cancellation | Merged; regressions pass; runtime chaos pending |
| 015–021, 024–025 | Phase 5: field validation, keyboard-safe contacts, voice semantics, lazy chat, text/motion/year policy | Merged; regressions pass; screenshots/device traces pending |
| 026–028 | Phase 6: route-local onboarding ownership, atomic advance, local progress tickers, disabled unavailable sign-in, production root/build guard | Merged; regressions pass; real authentication prerequisites and production adapters remain integration work |

## Styled vector map configuration

Set repository variable `DRIVER_MAP_ID` to a JavaScript vector map ID associated with a published cloud style that matches `lib/styles/reference_map_style.dart`. The deployment injects this non-secret ID into the HTML meta element. Vector construction excludes incompatible inline `styles`. Without that configuration, the preview explicitly uses styled 2D and announces that 3D is unavailable. This is a documented fallback, not real-SDK palette certification. Do not call FRONTEND-001 fully verified until city/street screenshots on Home, preview and trip match the approved palette.

Reference: https://developers.google.com/maps/documentation/javascript/map-rendering-type and https://developers.google.com/maps/documentation/javascript/webgl/support.

## Open execution matrix

The audit's 24-phase coverage gaps remain open: complete screen/interaction state inventory, native keyboard/system back/lock/resume/restart, pickup–wait–stop–dropoff/cancellation journeys, live network/storage chaos, sustained-session performance, responsive screenshots/text scale, real Maps gestures/fallback/recenter, and final combined regression. Compilation alone is not runtime evidence. Production-preview integrations must not be relabelled as working backend services.
