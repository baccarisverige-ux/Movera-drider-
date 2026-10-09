# Status, dispatch and support lifecycle follow-up

Base: PR #234, commit `5082cb0d6537d9e32f526bf67c486af8d35e356d`. Four additional frontend defects; earlier findings are not counted again.

| ID | Trigger and failure | Correction | Regressions |
| --- | --- | --- | --- |
| S01 | Create a dispatch watch stream, then subscribe after the creation microtask; the initial broadcast snapshot is lost. Reusing a stream for another listener also lacks an initial snapshot, and creating another watch broadcasts replay to existing listeners. | Each subscription receives its own current immutable snapshot and remains subscribed to subsequent updates. Schedule demo events when a live subscription starts. | Delayed filtered listener after a claim, independent subscriber replay with later updates, delayed/repeated next-trip listeners. |
| S02 | Call watchNearbyOffers after disposing the demo repository; two new timers start despite closed streams. | Disposed subscriptions close immediately and never start demo scheduling. | Both watch streams close, emit nothing and create no timers. |
| S03 | Touch the trip island during a GPS or routing fault, or receive a fault while default controls are temporarily showing; the controls mask the warning. | Fault status always takes priority over the temporary default face. Clear the previous reveal when a new fault arrives. | Touch during a GPS fault; rerouting banner overrides revealed controls and explicit touch works again after recovery. |
| S04 | A retained support reply callback runs after another route covers the conversation or after the conversation is disposed. It can persist a hidden reply or attempt setState after disposal. | Require a mounted, current route before accessing the editor or mutating the ticket. | Covered callback makes no write and preserves text; current route saves normally; disposed callback makes no write or exception. |

Eight regressions in `test/core/status_dispatch_followup_test.dart` and `test/widget/support_reply_route_ownership_test.dart`. The isolated Dart dispatch harness failed both S01 and S02 before the changes and passed afterward. Full Flutter analysis/tests and platform builds are checked by repository CI. No backend or deployment changes; physical-device testing is outside this run.

This PR is stacked on #234, which is stacked on #233. Merge #233, then #234, then this follow-up, retargeting each successor to main after its predecessor lands.
