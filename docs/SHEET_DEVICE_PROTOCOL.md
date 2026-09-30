# Phase 25 device evidence

Debug builds emit SHEET samples at pointer down/up, release +180ms/+460ms, and custom spring end. Traces are passive, disabled in release builds, and cancelled on disposal.

Run on a physical iPhone Safari/PWA and Android Chrome/native at 320×700, 375×812, 430×932 and a tall phone, with normal/200% text and reduced motion. Record 10 repetitions per gesture: collapsed→middle→expanded; fast flicks; interrupted spring; list at top/middle/bottom; map pan; sheet pointer cancellation; offline and route pop mid-drag. Record panel position/velocity, scroll offset, map handling and action-button visibility with video before/after.

Evidence status: NOT COLLECTED. CI does not establish physical gesture quality. Phase 26 must remain gated until the evidence selects one settle owner for each sheet.
