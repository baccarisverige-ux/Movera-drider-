# Dependency hygiene

Checked against the Driver source without a bulk upgrade.

`flutter_sliding_up_panel` was a direct dependency and had no import in `lib/`
or `test/`. The sheet uses `sliding_up_panel`. The unused package is removed.

Other direct dependencies were left on their current constraints. Map, picker,
animation, and UI packages were not upgraded together. Run `flutter pub outdated`
in a later maintenance change and upgrade one compatible group at a time.
