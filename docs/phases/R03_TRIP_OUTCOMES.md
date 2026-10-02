# R03 - One exit path for authoritative trip outcomes

Source: deep re-audit of 2 October 2026 (N02, N11, N26; residual of F26).

## Problem

- A backend terminal projection (completed, cancelled by Movera, no-show, failed, expired) arriving while a next trip was secured wrote the handoff to storage but only popped to Home. The next trip was stored but hidden, Home offered new trips, and accepting one then failed with an ownership error.
- After a failed rider-cancellation save, the only retry was a 4-second SnackBar.
- The driver saw raw wire names such as `Trip ended: cancelledByAdmin`.
- Waybills hard-coded `Movera partner vehicle` / `MVR 418`, and Profile hard-coded its vehicle text.

## Change

- `_leaveAfterAuthoritativeOutcome` is the shared exit for authoritative terminal projections. It stops timers, pauses GPS, discards the current waybill, shows a human outcome sheet, ends the trip in the session, and hands off to the secured next trip exactly like rider cancellation and driver completion.
- Unapplied terminal outcomes retry automatically with 1 s to 30 s backoff. The SnackBar keeps a **Retry now** action.
- `trip_outcome_sheet.dart` has driver copy for every terminal status, with no fee or payout claims.
- Home re-checks stored trip ownership when it becomes visible again (`didPopNext`), so a persisted handoff can never sit behind an available Home.
- Waybills and Profile read the vehicle from `LocalVehicleStore`; an unreadable store shows "Vehicle data unavailable".

## Validation

- `test/audit/trip_outcome_handoff_test.dart`: four outcomes with a secured next trip. Each shows the outcome sheet, hands off to trip B in storage, the session and the waybill, and archives A once.
- `test/audit/terminal_retry_test.dart`: two failed saves recover without user action.
