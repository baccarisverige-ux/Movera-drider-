#!/usr/bin/env python3
"""Validate candidate evidence metadata; never substitute for running checks."""
import argparse
import json
import re
import sys

REQUIRED = {
    "automated", "real-maps", "trip-journeys", "secondary-screens", "layout",
    "accessibility", "device-lifecycle", "performance", "staging-services",
    "deployment-smoke",
}


def validate(document, require_complete=False):
    if (not isinstance(document, dict)
            or type(document.get("schemaVersion")) is not int
            or document.get("schemaVersion") != 1):
        raise ValueError("unsupported candidate manifest")
    candidate = document.get("commit")
    if not isinstance(candidate, str) or not re.fullmatch(r"[0-9a-f]{40}", candidate):
        raise ValueError("candidate commit must be a full lowercase Git SHA")
    rows = document.get("checks")
    if not isinstance(rows, list):
        raise ValueError("checks must be a list")
    seen = set()
    incomplete = []
    for row in rows:
        if not isinstance(row, dict):
            raise ValueError("check must be an object")
        check = row.get("id")
        if not isinstance(check, str) or not check.strip() or check in seen:
            raise ValueError("check IDs must be nonempty and unique")
        seen.add(check)
        result = row.get("result")
        if not isinstance(result, str) or result not in {"PENDING", "PASS", "FAIL", "N/A"}:
            raise ValueError(f"{check}: invalid result")
        detail = row.get("detail")
        if result in {"PASS", "FAIL", "N/A"} and (
            not isinstance(detail, str) or not detail.strip()
        ):
            raise ValueError(f"{check}: record evidence context or N/A reason")
        if result == "PASS":
            if row.get("commit") != candidate:
                raise ValueError(f"{check}: evidence commit differs from candidate")
            artifact = row.get("artifact")
            if not isinstance(artifact, str) or not artifact.strip():
                raise ValueError(f"{check}: PASS requires an artifact")
        if result == "FAIL" or (check in REQUIRED and result != "PASS"):
            incomplete.append(check)
    missing = REQUIRED - seen
    if missing:
        raise ValueError("missing required checks: " + ", ".join(sorted(missing)))
    if require_complete and incomplete:
        raise ValueError("release incomplete: " + ", ".join(sorted(incomplete)))
    return sorted(incomplete)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest")
    parser.add_argument("--require-complete", action="store_true")
    args = parser.parse_args()
    try:
        with open(args.manifest, encoding="utf-8") as source:
            document = json.load(source)
        incomplete = validate(document, args.require_complete)
    except (OSError, ValueError) as error:
        print(f"evidence rejected: {error}", file=sys.stderr)
        return 1
    if incomplete:
        print("Manifest valid; release NOT complete: " + ", ".join(incomplete))
    else:
        print("Evidence metadata complete; review artifacts before release sign-off")
    return 0


if __name__ == "__main__":
    sys.exit(main())
