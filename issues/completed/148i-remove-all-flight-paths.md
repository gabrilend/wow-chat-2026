# 148i - Remove All Flight Paths from Vanilla

## Status
- Created: 2026-06-02
- **Completed: 2026-07-15** — Path B3+B1 implemented, applied, and
  verified live in `acore_world_vanilla`: the flightmaster flag is
  cleared on every creature (0 remain), and 69 hand-authored per-NPC
  flavor gossip lines cover every reachable Eastern Kingdoms + Kalimdor
  flight master. See "Current Behavior" below.
- Phase: 1 (Foundation — profile model)
- Parent: 148 (vanilla profile)
- Priority: Medium (defining ruleset feature, not a bug fix)

## Problem

Vanilla's design pairs an 80% movement-speed reduction (C003) with a
starting zone drop (Duskwood / Hillsbrad) and a starting level of 20.
The intent is a deliberate, smaller world where travel is meaningful
— you go somewhere because you decided to walk there, not because
you clicked a flight master and watched the camera fly.

Flight paths undermine that. A character at level 20 with a few
silver to spare can hop on a gryphon at the Darkshire flight master
and arrive at Stormwind in two minutes, then take another gryphon to
Ironforge, and from there to Menethil and the entire continental
flight network. The world collapses to a series of menu selections.

This ticket removes flight paths entirely from the vanilla server so
travel is exclusively on-foot, mounted, or by boat/zeppelin.

## Intended Behavior

- Flight master NPCs at every major city and outpost either no longer
  exist OR refuse to offer flight (decision below).
- The taxi UI does not appear when a player approaches what would
  have been a flight master.
- No flight node is "discoverable" — characters cannot accumulate
  flight points on their map.
- Boats (Menethil ↔ Theramore, Stormwind ↔ Auberdine, Booty Bay ↔
  Ratchet) and zeppelins (Orgrimmar ↔ Undercity / Grom'gol) remain
  functional. Cross-continent travel is preserved through these
  routes; only the in-continent gryphon/wyvern/bat network is gone.
- Mounts work normally. A level-20 character cannot yet ride mounts
  (mount learning at level 20 in WotLK; level 30 in classic), but
  once they level into mount eligibility, ground mounts work.
- Druid Travel Form and Shaman Ghost Wolf still work — they're not
  flight, they're class abilities.

## Current Behavior (implemented — Path B3 + B1)

Live in `acore_world_vanilla` and verified:

- **Flag cleared everywhere.** `UNIT_NPC_FLAG_FLIGHTMASTER` (8192) is
  stripped from every `creature_template` — 0 flightmasters retain it,
  so no taxi icon and no taxi UI appears anywhere, on any continent.
- **69 unique flavor lines.** Every reachable Eastern Kingdoms and
  Kalimdor flight master has its own two-sentence, location-and-
  personality-specific gossip line (`npc_text` + `gossip_menu` IDs
  90001–90069; the 90000–90999 range is reserved for this migration).
  Clicking a grounded master gives an in-world reason the wings are
  down instead of a dead click.
- **Menus actually open.** After the flag clear, the GOSSIP npcflag
  (bit 1) is re-set on exactly the masters that received a 90xxx menu,
  so the flavor text opens; masters with no line stay silent rather
  than throwing a per-NPC "gossip menu without GOSSIP flag" core warning.
- **Outland + Northrend:** flag cleared (defense-in-depth) but no
  dialogue authored — unreachable at the level-40 cap, a deliberate
  scope call.
- Boats, zeppelins, mounts, Travel Form, and Ghost Wolf are untouched,
  per the intended behavior above.

Migration: `sql/vanilla/db_world.src/03-remove-flight-paths.apply.sql`
(applied by the E008 patch via AC's UpdateFetcher; the revert is the
E008 unpatch heredoc).

## Two Implementation Paths

### Path A — Remove flight master NPCs entirely

Delete the flight master entries from `creature_template` (or set
their `creature` spawn count to zero so they don't appear in the
world). Players walking up to a flight master platform see an empty
platform.

**Pros:** Hard removal. No way for any player to ever invoke a
flight master.
**Cons:** Empty platforms look broken. Quests that reference flight
masters by NPC ID would orphan. Future re-enabling requires
re-spawning every NPC.

### Path B — Keep the NPCs, disable the taxi function

Modify the flight master NPCs' gossip or unit flags so they no
longer offer the "Take a taxi" interaction. Players see the NPC
but the interaction is either missing or replaced with flavor text
("The gryphons have flown south for the season").

**Pros:** World still looks populated. Reversible cleanly. Provides
narrative cover (the flight masters acknowledge the situation).
**Cons:** Players might keep clicking expecting flight; have to make
the gossip clear.

**Decided: Path B with per-NPC unique flavor gossip.** The world
stays populated, the design choice is legible to the player, and a
future profile can re-enable flight by reverting the gossip change.

Every flight master gets a **unique** two-sentences-maximum line of
dialogue, thematically appropriate to their location and personality.
Stormwind's flight master sounds different from Booty Bay's; Tarren
Mill's wyvern keeper sounds different from Thunder Bluff's. The
collected dialogue forms a small piece of incidental worldbuilding
— a player who visits every former flight platform learns the world
in small drips.

Examples of the tone (not literal text; the implementer writes
real lines):
- Stormwind: "By royal decree, the gryphons are grounded until
  further notice. His Majesty has not seen fit to share the why."
- Booty Bay: "Trade winds turned ugly last month and I haven't paid
  the wyverns since. Come back when there's silver in it for them."
- Thunder Bluff: "The wind speaks of bad omens to the south. The
  wyverns refuse the sky."

The implementer drafting the migration is responsible for writing
these lines — they're an artistic deliverable, not a mechanical one.
Take time on them. They're the last thing a player sees of the
flight system, and they should feel intentional.

## Mechanism

### Path B implementation sketch
- Identify the `Flight Master` NPC type: `gossip_menu_option` table
  rows where `OptionType = 4` (TAXIVENDOR per
  `Object/Creature/Creature.h`'s `GOSSIP_OPTION_TAXIVENDOR`).
- Either:
  - **(B1)** Replace those gossip options with a flavor-text gossip
    option that displays a message but does nothing, OR
  - **(B2)** Remove those gossip options entirely so the NPC has no
    interaction at all (the player sees them but can't click), OR
  - **(B3)** Clear the `npcflag` bit `UNIT_NPC_FLAG_FLIGHTMASTER`
    (value 0x2000) on every creature template that has it, so the
    yellow `!` taxi icon doesn't appear above their heads.

**Recommendation: B3 combined with B1.** Clear the flightmaster
flag (no more taxi icon) AND add a flavor gossip line so clicking
the NPC produces a brief in-world acknowledgement.

### File layout
Mirrors 148a and 148h: a vanilla-profile-only SQL migration.

- `sql/vanilla/03-remove-flight-paths.sql` — clears `UNIT_NPC_FLAG_FLIGHTMASTER`
  bit from all matching `creature_template` rows; inserts a unique
  flavor gossip line per flight master NPC (two sentences maximum
  per NPC, thematically appropriate to that NPC's location).

## Boats and Zeppelins

These are NOT touched. Cross-continent transit by boat and zeppelin
remains functional because:
- Cross-continent travel needs SOME mechanism, otherwise players are
  stranded on one continent.
- Boats and zeppelins are slow, on-rails, and atmospheric in a way
  flight paths are not. They preserve the "travel is meaningful"
  design intent.
- They are far less numerous than flight paths (~6 boats and ~3
  zeppelins across all of WoW) so they don't constitute a network
  that collapses the world.

## Mounts

Mounts are NOT touched. Once a player reaches the level at which
they can learn mount-riding (level 20 in WotLK; level 30 in classic
— check the active server's value), they can buy and use a mount
normally. Mounts are 60% faster than walking on the ground; combined
with the 80% movement reduction from C003, a mounted player travels
at roughly the same effective speed a stock un-mounted player would,
which feels appropriate for the deliberate-travel design.

## Implementation Steps (done)

1. ✅ `UNIT_NPC_FLAG_FLIGHTMASTER` = 0x2000 = 8192 confirmed.
2. ✅ Flag cleared across all `creature_template` rows via the apply
   migration.
3. ✅ `sql/vanilla/db_world.src/03-remove-flight-paths.apply.sql` written:
   the flag clear, the 90000-range idempotent cleanup, 69 per-NPC flavor
   `npc_text` + `gossip_menu` rows, and the GOSSIP-flag re-enable.
4. ✅ Applied via the E008 patch (`patch_E008_vanilla_remove_flight_paths`)
   + UpdateFetcher; verified live in `acore_world_vanilla`.
5. ⏳ In-client eyeball (folds into the 148o pass): a Stormwind flight
   master shows no taxi icon but gives the flavor line; the
   Menethil→Theramore boat still runs; Druid Travel Form still casts.

## Composition With Other Vanilla Decisions

- **C003 (80% movement)** — pairs naturally with this. Without flight,
  the slower base speed is the dominant pacing knob.
- **Starting zones (Duskwood / Hillsbrad)** — players begin in a
  zone they have to walk out of. Flight removal makes the starting
  zone matter.
- **40 level cap** — by the time a player reaches level 40 they've
  walked every road they'll ever walk. The cap and the no-flight
  rule together produce a small, well-known world.

## Open Questions

- **Should the NPCs eventually be repurposed?** Flight master models
  are evocative — they could be moved to flag duty (e.g. fishing
  hobbyist, town guard) instead of just standing on an empty
  platform. Out of scope for v1, but worth noting.
