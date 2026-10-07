# Driver island state mapping

The 100 concepts are examples of reusable data-driven states, not a slideshow or 100 pages. Core selection lives in `lib/core/island/trip_island_controller.dart`; camera and trip lifecycle remain independent. Renderer uses the default displayed height (40.32 logical px), default width195.2 and maximum224.48 (+15%). Text has symmetric24px icon slots with6px gaps; only the left slot carries a sign, inside the capsule. Waiting lane is activity, not route completion. Default face returns to live information after two idle seconds. Reduced motion disables rolling digits and the lane sweep.

Priority: persistent route/location faults; active real turn instead of arrival proximity; short confirmed transition/recovery messages when they do not obscure a maneuver; waiting timer/name cycle; arrival approach; ordinary guidance. GPS proximity says Near pickup/stop/destination, never confirms arrival. Confirmed pickup arrival starts waiting. Pickup paid clock subtracts120 included seconds; stop waiting is paid from its start, retaining the current existing policy. Completion is shown only after the existing completion journal/lifecycle succeeds.

The following concept IDs are data/acknowledgment dependent and remain inactive:33 rider-notification delivery;40 incoming chat (no production chat event);41 a meeting-point update notification;42 rider proximity;54–55 lane metadata;59–61 tunnel metadata;73–74 live traffic/delay;82 explicit rider-ready signal. Existing editing/communication controls remain available. Do not invent those confirmations. Gentle bends57–58 use available slight-turn instructions; no extra fabricated road condition is emitted. Home retains its existing offer/status sources and has capped message width and non-overshooting resize; it is not a new offer workflow.

| Concept | Example | Source / condition |
|---|---|---|
| 01 | Default · 120 kr | Existing Home offer/availability/Radar data |
| 02 | Available for rides | Existing Home offer/availability/Radar data |
| 03 | Radar active | Existing Home offer/availability/Radar data |
| 04 | Searching nearby | Existing Home offer/availability/Radar data |
| 05 | New ride request | Existing Home offer/availability/Radar data |
| 06 | Pickup · 3 min | Existing Home offer/availability/Radar data |
| 07 | Angelica · 4.8 ★ | Existing Home offer/availability/Radar data |
| 08 | Ride accepted | Successful offer acceptance |
| 09 | Preparing route | Route loading/usable pickup route |
| 10 | Toward pickup · 1.4 km | Route loading/usable pickup route |
| 11 | Continue ahead · 800 m | Current route instruction and measured remaining distance |
| 12 | Keep right · 500 m | Current route instruction and measured remaining distance |
| 13 | Turn right · 180 m | Current route instruction and measured remaining distance |
| 14 | Continue · 300 m | Current route instruction and measured remaining distance |
| 15 | Turn left · 120 m | Current route instruction and measured remaining distance |
| 16 | Roundabout · 1st exit | Current route instruction and measured remaining distance |
| 17 | Roundabout · 2nd exit | Current route instruction and measured remaining distance |
| 18 | Roundabout · 3rd exit | Current route instruction and measured remaining distance |
| 19 | Roundabout · 4th exit | Current route instruction and measured remaining distance |
| 20 | Take exit · 200 m | Current route instruction and measured remaining distance |
| 21 | Keep left · 300 m | Current route instruction and measured remaining distance |
| 22 | Merge right · 250 m | Current route instruction and measured remaining distance |
| 23 | U-turn · 100 m | Current route instruction and measured remaining distance |
| 24 | Pickup ahead · 150 m | Fresh pickup proximity, without hiding a turn |
| 25 | Arriving soon · 50 m | Fresh pickup proximity, without hiding a turn |
| 26 | Arrived at pickup | Confirmed pickup arrival |
| 27 | Waiting begins · 00:00 | Persisted pickup timer or real rider-on-the-way event |
| 28 | Waiting time · 00:15 | Persisted pickup timer or real rider-on-the-way event |
| 29 | Waiting time · 00:30 | Persisted pickup timer or real rider-on-the-way event |
| 30 | Waiting time · 00:45 | Persisted pickup timer or real rider-on-the-way event |
| 31 | Waiting time · 01:00 | Persisted pickup timer or real rider-on-the-way event |
| 32 | Waiting for Angelica | Persisted pickup timer or real rider-on-the-way event |
| 33 | Rider notified | Inactive until a truthful data/acknowledgment source exists |
| 34 | Rider is coming | Persisted pickup timer or real rider-on-the-way event |
| 35 | Waiting time · 01:30 | Persisted pickup timer or real rider-on-the-way event |
| 36 | Waiting time · 02:00 | Persisted pickup timer or real rider-on-the-way event |
| 37 | Paid wait · 00:15 | Persisted pickup timer or real rider-on-the-way event |
| 38 | Paid wait · 00:45 | Persisted pickup timer or real rider-on-the-way event |
| 39 | Paid wait · 01:15 | Persisted pickup timer or real rider-on-the-way event |
| 40 | Message received | Inactive until a truthful data/acknowledgment source exists |
| 41 | Meeting point updated | Inactive until a truthful data/acknowledgment source exists |
| 42 | Rider nearby | Inactive until a truthful data/acknowledgment source exists |
| 43 | Rider on board | Successful trip start and next route leg |
| 44 | Confirm pickup | Successful trip start and next route leg |
| 45 | Trip started | Successful trip start and next route leg |
| 46 | Preparing destination | Successful trip start and next route leg |
| 47 | Toward destination · 8 km | Successful trip start and next route leg |
| 48 | Continue ahead · 1 km | Successful trip start and next route leg |
| 49 | Turn right · 400 m | Successful trip start and next route leg |
| 50 | Keep left · E4 | Successful trip start and next route leg |
| 51 | Join E4 · 300 m | Actual current route instruction; optional metadata only if present |
| 52 | Merge onto highway | Actual current route instruction; optional metadata only if present |
| 53 | Continue · 4.5 km | Actual current route instruction; optional metadata only if present |
| 54 | Stay in left lane | Inactive until a truthful data/acknowledgment source exists |
| 55 | Stay in right lane | Inactive until a truthful data/acknowledgment source exists |
| 56 | Keep straight · 2 km | Actual current route instruction; optional metadata only if present |
| 57 | Gentle right bend | Actual current route instruction; optional metadata only if present |
| 58 | Gentle left bend | Actual current route instruction; optional metadata only if present |
| 59 | Tunnel ahead · 500 m | Inactive until a truthful data/acknowledgment source exists |
| 60 | Through tunnel | Inactive until a truthful data/acknowledgment source exists |
| 61 | Exit tunnel · 200 m | Inactive until a truthful data/acknowledgment source exists |
| 62 | Exit right · 800 m | Actual current route instruction; optional metadata only if present |
| 63 | Exit right · 300 m | Actual current route instruction; optional metadata only if present |
| 64 | Take ramp · 150 m | Actual current route instruction; optional metadata only if present |
| 65 | Turn left · 250 m | Actual current route instruction; optional metadata only if present |
| 66 | Roundabout · 2nd exit | Actual current route instruction; optional metadata only if present |
| 67 | Roundabout · 3rd exit | Actual current route instruction; optional metadata only if present |
| 68 | Route updated | Navigation route/location state and recovery |
| 69 | Recalculating route | Navigation route/location state and recovery |
| 70 | New route ready | Navigation route/location state and recovery |
| 71 | GPS signal weak | Navigation route/location state and recovery |
| 72 | GPS restored | Navigation route/location state and recovery |
| 73 | Traffic ahead | Inactive until a truthful data/acknowledgment source exists |
| 74 | Delay · 2 min | Inactive until a truthful data/acknowledgment source exists |
| 75 | Continue · 1.2 km | Current route instruction |
| 76 | Stop 1 ahead · 300 m | Current stop cursor, confirmed arrival/continuation, persisted waiting timer or final route leg |
| 77 | Arriving at stop 1 | Current stop cursor, confirmed arrival/continuation, persisted waiting timer or final route leg |
| 78 | Arrived at stop 1 | Current stop cursor, confirmed arrival/continuation, persisted waiting timer or final route leg |
| 79 | Stop wait · 00:00 | Current stop cursor, confirmed arrival/continuation, persisted waiting timer or final route leg |
| 80 | Stop wait · 00:45 | Current stop cursor, confirmed arrival/continuation, persisted waiting timer or final route leg |
| 81 | Waiting at stop 1 | Current stop cursor, confirmed arrival/continuation, persisted waiting timer or final route leg |
| 82 | Rider ready | Inactive until a truthful data/acknowledgment source exists |
| 83 | Continue to stop 2 | Current stop cursor, confirmed arrival/continuation, persisted waiting timer or final route leg |
| 84 | Turn right · 200 m | Current stop cursor, confirmed arrival/continuation, persisted waiting timer or final route leg |
| 85 | Arriving at stop 2 | Current stop cursor, confirmed arrival/continuation, persisted waiting timer or final route leg |
| 86 | Arrived at stop 2 | Current stop cursor, confirmed arrival/continuation, persisted waiting timer or final route leg |
| 87 | Stop wait · 01:20 | Current stop cursor, confirmed arrival/continuation, persisted waiting timer or final route leg |
| 88 | Waiting at stop 2 | Current stop cursor, confirmed arrival/continuation, persisted waiting timer or final route leg |
| 89 | Continue to destination | Current stop cursor, confirmed arrival/continuation, persisted waiting timer or final route leg |
| 90 | Destination · 700 m | Current stop cursor, confirmed arrival/continuation, persisted waiting timer or final route leg |
| 91 | Keep right · 250 m | Current stop cursor, confirmed arrival/continuation, persisted waiting timer or final route leg |
| 92 | Turn right · Storgatan | Current stop cursor, confirmed arrival/continuation, persisted waiting timer or final route leg |
| 93 | Drop-off ahead · 100 m | Current stop cursor, confirmed arrival/continuation, persisted waiting timer or final route leg |
| 94 | Arriving soon · 50 m | Current stop cursor, confirmed arrival/continuation, persisted waiting timer or final route leg |
| 95 | Arrived at destination | Confirmed completion, completion journal, rating view and next-trip handoff |
| 96 | Confirm drop-off | Confirmed completion, completion journal, rating view and next-trip handoff |
| 97 | Trip completed | Confirmed completion, completion journal, rating view and next-trip handoff |
| 98 | Rate rider | Confirmed completion, completion journal, rating view and next-trip handoff |
| 99 | Trip saved | Confirmed completion, completion journal, rating view and next-trip handoff |
| 100 | Ready for next trip | Confirmed completion, completion journal, rating view and next-trip handoff |

