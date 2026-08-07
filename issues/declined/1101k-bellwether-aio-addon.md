# 1101k - The Bellwether Addon (AIO Client Half)

## Status
- Created: 2026-08-01
- Parent: Issue 1101 (Bellwether — attended play)
- Phase: 11
- Priority: Medium
- Depends on: 1101j (the interface contract), AIO

## Overview

The in-client half. Two jobs, and they point in opposite directions:

1. **An interface** — the panel a player uses when they're at the screen
   but not driving: the family, what each ward is doing, the utterance
   log, and the controls for guiding them.
2. **A sensor** — the client sees things the server doesn't bother to
   assemble. Combat log text, emotes, quest text, what's on screen.
   These are facts the server-side reader in 1101b can't get cheaply.

The request called this whole feature "an addon." It's more than an
addon, but the addon is the part the player actually touches when
they're present, and it's the part that makes attendance and play the
same system rather than two.

## Current Behavior

AIO is installed. Issue 616 specifies a public healer frames addon and
carries the research this will need — in particular the SecureActionButton
and combat-lockdown constraints on what an addon may do during combat.

No Bellwether addon exists.

## Intended Behavior

### The panel

| Element | Shows |
|---------|-------|
| Family roster | every ward: name, level, health, where, what they're doing |
| Utterance log | the last N utterances, timestamped, grouped by ward |
| Guidance box | free text in, plus the fast buttons below |
| Standing orders | what each ward is currently under, editable |
| Pipeline status | attached interfaces, cluster health, fallback rate |

The pipeline status row exists for the same reason 1101f reports
pipeline failures as alarms: a player must always be able to tell
"nothing is happening" from "nothing is working."

### The fast buttons

Guidance at its lowest altitude, one click: *regroup*, *back off*,
*push*, *rest*, *follow me*, *hold here*. These map to the same
directive vocabulary as typed guidance (1101l) — they are shortcuts into
it, not a second system.

Combat lockdown constrains what a click may do mid-combat. Nothing here
casts a spell on the player's behalf, so most of the lockdown problem
that issue 616 wrestles with doesn't apply — but confirm that rather
than assume it.

### The sensor half

Client-only facts worth capturing:

- Combat log lines that carry causality the server-side reader would
  have to reconstruct
- Emotes and chat from wards, including anything mod-soren-chat has
  them say — a ward that speaks in-world should be able to appear in
  the attended feed
- Quest text and objectives, which the server knows but not in
  presentable form
- What the player is looking at, when they're at the screen

These flow back over AIO and enter the fact extractor (1101c) as another
source, on the same fact contract as everything else.

### The handoff

The player sits down mid-session. The panel appears, the speech
interface detaches or drops to a whisper, the utterance rate rises
because their attention is higher. They stand up; it reverses. Attended
and played should be a dial, not a switch — and the dial is the
`attention` port from 1101j.

## Implementation Steps

1. AIO addon skeleton: registers, receives a message from the server,
   draws a frame. Confirm the round trip before building anything.
2. Family roster panel, fed by a periodic server push of the same
   snapshots 1101b already collects. Do not build a second reader.
3. Utterance log, fed through the panel interface sub-map from 1101j.
4. Guidance box and fast buttons, emitting on the sub-map's `guidance`
   port.
5. Standing-order display and edit.
6. Pipeline status row.
7. The sensor half: combat log and ward chat capture, sent server-ward,
   entering 1101c as facts.
8. The attention handoff, driven by whether the panel is open and
   whether the player has moved recently.
9. Test with the client closed entirely — every part of the feature that
   doesn't need the panel must keep working, or the "addon" framing has
   quietly become a requirement.

## Files to Create

- The AIO addon (client Lua)
- The server-side AIO handler
- `docs/addons/bellwether-panel.md`, alongside the existing addon docs,
  added to the table of contents

## Open Questions

- How much of this duplicates issue 616's healer frames? Both draw a
  roster of units with health bars fed by server pushes. If 616 lands
  first, is this a mode of that addon rather than a second one?
- Does the sensor half create a trust problem? Facts sourced from the
  client are facts the server didn't verify. For a single-player family
  on a private server this is academic — but the fact contract in 1101c
  says facts are true, and a client-sourced fact is only as true as the
  client.
- What happens to the panel when the player is attending a family they
  are not logged in near — or at all? The panel is client-side; the
  family may be across the world. It shows what the server pushes,
  which is everything, which is more than the client would normally know.
- Should the addon work when the pipeline is down entirely — as a plain
  family-status panel with no narration? Probably yes, and that makes it
  useful on its own before any of this ships.
- Is the anchor character from 1101a the one running this addon, and
  does that couple the panel to the anchor's presence?

## Related

- Parent: [1101 - Bellwether](1101-bellwether-attended-play.md)
- [616 - Public healer frames addon](616-public-healer-frames-addon.md)
  — the AIO precedent, the roster-of-units problem, and the
  SecureActionButton / combat-lockdown research
- [1101j - Interfaces as sub-maps](1101j-interfaces-as-submaps.md) —
  the panel is one interface among several
- [1101b - Ward state reader](1101b-ward-state-reader.md) — the roster
  data source; do not duplicate it
- [916l - Chat emission and rate limit](916l-chat-emission-and-rate-limit.md)
  — ward speech that the sensor half should pick up
- `docs/addons/public-healer-api.md` — the existing AIO API shape
</content>
