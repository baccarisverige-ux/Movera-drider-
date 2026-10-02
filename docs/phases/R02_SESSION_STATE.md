# R02 - Availability state machine and logout

Source: deep re-audit of 2 October 2026 (N03, N12; residuals of F15, F17).

## Problem

`stayOnlineAfterTrip()` always set the driver online when a trip ended. A suspension issued during a trip was undone by finishing the trip. A trip restored while the driver was offline put the driver back into dispatch. Logout cleared storage outside the repositories' serial queues and left the waybill singleton and demo dispatch state in memory.

## Change

| Before trip | During trip | After trip |
| --- | --- | --- |
| online | - | online |
| offline (restored trip) | - | offline |
| any | suspend | suspended |
| suspended | - | suspended |
| online | go offline | offline |
| online | go offline, then online | online |

- `endTrip()` applies this table. `stayOnlineAfterTrip()` delegates to it so existing call sites are unchanged.
- During a trip, `setOnline(false)` records "go offline after this trip" instead of being ignored.
- `DriverRuntimeScope.logout` is an app-level command. It waits for the active-ride, journal and settings queues to settle, clears local data, resets waybills and demo dispatch, then resets the session. Profile shows an error and stays signed in if clearing fails.

## Validation

`test/core/session_state_machine_test.dart` covers each table row plus queued trips, reset and dispatch reset.
