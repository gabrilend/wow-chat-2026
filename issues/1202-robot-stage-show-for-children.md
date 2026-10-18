# 1202 - The Robot Stage Show: Talking Robots Perform for Children

## Status
- Created: 2026-10-17
- Phase: 12 (Example products: the framework outside World of Warcraft)
- Parent of: 1202a, 1202b, 1202c, 1202d
- Blocked by: 916d (the model runner, llama.cpp) for the robots' words
- Related: 916 (the buddies' chat layer: personas, one-sentence replies
  held to a grammar), 916k (personas), 916l (the chat grammar and
  filter), `docs/roaming-pattern.md` (walking the stage), 506 (the
  gallery's design-and-vote loop, for the backdrops), 1201 (the other
  phase-12 example)
- Priority: Medium
- State: planned; open questions first

## Origin

Verbatim, 2026-10-17:

> also, can we have another one that's robots performing Freddy Fish
> like on a stage for children. the NPCs should talk using our
> buddy-bot LLM capabilities. We don't have to implement Freddy Fish
> story, just some backgrounds and such.

## Why This Exists

A second example of the framework outside World of Warcraft, showing a
different part of it from 1201: the buddies' **talking**. Small robot
performers on a stage, in the gentle, point-and-click spirit of the
1990s children's adventure games (Freddy Fish and its kin): painted
underwater and seaside scenes, characters who are kind and a little
silly, a child who clicks on things to see what happens. Not that game:
no story, characters, names, art or sounds from it or any other game.
The robots, their names and the backdrops are the project's own.

It also asks the hardest question the chat layer has faced: **what may
a model say to a child?** The answer has to be built into the design
(1202c), not added afterwards.

## Current Behavior

Nothing exists. The buddies' chat layer (916) is designed, not built;
its model runner (916d) runs llama.cpp in the game server, beside it, or
in the custom client. Nothing in the project is made for children.

## Intended Behavior

A small program shows a toy theatre: a stage with a painted backdrop, a
curtain, and three or four robot performers.

- **Scenes, not a story** (1202a): a handful of backdrops (a reef, a
  harbour, a sunken ship, a starry night), changed between acts like
  painted flats. Each scene has a few things a child can click (a shell,
  a lamp, a sleepy crab).
- **Robots who move about the stage** (1202b) by the roaming pattern,
  the stage being its area: they wander, gather round what was clicked,
  and step aside for each other.
- **Robots who talk** (1202c), each with a persona (916k's persona seed,
  written for this cast: the curious one, the worried one, the one who
  tells jokes), in one short sentence at a time, out loud and as a
  caption, by the buddies' chat layer and its grammar, under rules made
  for children.
- **Small hands, no typing** (1202d): everything is a click or a tap.
  The child never types and is never asked anything about themselves.

### Sub-issues

| ID | Name | Dependencies | Description |
|----|------|--------------|-------------|
| 1202a | stage-and-backdrops | None | The theatre, the scenes and their clickable things, made by the project's own asset loop |
| 1202b | performers-walk-the-stage | None | The roaming pattern with the stage as its area, in the program's language |
| 1202c | robots-speak-kindly | 916d | The chat layer for children: personas, a word list, a grammar, a filter, speech |
| 1202d | clicks-for-small-hands | 1202a, 1202b, 1202c | What a click does: the robots' reaction, an act's flow, the demo |

Execution order: `1202a ‖ 1202b ‖ 1202c → 1202d`.

## Suggested Implementation Steps

1. Answer the open questions.
2. 1202a, 1202b and 1202c apart; each checkable alone.
3. 1202d joins them into one act on one backdrop, then the rest.
4. A demo receipt: an unattended run with scripted clicks
   (`--click SECONDS X Y`, the house pattern) writes `output/goodbye`
   (seed, clicks, lines spoken, lines refused by the filter, minutes)
   and screenshots into `development-history/`.

## Related Issues

- 916, 916d, 916k, 916l: the chat layer this uses
- `docs/roaming-pattern.md`: the walking
- 506: the design-and-vote loop for generated assets
- 1201: the other example product of phase 12

## Open Questions

1. **What runs it?** Proposed: a web page, like the project's other
   playable pages (the gallery's roaming scenes already run the roaming
   pattern in JavaScript, `docs/HTML/buddy-roaming/roam-pattern.js`),
   with the model behind a local `llama-server` (916d's "beside") and
   the browser's own speech for the voices. The other choice is the W
   custom client (C), as a new mode beside World of Warcraft and Warcraft
   III maps. The page is far quicker; the client shows more of the
   framework.
2. **Who is it for?** Ages (3-5 and 6-8 want different words and
   pacing), and where: at home on a parent's computer, or a kiosk?
3. **Voices.** The browser's speech voices differ by machine and some
   sound harsh to small children; a local speech model would be steady
   but is another download. Captions always, voices optional?
4. **Should the model run live at all?** A middle way: the model writes
   many lines ahead of time, a person reads and approves them, and the
   show only ever says approved lines. Safest for children, at the cost
   of surprise (1202c).
