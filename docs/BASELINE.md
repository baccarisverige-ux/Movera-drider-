# Movera Drider — Phase 0 Baseline

## Scope lock

This repository is **Movera Drider**: `baccarisverige-ux/Movera-drider-`.

The separate Rider repository `baccarisverige-ux/-movera-rider` is out of scope and must not be modified by Drider work.

Phase 0 freezes the current Drider visual product. Architecture work must preserve existing screens/design unless a later task explicitly authorizes a design change.

## Reconstructed upload

The original upload was delivered as four ZIP parts and reconstructed without conflicting duplicate paths. The project is Flutter and contains Android, iOS, web, Linux, macOS and Windows targets.

## Current bootstrap

`lib/main.dart` currently starts:

`MoveraApp -> ScreenUtilInit -> GetMaterialApp -> Splash -> OnboardingScreen`

The onboarding flow is intended to enter `DriverStarter`. The uploaded onboarding file contained stale imports to missing Rider screens; Phase 1 removes those stale references and keeps the flow inside Drider.

## Current source layout

The existing application is organized primarily as:

- `lib/constants`
- `lib/models`
- `lib/presentation/common`
- `lib/presentation/driver`
- `lib/widgets`

There is not yet a clear application/domain/data/infrastructure separation. This will be introduced incrementally after the baseline is buildable and protected by tests.

## Existing Driver feature inventory

The uploaded Driver presentation includes these major areas:

- Accept ride / cancel ride
- Add vehicle / upload vehicle photos
- Analytics: acceptance, cancellation, earnings, ratings, reviews
- Driver authentication and account creation
- Driver additional details / document upload / ID capture
- Documents
- Driving logs
- Earning stats
- Home / recent rides / destination panel / account activation
- Bank accounts
- Queue position / airport queue
- Wallet / withdrawal
- PIN verification
- Preferences
- Profile
- Promotions
- Ride completed
- Ride history / history details
- Ride requests
- Safety toolkits
- Pickup/drop-off location search and pickup confirmation
- Settings / accessibility / sound and voice
- Side menu
- Vehicles
- Common splash, onboarding and chat

## Current technical observations

- State/navigation currently depends heavily on widgets and GetX/imperative navigation.
- `pubspec.yaml` has no HTTP/Dio/Firebase/backend client dependency; no production backend should be invented during foundation work.
- The original `test/widget_test.dart` was Flutter's unrelated counter template and provided no Drider coverage.
- The uploaded root contained an accidental `tatus` file containing terminal `less` help; Phase 1 removes it.
- Several source folders contain spaces or punctuation. They are preserved during baseline stabilization to avoid unsafe mass renames; normalization belongs to a later architecture migration.
- Android application id is `se.movera.driver`. Release signing uses `MOVERA_UPLOAD_STORE_*` env vars when present, otherwise debug keys for local/CI previews.
- Large assets exist and should be optimized later only after visual regression protection is in place.

## Baseline rules

1. Do not redesign screens during architecture phases unless explicitly authorized.
2. Do not fabricate backend responses or production data.
3. UI must not become the long-term source of truth for ride state.
4. Every structural migration must be incremental and test-gated.
5. Keep Drider work isolated from the separate Movera Rider repository.
6. A phase is not complete until analyzer/tests for the exact branch head are verified.

## Phase 1 verification gate

The initial CI gate is:

1. `flutter pub get`
2. `flutter analyze --no-fatal-infos --no-fatal-warnings`
3. `flutter test`
4. `flutter build web --release`

Any failures found by this gate are treated as baseline defects and fixed before architecture migration begins.
