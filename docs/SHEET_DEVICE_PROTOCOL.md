# Sheet device evidence protocol

Debug builds can emit SHEET samples at pointer down/up, release +180ms/+460ms, and custom spring end. Traces are passive, disabled in release builds, and cancelled on disposal.

The full certification protocol remains: physical iPhone Safari/PWA and Android Chrome/native; representative narrow/tall viewports; normal/200% text; reduced motion; repeated collapsed→middle→expanded gestures, fast flicks, interrupted motion, list top/middle/bottom, map pan, pointer cancellation, offline teardown and route-pop during drag.

## Evidence recorded 2026-09-30

The product owner reported a real-device smoke test of the current sheet behavior and reported **no problem observed**.

The exact device model, OS/browser version, trace samples, video and full iPhone+Android matrix were not captured. Therefore:

- no reproducible sheet defect exists from the available evidence;
- Phase 36/37 speculative motion rewrites remain intentionally unmerged;
- the current working sheet behavior is protected;
- this record must not be described as full cross-platform physical certification.
