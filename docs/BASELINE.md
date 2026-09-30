# Movera Drider — current protected baseline

## Scope

This repository is **Movera Drider**: `baccarisverige-ux/Movera-drider-`.
The separate Rider repository is out of scope.

The application remains a Flutter frontend/demo. Architecture and reliability work must preserve the current product design unless a later task explicitly authorizes redesign.

## Canonical bootstrap

The current app starts directly on the Driver surface:

`MoveraApp → LayoutViewport → ScreenUtilInit → GetMaterialApp → DriverHome`

The old Splash bootstrap is not part of the canonical app entry. Legacy authentication remains opt-in behind `MOVERA_ENABLE_LEGACY_AUTH`.

## Current runtime boundaries

- Driver session state is owned by `DriverSessionController`.
- Active trip state and recovery use `ActiveRideController` / `ActiveRideRepository`.
- Completed/cancelled terminal transitions use the replayable `CompletionJournal`.
- Terminal markers prevent completed/cancelled snapshots from resurrecting.
- Completed-trip History is a separate projection and does not invent missing tip/payment facts.
- Driver realtime remains an in-memory/backend-ready seam. Events are sequence-gated per trip; duplicate/reordered events are ignored and terminal events dominate later non-terminal events.
- Driver location, routing, dispatch, support and settings remain replaceable boundaries rather than production backend integrations.
- Canonical market/currency remains Stockholm / SEK.

## Post-audit protections now present

- Home/active-trip lifecycle ownership and explicit `DriverOnlineStatus.onTrip`.
- Cold start remains offline.
- Replayable completion/cancellation journal.
- Driver/rider cancellation metadata survives terminal cleanup.
- Active-trip stale recovery and exact-trip cleanup.
- Bounded terminal-marker retention with legacy-marker compatibility.
- History archive idempotency by `tripId`.
- Truthful local/demo labels for contact, chat, support, settings, analytics, earnings, queue, promotions and driving-log preview data.
- Support optimistic state rolls back when local persistence fails.
- Settings persistence is isolated per section so one corrupted section does not erase unrelated sections.
- Realtime sequence ordering, reconnect replay of the newest known event and terminal dominance.
- Conservative orphan cleanup only after analyzer proof.

## Sheet behavior

A real-device smoke test was reported by the product owner on 2026-09-30 with no sheet defect observed. Device model/platform and the full trace matrix were not captured. Because no reproducible issue exists, the current Home and Active Ride sheet behavior is protected from speculative Phase 36/37 rewrites.

## Product limits

This repository does **not** establish a live production backend for dispatch, payments, support, chat delivery, reservations, document review, OTP, safety recording/sharing or account verification. Local/demo state must not be described as a successful production action.

## Current verification gate

Every implementation PR must pass on its exact head:

1. `flutter pub get`
2. `flutter analyze --no-fatal-infos`
3. `flutter test`
4. `flutter build web --release`
5. verification artifact upload

No newer commit is covered by an older successful workflow run.
