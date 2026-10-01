#!/usr/bin/env python3
"""Reject a release matrix that claims PASS without an artifact."""
import sys
from pathlib import Path

path = Path(sys.argv[1] if len(sys.argv) > 1 else "docs/certification/RELEASE_EVIDENCE_MATRIX.md")
text = path.read_text()
required = (
    "device_or_browser",
    "viewport",
    "text_scale",
    "reduced_motion",
    "artifact",
)
for column in required:
    if column not in text:
        sys.exit(f"matrix missing column {column}")
rows = [line for line in text.splitlines() if line.startswith("| ") and not line.startswith("| id") and not line.startswith("| ---")]
if len(rows) < 8:
    sys.exit("matrix needs the device, browser, visual, and performance rows")
for line in rows:
    cells = [cell.strip() for cell in line.strip("|").split("|")]
    if len(cells) < 9:
        sys.exit(f"short row: {line}")
    result, artifact = cells[7], cells[8]
    if result == "PASS" and not artifact:
        sys.exit(f"PASS without artifact: {cells[0]}")
print(f"evidence matrix ok ({len(rows)} rows, no unproven PASS)")
