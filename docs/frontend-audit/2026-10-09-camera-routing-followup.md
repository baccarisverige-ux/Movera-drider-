# Camera and routing lifecycle follow-up

This follow-up starts from PR #233 (`ef0f5b5a41aa73502e9447a0b4238b7fe7b3111d`). The six findings below are additional defects; the prior 30 fixes are not counted again. Scope is frontend navigation and routing client lifecycle only.

| ID | Reproduction and previous failure | Fix | Regression |
| --- | --- | --- | --- |
| C01 | GPS moves off the requested road while the route request is pending. The response rebuild attempts to schedule a reroute while the request lane is busy; no timer remains after completion. | Schedule recovery after releasing the successful request lane when the current snapshot is off route. | Off-route response starts a second request after two seconds without another GPS event. |
| C02 | Waiting retains the navigating flag. After a waiting overview, starting guidance leaves the camera in overview because navigating did not change. | Treat leaving waiting as entering guidance. | Following resumes with the 900 ms entry framing. |
| C03 | A map animation stalls while another GPS pose queues. When it finishes after GPS expiry, the queued movement still runs. | Check current fix freshness before dispatching queued movement. | Expired movement is dropped; a new fresh fix resumes movement. |
| C04 | The same map port is attached twice. The second attachment disposes the port before storing it again. | Make attachment of the current port idempotent. | Duplicate attachment does not dispose; controller disposal disposes once. |
| C05 | A disposed service with a borrowed HTTP client can still send requests and accept an already pending response. | Reject requests and completed responses after service disposal, preserving borrowed client ownership. | New request sends nothing; late valid response is rejected; borrowed client remains usable. |
| C06 | A replacement route retains its geometry but corrects upcoming maneuver locations. The old instruction hint skips the corrected turn. | Reset instruction progress when maneuver definitions change, retaining road progress. | Corrected upcoming turn receives the turn-preview zoom and tilt. |

Regression coverage: `test/core/camera_routing_followup_test.dart` (seven tests; two manifestations of C05). The four camera reproductions also passed using an isolated Dart harness before publication. Flutter analysis, full test coverage and platform builds are verified through repository CI; physical-device verification is outside this run.

Merge order: PR #233 first, then retarget this stacked follow-up to main. Do not merge this follow-up ahead of its base.
