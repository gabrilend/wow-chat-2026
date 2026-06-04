# 148d - Add mod-zone-difficulty to Vanilla — DECLINED

## Status
- Created: 2026-06-01
- **Decision: Declined 2026-06-02.** Uldaman's default tuning stands.
  Vanilla v1 ships without per-zone HP/damage multipliers; the
  endgame dungeon plays at its stock level-band difficulty. Revisit
  if play-testing shows Uldaman feels trivial.
- Phase: 1 (Foundation — profile model)
- Parent: 148 (vanilla profile)
- Priority: N/A (declined)

## Mechanism (recorded for future reference)

If this is reconsidered, mod-zone-difficulty works by hooking
creature stat queries: when a creature spawns or has its HP/damage
computed, the module looks up the creature's zone in a config table
mapping zone IDs to multiplier records, then scales the base values.
Config lives in `etc/modules/mod-zone-difficulty.conf` as plain text
and is reloadable via the worldserver `.reload config` command — so
retuning is hot, no rebuild needed. The hook surface is small and
profile-scoped via the standard module config system.

## Problem

Uldaman is vanilla's endgame dungeon, but in unmodded WotLK Uldaman
is a level 35-45 leveling instance designed to be killed by a normal
party of five appropriately-levelled characters in ~45 minutes. Once
a vanilla player and their playerbot group hit the level-40 cap and
gear up a little, Uldaman becomes trivial — the very thing it's
supposed to be the climactic experience of.

mod-zone-difficulty lets per-zone HP and damage multipliers be applied
to creatures. The endgame zone(s) can be retuned to feel like the
final challenge without changing the dungeon's level band or content.

## Intended Behavior

- Uldaman creatures (and any other zones designated "endgame") have
  HP and damage scaled up by configurable multipliers. Defaults
  proposed: HP ×2.5, damage ×1.5. To be tuned by play-testing.
- Non-endgame zones are left at vanilla multipliers (×1).
- The scaling is per-zone-ID, so a zone can be marked endgame or not
  by editing a config file; no source rebuild required to retune.

## Module Details

- **Upstream:** `https://github.com/azerothcore/mod-zone-difficulty` (or
  current best-maintained equivalent; verify at install time).
- **Configuration:** typically a config file maps zone IDs to multiplier
  sets. Uldaman's zone ID needs to be looked up and pinned in the
  config.
- **Compatibility:** standalone; no known conflict with the other
  vanilla modules.

## Intersections With Other Vanilla Decisions

- **Level cap of 40.** The scaling applies on top of vanilla creature
  stats. A level-40 Uldaman boss scaled ×2.5 HP is still a level-40
  boss for purposes of XP, loot tables, and aggro mechanics — just
  with more meat.
- **Playerbot groups.** Bot DPS scales with their gear and AI tuning,
  not with the zone multipliers. Heavier zone tuning may need
  corresponding playerbot config adjustments (party-level scaling,
  bot iLvl floor) to keep difficulty consistent across bot quality.
  Out of scope for this ticket; flag for later.

## Implementation Steps

1. Add `mod-zone-difficulty` to `PROFILE_MODULES["vanilla"]` in
   `scripts/install`.
2. Add the upstream URL to `MODULE_REPOS`.
3. Look up Uldaman's zone ID (and any sub-zones inside the instance
   if the module distinguishes them).
4. Draft a starter config: Uldaman set to HP ×2.5 / damage ×1.5;
   everything else at ×1.
5. Drop the config into vanilla's `etc/modules/` overlay.
6. Rebuild vanilla via `scripts/install --profile vanilla`.
7. Play-test: clear Uldaman with a level-40 character + four playerbots.
   Note time-to-clear, deaths per attempt, and overall feel.
8. Iterate on the multipliers based on play-test feedback.

## Open Questions

- What are the right starter multipliers? The ×2.5 / ×1.5 above is a
  guess; could be way off depending on bot quality and gear curves.
- Should sub-bosses scale differently from trash? Some zone-difficulty
  modules support per-creature-type scaling within a zone; if this one
  does, use it.
- Are there other zones beyond Uldaman that should be marked endgame?
  (Razorfen Downs? The Stockade at the high end? Decide as the
  ruleset matures.)
