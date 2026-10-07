# Phase 7 — Device lifecycle and sustained performance

Status: physical-device and profile/release traces pending. Compile success is not lifecycle or performance certification.

## Device scenarios

- [ ] iPhone: permissions granted/denied/restricted, location changes, keyboard, safe area, lock/unlock, foreground/background and process restart.
- [ ] Android: permission variants, hardware/system Back, activity recreation, process death, restart and denied dialer availability.
- [ ] Both: acceptance/waiting/active trip/completion during background or termination; elapsed waiting time and trip recovery remain correct.
- [ ] Browser/PWA: reload, install, offline/reconnect, background tab, map reinitialization and session cleanup.

## Sustained run

Record a 30-minute multi-feature profile/release session: online idle, offer, pickup, waiting, route/stop transitions, map gestures/recenter, support/settings navigation and logout. Capture cold-start and tap-to-feedback/usable-frame timings, frame p50/p95, long frames, heap snapshots, active listeners/timers/subscriptions, location/route request counts and battery observations.

Use identical devices and scenarios before/after a proposed performance change. Define numeric acceptance budgets from the measured baseline and target device class before marking a row passed; do not invent timings from CI. Investigate growing resources, unnecessary stationary/background wakeups and duplicate requests.

## Exit gate

No lifecycle-induced stale state, lost recoverable trip or terminal resurrection. Ownership counters settle after leaving a feature and across repeated journeys. Memory/request/frame traces meet the recorded budgets and contain no unexplained sustained growth. Attach candidate SHA, device/OS/build mode, scenario and trace artifacts.
