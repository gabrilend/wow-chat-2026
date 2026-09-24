# 155f - Outland Dungeons at Level 64

## Status
- Created: 2026-09-23 (drafted as "early-outland-heroics-at-64", then
  "early-outland-dungeons-at-64", briefly "reachable-outland-at-64"; settled
  the same day, see Origin)
- Phase: 1
- Parent: 155
- Blocked by: 155a; pairs with the accuracy cap (B005) in 155c
- Priority: Medium

## Origin

Verbatim, 2026-09-23, in order:

> oh and since the early Outland dungeons give blues, let's tune them higher
> (level 64) as a "heroic" mode. Also let's implement the patch that removes
> the accuracy penalty for level gaps.

> it's not actually a heroic dungeon. The regular dungeons are simply
> increased in difficulty. The monsters are set to level 64 and given
> appropriate damage / health values and such. The loot stays the same, so a
> level 58 can't get hardcore blues - they need to quest or farm mobs to get
> the greens and blues and epics that compare to the dungeon loot. They could
> of course also do vanilla content but Outland is an option. The dungeons are
> supposed to be as hard as raids or whatever.

On scripted creatures: "yes". On which dungeons:

> anything in Outland that can be reached by a level 60 should be scaled to
> level 64.

And, correcting a reading of that as the whole of Outland:

> oh, um, no, the open world remains at the default levels. Just the dungeons
> are modified.

> quests and creatures should be the default level. Only dungeons are
> affected.

## Current Behavior

**Built 2026-09-23; tested against a throwaway RAM database** (`scripts/test-basic-sql-in-ram`: stock databases brought fully up to date, then apply, re-apply, revert, apply; all checks pass). It raises 220 templates across the nine dungeons, e.g. Vazruden, Nazan and Omor in the Hellfire Ramparts. Setup step E024
installs `sql/basic/db_world.src/09-outland-dungeons-64.apply.sql`, which
raises to level 64 every creature in each Outland dungeon a level 60 can
enter. The dungeon list is computed from the dungeon-access table (normal
mode, entry level ≤ 60): the Hellfire Ramparts, Blood Furnace, Shattered
Halls, Slave Pens, Underbog, Steamvault, Mana-Tombs, Auchenai Crypts and
Sethekk Halls. Shadow Labyrinth (65), the 67+ dungeons and the raids stay
stock, and so do the open world and every quest.

The set of creature templates is built from:

1. every template spawned in those dungeons;
2. the creature ids those dungeons' C++ scripts name;
3. database-scripted summons and summon groups of anything in the set,
   followed two levels deep.

One safety rule: **a template also spawned anywhere outside these dungeons
is left alone**, the Outland open world included, because raising it would
raise it there too. The Midsummer festival's Ahune encounter in the Slave
Pens is excluded (holiday content). Heroic templates are never spawned
directly, so heroic modes stay stock (level 70, keys, out of reach at 60).

Health and damage follow the level with no further edits. Stats are
computed at spawn as the class/level/expansion base value times the
template's own multipliers (`Creature.cpp`: health = GenerateHealth ×
HealthModifier), so elites stay elite and bosses stay bosses, at level-64
values. Loot is unchanged.

Original levels are saved in `basic_155f_level_backup`, and the revert
restores them. `scripts/validate-basic-state` checks after install that
every raised template is 64, that no template living only in these dungeons
was missed, and that heroic entry is still stock.

## Intended Behavior

- Inside every Outland dungeon a level 60 can enter, every creature is
  level 64 with level-64 health and damage: "as hard as raids".
- Loot, quests and the open world are stock.
- With B005's accuracy cap a four-level gap hits and misses like three.
- If a level-60 party of five clears them too easily, the next knob is the
  templates' health and damage multipliers, logged in
  `docs/balance-updates.md`.

## Suggested Implementation Steps

1. Compute the dungeon list from the dungeon-access table.
2. Collect templates (spawns, C++ script ids, summons); drop those also
   spawned outside the dungeons.
3. Save levels; set 64.
4. After the owner's install: `scripts/validate-basic-state`, then a
   level-60 bot party of five in Hellfire Ramparts.

## Related Issues

- **155** parent; **155c** (B005, the accuracy cap, and the Outland decision)
- **803** monster accuracy level cap — the design behind B005
- **156** expert — at 61–80 these are ordinary levelling dungeons again;
  expert decides whether basic's level-64 version carries over

## Open Questions

- (Answered 2026-09-23) Scripted creatures are raised too; only dungeons
  are affected, and quests and the open world stay stock.
