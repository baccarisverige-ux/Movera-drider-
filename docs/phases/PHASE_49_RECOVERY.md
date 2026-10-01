# Phase 49 — recovery ownership and validation

Audit: F18, F19, F20, F21, F22, F30, F36. Draft only.

Storage failures and malformed or unsupported snapshots remain observable and retain raw data. All repository instances share a serialized queue. Terminal snapshots cannot revive and older stages cannot rewind progress. Journal handoff checks ownership before replacing A with B; replay of B never rewinds it, and unrelated C is retained with a visible conflict.

Home resolves recovery before exposing offers. Missing saved coordinates require explicit closure rather than invented Stockholm locations. Queued coordinates and provided timestamps are validated; far-future snapshots are not fresh. Destination mode and its endpoint survive active-trip snapshots and handoff. Each accepted demo occurrence gets a unique trip ID while dispatch offer IDs remain stable.

Validation: ownership, terminal resurrection, corrupt storage, and invalid-coordinate/time regressions. CI and restart/reload device scenarios required. Terminal history outcomes are addressed in the data phase.
