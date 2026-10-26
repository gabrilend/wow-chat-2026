# 198 - Patch Notes

## Status
- Created: 2026-10-26
- Phase: 1
- Related: `docs/balance-updates.md` (the knobs log, one of the sources),
  `docs/patches/patch-registry.md` and `docs/profiles/basic.md` (what each
  install step and source patch does), the commit history, 155 (basic)
- Priority: Medium
- State: planned; open questions first

## Origin

The owner, 2026-10-26:

> Can we write a "patch notes" system that we keep continuously updated,
> in the style of World of Warcraft patch notes? It should be roughly as
> detailed as those.

## Current Behavior

There are no player-facing notes. What changed lives in three places, all
written for the people building the server: the commit history (every
change, in builders' words), `docs/balance-updates.md` (each knob turned,
with its value and why), and the issue files (each feature's design).
Nothing gathers them into what a player would read.

## Intended Behavior

- **Notes in Blizzard's shape, for each build the owner installs**: a
  heading with the build's date (and a name or number), then sections
  in the order World of Warcraft's notes use: General, Classes (one
  heading per class), Dungeons and Raids (one per instance or boss),
  Items, Professions, Quests and World, User Interface, Bug Fixes. Each
  entry one line, written for players: what changed and, where Blizzard
  would say it, the new number ("Doom Lord Kazzak now deals 60% less
  damage." "Greens and blues now drop twice as often from ordinary
  monsters.").
- **Kept continuously**: every change that reaches a player adds its
  line under the coming build ("Upcoming") as it is made, so the notes
  are written at the time the change is understood, not reconstructed
  later. Installing a build closes "Upcoming" under that build's date.
- **One source, two views**: the notes are a Markdown file in `docs/`
  (the data); an HTML page in `docs/HTML/` generated from it in the
  project's page style (the view), linked from the table of contents.
- **Checked**: a tool lists the changes since the last closed build that
  have no note yet (commits that touch what players meet: install steps,
  source patches, settings patches, Lua scripts), so nothing ships
  unannounced.

## Suggested Implementation Steps

1. `docs/patch-notes.md`: an "Upcoming" build at the top, sections as
   above; first filled from the work since the last build the owner
   installed (Kazzak, richer drops, no crushing blows, spirit's healing,
   the tabard rule ...), in players' words.
2. `scripts/generate-patch-notes-page`: the HTML page from the Markdown,
   every boss, item and class heading linked where the project has a
   page, in the project's style.
3. `scripts/check-patch-notes`: the commits since the last closed build
   that touch patches, settings, Lua or SQL, with no note naming their
   issue; run with the other checks.
4. A habit, written into CLAUDE.md's commit conventions: a change a
   player meets adds its line under "Upcoming" in the same commit.

## Open Questions

1. **Which profiles**: notes for basic only (the profile being played),
   or one set per profile?
2. **A build's name**: dates, version numbers (0.1, 0.2 ...), or names?
3. **Where players read them**: only the HTML page, or also in game (a
   book, a message at login when the build is new)?
