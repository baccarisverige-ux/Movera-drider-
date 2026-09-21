# Movera platform decisions (P1, P2, P4, D11)

Written 21 September 2026. These are the Week 0/1 product records from
*Movera Platform Audit & Work Plan*. They are not a backend and they do not
change Driver or Rider screens.

## P1 — Canonical vocabulary

| Concept | Canonical name | Notes |
|---|---|---|
| Trip identifier | `tripId` | Neutral to Rider `rideId` and Driver `offerId`/`tripId`. Rider rename is R4 (later). |
| Trip lifecycle | `TripStatus` | See enum below. Payment and rating are **not** trip states. |
| Currency code | `SEK` | ISO 4217. Minor units are öre integers. |
| Vehicle categories | `economy`, `comfort`, `premium`, `priority`, `xl`, `electric`, `pet` | Rider catalog ids. Admin's 3-value USD list must extend, not shrink this. |

### TripStatus

Happy path:

`draft → quoted → requested → searching → offered → accepted → driver_to_pickup → arrived → rider_onboard → in_trip → approaching_dropoff → completed`

Terminal:

`cancelled_by_rider` · `cancelled_by_driver` · `cancelled_by_admin` · `no_show` · `expired` · `failed`

Driver `ActiveRideStage` maps onto the live slice only:

| ActiveRideStage | TripStatus |
|---|---|
| `headingToPickup` | `driver_to_pickup` |
| `waitingForRider` | `arrived` |
| `onTrip` | `in_trip` |

### Separate machines (not TripStatus)

- **PaymentStatus:** `pending → authorized → captured`, plus `failed`, `refunded`
- **RatingStatus:** `pending → submitted → skipped`
- **DriverOnlineStatus:** `offline`, `going_online`, `online`, `on_trip`, `suspended`

## P2 — Market / currency

**SEK / Stockholm.** Rider and Driver already run this market. Admin's USD / New York sample data is placeholder and is replaced in A10. Named owner: Movera product (this record).

## P4 — State ownership

| State | Owner | Clients |
|---|---|---|
| Trip status | Backend | Rider, Driver, Admin receive projections |
| Driver availability | Backend | Driver sends intent; Admin may suspend |
| Fare | Backend | Clients display a quote; they do not invent totals |
| Payment status | Backend / PSP | Rider sees result; Driver sees payout implication |
| GPS | Driver device sends, backend stores | Rider/Admin receive a projection |
| Queued next trip | Backend (`GET /api/v1/drivers/:id/queue`) | Driver `WaybillRepository.next` is the local slot |

Until a backend exists, each app keeps its current mock, but **new code uses these names**.

## D11 — Online status after restart

A driver does **not** return online after a crash or cold start. Going online is an explicit action. `DriverSessionController.restore()` therefore stays offline even if the last in-memory write was online.

## Out of this record

P3 (`movera-contracts` OpenAPI) consumes this document. R3–R5 and D5 (full ActiveRideStage replacement) wait on this record and do not redesign screens.

D3 — `GeoPoint` is the domain type. `LatLng` conversion lives in `lib/core/geo/geo_point_maps.dart`. `RoadRoute.points` is `List<GeoPoint>`.

D4 — Driver, Vehicle, DriverDocument, and Earnings repositories exist under `lib/core/` as in-memory seams. Screens are not yet wired (no UX change).

D6 — `Money` stores öre integers and formats `104,80 kr`. Existing screen literals are unchanged until a later wiring pass.

