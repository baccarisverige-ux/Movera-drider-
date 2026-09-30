# Phase 52 — durable local drafts, consistent identity and terminal history

Audit F24–F26, F29, F37. Draft only.

Trusted contacts persist on device with validated numbers. The only seeded callable number is emergency services 112; invented personal numbers are removed. Dialer failures are observed.

Vehicle creation, document photos and removal now change device-local drafts. The list refreshes after edits; bounded camera images retain bytes and have a visible preview. Copy distinguishes local capture from upload, activation and verification. The sample car is consistently E 220 / MVR 418. Unverified documents no longer use completed-state styling. Restored waybill identity is retained rather than overwritten by sample identity.

History stores all terminal outcomes with cancellation actor/reason. Cancellations are not counted as completed rides or earnings. Known fares migrate to integer SEK minor units with strict locale parsing; unknown fares make totals unavailable rather than zero. The local archive serializes writes across instances.

Validation: durable vehicle draft/removal, exact grouped/negative money parsing and unknown amounts; existing journal tests now assert terminal cancellation history. Camera, dialer and browser storage-limit checks remain device gates. No backend service is implied.
