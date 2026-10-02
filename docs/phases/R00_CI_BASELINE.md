# R00 - Reproducible CI baseline

Source: deep re-audit of 2 October 2026 (N14, N25).

- All Flutter CI and Pages jobs pin `flutter-version: 3.47.6` on the stable channel. A Flutter release can no longer change analyzer or test results without a code change.
- `pubspec.lock` is regenerated. The committed lock was missing `integration_test` and its transitive packages, which were added with the lifecycle test. Every job runs `flutter pub get --enforce-lockfile` and fails on a stale lock.
- The analyzer baseline is zero, so CI now runs `flutter analyze --fatal-infos`.

Bumping Flutter is a deliberate change: update the pinned version in both workflows, regenerate the lock, and fix any new analyzer findings in the same pull request.
