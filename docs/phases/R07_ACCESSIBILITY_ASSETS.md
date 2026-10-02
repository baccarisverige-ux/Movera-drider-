# R07 - Screen-reader labels and unused assets

Source: deep re-audit of 2 October 2026 (N19, N28; residual of F31). N18 is not in this pull request.

## Change

- All 44 `IconButton`s now have a tooltip, which is also their semantic label: Back, Close, Settings, Add vehicle, Add trusted contact, `Call <name>`, Send. The custom checkbox reports Checked / Not checked and its selected state.
- 107 `AppAssets` constants referenced nowhere in `lib/` or `test/`, and their image files (11.05 MB), are removed. No asset path is built at runtime. Web build assets drop from about 19 MB to 8.2 MB.
- `test/audit/accessibility_assets_test.dart` fails if an IconButton has no tooltip or a declared asset is unused or missing.

## Not done (N18)

Localisation (ARB en/sv) and colour/typography tokens touch every screen (89+ literal strings, 885 raw colours). They need golden tests to prove visual parity and product copy for Swedish, so they are left as a dedicated follow-up and are **not** claimed here. VoiceOver/TalkBack runs stay in the release evidence matrix.
