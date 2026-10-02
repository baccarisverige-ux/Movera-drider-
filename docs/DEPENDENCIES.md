# Dependency hygiene

Checked against the Driver source without a bulk upgrade.

`flutter_sliding_up_panel` was a direct dependency and had no import in `lib/`
or `test/`. The sheet uses `sliding_up_panel`. The unused package is removed.

Other direct dependencies were left on their current constraints. Map, picker,
animation, and UI packages were not upgraded together. Run `flutter pub outdated`
in a later maintenance change and upgrade one compatible group at a time.

## R08 (deep re-audit, N15/N16)

Removed direct dependencies with no import in `lib/`: `animator`, `flip_card`, `animated_segmented_tab_control`, `syncfusion_flutter_datepicker` (commercial/community licence), `readmore`, `flutter_colorpicker`, `carousel_slider`, `flutter_animate`, `fl_chart`, `riff_switch`, `lottie`. `test/audit/dependency_hygiene_test.dart` now fails on any unused direct dependency.

Removed the `driver-part-*.zip` upload snapshots (September source), `UPLOAD_MANIFEST.txt` and the superseded `docs/Movera-Driver-Audit-2026-09-29.pdf`. The repository tree is the single source of truth, and git history keeps the old files. `*.zip` is ignored.

Still open: `google_fonts` fetches fonts at runtime (bundle the font files as assets), and an injectable clock (N24).
