# Phase 6 — Layout, visual consistency and accessibility

Status: screenshots and real assistive-technology execution pending.

Dependencies: agreed Driver visual target; completed functional states; physical devices for VoiceOver/TalkBack. Uploaded Movera Host pages are reference material, not Driver goldens.

## Matrix

| Target | Viewport/variation | Required surfaces | Evidence |
| --- | --- | --- | --- |
| Narrow phone | 320×568 and 320×700 | Home, offer, trip, forms, support, wallet/history | PENDING |
| Standard phones | 375×812, 390×844, 430×932 | Same plus overlays and navigation | PENDING |
| Tablet/desktop | 768×1024 and 1440×900 | Same plus maps/sidebar and keyboard navigation | PENDING |
| Landscape/keyboard | Device landscape; keyboard open; safe areas | Forms, contacts, search, chat, sheets | PENDING |
| Text scale | 1.0, 1.3 and 2.0 | All reachable controls and state messages | PENDING |
| Reduced motion | Enabled/disabled | Navigation, sheets, progress and camera | PENDING |
| Screen readers | VoiceOver and TalkBack | Labels, state, reading order, modal focus and announcements | PENDING |

## Checklist

- [ ] Record screenshots for loaded, empty, error and keyboard states.
- [ ] Validate touch targets, contrast, visible focus and keyboard activation.
- [ ] Verify modal focus entry/return and prevent obscured controls from receiving actions.
- [ ] Verify independent switch labels, current state, error announcements and enabled/disabled semantics.
- [ ] Check long translated labels and user text; ensure critical controls remain reachable.
- [ ] Preserve lazy conversation rendering and scroll ownership with a 1,000-message fixture.

## Exit gate

No unintended overflow or inaccessible action. Reading order and control semantics match behavior. Visual differences are compared with the documented Driver target and evidence is tied to the candidate commit.
