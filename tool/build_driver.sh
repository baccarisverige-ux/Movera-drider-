#!/usr/bin/env bash
set -euo pipefail
mode="${1:-}"
if [[ "$mode" != "preview" ]]; then
  echo "Production build refused: real Driver adapters and staging verification are not configured. Use: tool/build_driver.sh preview <web|apk|ios>" >&2
  exit 1
fi
shift
flutter build "$@"
