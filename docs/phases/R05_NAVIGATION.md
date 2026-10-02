# R05 - Monotonic route progress and configurable routing host

Source: deep re-audit of 2 October 2026 (N17; N07 partially; residual of F05).

## Route progress

- Progress keeps a cursor (`alongMeters`). Each fix is first matched within a window from 60 m behind to 400 m ahead of the previous progress. If no road segment within 50 m falls inside that window, the whole route is searched, so rejoining after a tunnel or reroute still works.
- When two passes of the same road are equally close (U-turns, loops, out-and-back), the forward pass wins.
- Segment lengths and maneuver positions are computed once per route (`Expando` cache). Maneuvers are resolved in route order, so an arrival at the route start is placed at the end, not at 0 m.
- `passedManeuverMeters` is now the threshold actually used, at its previous effective value of 4 m.

## Routing provider

`RoadRouteService` reads `MOVERA_ROUTING_HOST`. The default is still the public OSRM demo server, so demo behaviour is unchanged. See `docs/ROUTING_PROVIDER.md` for why production must change it. Choosing and contracting a provider (DPA, privacy notice) is a business action and is **not** done in this pull request; N07 stays open until it is.

## Validation

`test/core/route_progress_monotonic_test.dart`: out-and-back with arrival at the start, monotonic return leg, rejoin outside the window, a 2,000-point route performance bound, and configurable host. Existing navigation tests are unchanged.
