# Phase 55 — dead UI removal, API cleanup and final verification

Audit F33, F34; integrates final CI corrections. Draft only.

Removed 16 obsolete UI/model files after checking application and test consumers. The exact list is PHASE_55_REMOVED_FILES.json. Kept explicit domain/backend interfaces, tested domain models, legacy withdrawal preview files checked by truthfulness tests and the sheet-state seam. Being outside the main import graph alone is not proof that a contract should be deleted.

Reproducible inventory: `python tool/source_inventory.py`. Snapshot: PHASE_55_SOURCE_INVENTORY.json. It follows relative and package imports/exports/parts; runtime File reads and external consumers require review.

Migrated deprecated color opacity, switch, dropdown, bitmap and size-transition APIs; removed stale suppression directives, unused private map extensions and redundant imports; added block braces and simplified string interpolation. The supported Flutter API baseline is explicit in pubspec. CI must report the exact final analyzer result; no blanket lint suppression is added.

Final corrections await session restore storage, exercise the intended support button, dispose test semantics before end-of-test checks, accept a new snapshot only when its previous owner is terminal, rearm visible Home offers after route return, guard stale GPS failures, use unique queued demo occurrences and serialize vehicle draft updates.

## Merge gates

All nine PRs stay draft and unmerged. Review in order 47→55. Each head must pass analyze, complete tests and release web build. Re-run affected mobile interactions on the final merged candidate. Physical device evidence and operational backend integration remain pending as described in phases 53 and 54.
