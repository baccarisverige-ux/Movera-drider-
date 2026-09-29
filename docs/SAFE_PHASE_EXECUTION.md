# Driver audit execution baseline

Base commit: `5f1e119bde841df466ceda1bc0e62f08bcea9cf6`.

This is a stacked, draft-only review series. No phase is merged automatically. Each PR targets the preceding phase branch so reviewers see one change at a time. Publication of a later draft does not approve earlier work.

## Invariants

- Preserve current Driver screens, Movera colors and sheet layout.
- Do not connect a backend or claim real payment, safety or support service from demo UI.
- Do not use a test skip as production authentication.
- Keep one canonical active trip and stable trip ID through accept, restart, cancel, complete and queued trip promotion.
- Merge only after Flutter analyze, tests, web build and affected mobile interactions pass on the exact head.

## Baseline gate

`flutter pub get`, `flutter analyze --no-fatal-infos --no-fatal-warnings`, `flutter test`, `flutter build web --release`; physical iPhone PWA and Android checks for sheet drag, map pan, keyboard, background/restart, narrow widths and large text.

Current frontend uses demo dispatch, local waybills and local support/reservations. CI checks analyze, tests and web build. Device and gesture checks remain manual.

## Dependency chain

00 baseline → 01 trip storage → 02 lifecycle snapshot → 03 stops → 04 archive/history → 05 queued ride → 06 offers → 07 Home sheet → 08 active sheet → 09 safety → 10 auxiliary data → 11 dead controls/settings → 12 auth → 13 regression.
