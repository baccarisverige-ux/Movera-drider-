# Routing provider

The Driver app requests road routes through `RouteRepository` (`RoadRouteService`, OSRM-compatible).

## Current state

- The default host is `router.project-osrm.org`, the public OSRM demo server. It is volunteer-run with no SLA, and its usage policy excludes production or heavy use.
- Each request sends the driver's live origin and the trip destination to that third party. This is a personal-data transfer and must be disclosed and covered by a processor agreement before production.
- Requests are throttled by `NavigationController` (no new request unless the vehicle moved 20 m or 8 s passed, plus a single outstanding reroute). Each request has an 8 s timeout. A routing failure never ends the trip; the UI shows "Route updating".

## Production requirement (decision pending)

Choose a contracted provider and set it at build time:

```
flutter build web --release --dart-define=MOVERA_ROUTING_HOST=routing.example.movera.se
```

Options: self-hosted OSRM or Valhalla, Movera backend proxy (preferred: hides the provider and adds auth and rate limits), Google Routes or Mapbox through a backend adapter. Before production:

1. Sign a data processing agreement and update the privacy notice (location data, purpose, retention, processor).
2. Point `MOVERA_ROUTING_HOST` at the contracted host and add a contract test against it.
3. Run an outage drill: a provider timeout must keep the trip usable.

This repository cannot sign agreements or create provider accounts, so the production host is not set here.
