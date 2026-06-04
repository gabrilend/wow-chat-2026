# 148c - Add mod-quest-status to Vanilla — DECLINED

## Status
- Created: 2026-06-01
- **Decision: Declined 2026-06-02.** Vanilla ships without quest
  marker overlays. Players read quest text and use the in-game map
  to find objectives — the slower exploration matches the ruleset's
  intent. Revisit if play-testing shows the friction is acute.
- Phase: 1 (Foundation — profile model)
- Parent: 148 (vanilla profile)
- Priority: N/A (declined)

## Problem

Vanilla-style WotLK questing relies on the player reading quest text
to figure out what to kill and where. The base 3.3.5a client has no
"objective marker" overlay on creatures and objects that satisfy an
active quest. Modern WoW conditioned players to expect those markers;
without them, even players who enjoy the slower pace can lose ten
minutes per quest finding the right wolf among twelve visually-identical
wolves.

mod-quest-status puts an icon (typically a yellow `!` or `?` style
glyph) over the head of NPCs and over interactable objects that
contribute to a quest the player currently has. Stops short of
wholesale waypoint helpers — the player still has to walk to the area
on their own.

## Intended Behavior

On a vanilla server, a player with an active "kill 10 wolves" quest
sees a marker over the correct wolves. The marker disappears once the
objective is satisfied or the quest is turned in. Markers do not
appear for quests the player has not accepted.

The same applies to "click the lever" / "collect 5 herbs" style quest
objects.

## Module Details

- **Upstream:** `https://github.com/azerothcore/mod-quest-status` (or
  whichever fork is current — verify at install time; the AzerothCore
  module ecosystem has several similar modules under slightly
  different names).
- **Configuration:** marker style and visibility radius are typically
  configurable. Defaults are reasonable; revisit only if play-testing
  shows them ugly or intrusive.
- **Compatibility:** standalone module, no known conflicts.

## Implementation Steps

1. Identify the canonical / best-maintained quest-status module in
   the AzerothCore ecosystem (the upstream URL above is a starting
   guess; confirm at install time).
2. Add it to `PROFILE_MODULES["vanilla"]` in `scripts/install`.
3. Add the upstream URL to `MODULE_REPOS`.
4. Drop the module's config file into vanilla's `etc/modules/`
   overlay; keep defaults unless play-testing motivates a change.
5. Rebuild vanilla via `scripts/install --profile vanilla`.
6. In-game test: pick up a basic kill-quest, confirm markers appear
   on the correct creatures, confirm they disappear after objective
   completion.

## Open Questions

- Several similar modules exist (different names, different authors).
  Which one is best-maintained as of installation?
- Does the marker render correctly through the 3.3.5a client without
  needing a client-side patch? (Most server-side overhead icons use
  the existing quest-giver glyph system, which the client already
  knows how to draw — so probably yes.)
