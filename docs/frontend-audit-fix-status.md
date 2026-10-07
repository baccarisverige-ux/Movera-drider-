# 7 October frontend correction status

Baseline: `55026d5211bb41b921f819b9f6b88be5f8619811`. No merge or deployment authorized in this batch.

| Audit IDs | Patch | Verification |
| --- | --- | --- |
| 003–007 | Phase 1: validated history, preserved originals, support recovery, checked logout, stale-session fence | New CI regressions; await complete CI |
| 008–010 | Phase 2: destination identity, full geometry comparison, route failure/retry | New CI regressions; device journeys pending |
| 001–002 | Phase 3: cloud-style vector construction and observed raster fallback | JS contract passes; cloud configuration and real SDK screenshots pending |
| 014, 022–023 | Phase 3: owned service disposal, settled scheduler stop, camera retry feedback | Port regressions; device profiling pending |
| 011–013 | Phase 4: route entry guards, composer single flight, spring cancellation | Added regressions; runtime chaos pending |
| 015–021, 024–025 | Phase 5: field validation, keyboard-safe contacts, voice semantics, lazy chat, text/motion/year policy | Added regressions; screenshots/device traces pending |
| 026–028 | Phase 6: route-local onboarding ownership, atomic advance, local progress tickers, disabled unavailable sign-in, production root/build guard | Added regressions; real authentication prerequisites and production adapters remain integration work |

## Styled vector map configuration

Set repository variable `DRIVER_MAP_ID` to a JavaScript vector map ID associated with a published cloud style that matches `lib/styles/reference_map_style.dart`. The deployment injects this non-secret ID into the HTML meta element. Vector construction excludes incompatible inline `styles`. Without that configuration, the preview explicitly uses styled 2D and announces that 3D is unavailable. This is a documented fallback, not real-SDK palette certification. Do not call FRONTEND-001 fully verified until city/street screenshots on Home, preview and trip match the approved palette.

Reference: https://developers.google.com/maps/documentation/javascript/map-rendering-type and https://developers.google.com/maps/documentation/javascript/webgl/support.

## Open execution matrix

The audit's 24-phase coverage gaps remain open: complete screen/interaction state inventory, native keyboard/system back/lock/resume/restart, pickup–wait–stop–dropoff/cancellation journeys, live network/storage chaos, sustained-session performance, responsive screenshots/text scale, real Maps gestures/fallback/recenter, and final combined regression. Compilation alone is not runtime evidence. Production-preview integrations must not be relabelled as working backend services.
