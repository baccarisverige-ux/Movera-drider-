# Phase 50 — route progress, GPS evidence and visible-screen ownership

Audit F04–F08, F12–F14. Draft only.

Progress projects onto road segments and measures maneuver distance along the route. Near turns retain turn instructions; stop routes name the stop. In-flight route results cannot notify a disposed controller. Repeated off-route fixes no longer restart the reroute deadline indefinitely.

Location observations retain measurement time and accuracy. Stale, inaccurate or unknown-age fixes cannot authorize arrival or Radar matching. Active-trip GPS subscription creation is guarded across awaited work, pause and disposal. Home owns GPS and animation/offer timers only while its route is visible and the app is foregrounded.

Validation: sparse-road midpoint, near-turn banner, disposed response and measurement evidence regressions. CI plus real permission, stale-location, background/resume and map-follow scenarios required before merge. No sheet physics rewrite is included.
