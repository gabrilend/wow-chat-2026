# 155f1 - Level-60 Fights Balanced

## Status
- Created: 2026-10-25
- Phase: 1
- Parent: 155f (Outland's dungeons opened at 60, their creatures raised)
- Blocked by: none (the tools and the table exist; the numbers are the work)
- Related: 167 (spirit heals by stamina: the change that shifts every
  fight), 155i (the per-creature damage, healing and health multipliers
  this fills in; completed), 803 and B031 (crushing blows start late),
  155k1 (stamina scaled to the threat: an earlier answer to the same
  worry, on hold), 155k2 (spirit on gear), 155j (Kazzak), 155h (Onyxia and
  Naxxramas at 60), 155z (the Dark Portal front)
- Priority: High

## Origin

The owner, 2026-10-25, after the boss numbers in 167:

> This is... a separate issue, but can we work on balancing the level 60+
> fights now? We want to make sure that with the stamina/spirit changes,
> that the Azeroth fights remain relatively the same, and the Outland
> fights become doable.

> I'm concerned that our updated Outland dungeon bosses and such will deal
> so much damage they'll essentially one-shot our tanks.

> we are adjusting the spell values too, so we should consider them for
> these balancing purposes.

> maybe we should expand the crushing blow limit? Or eliminate crushing
> blows entirely?

And the principle, on spirit and stamina: "this principle, that nothing is
"always right", is what we're designing for." From 155f's origin
(2026-09-23): "The dungeons are supposed to be as hard as raids or
whatever."

## Current Behavior

Nothing is tuned yet. What stands:

- **Spirit heals health by stamina** (B049, divisor 100, not yet
  compiled): spirit x stamina / 100 every 5 seconds, half for 5 seconds
  after each hit, in combat too.
- **Outland's dungeon creatures are raised** to 66-78 (E024, installed),
  each dungeon by its own step; stats follow their new level from the
  server's per-level table.
- **Crushing blows start late** (B031): none until a creature is 8 levels
  above its target, 1/5 of the stock chance at 8, full at 12. Defence
  above 300 counts for nothing at level 60, so from level 71 every swing
  that lands on a level-60 tank crushes (x1.5).
- **The multiplier table** (`basic_creature_multipliers`, 155i: melee,
  spell, heal and health per creature or per map) exists and is empty.
- **Measured melee**, `scripts/tank-damage-taken` (melee only, against a
  4509-health, 10,000-armour level-60 tank, 25% avoided): the level-60
  raid bosses' biggest hits are 25-48% of the tank's health; the 45
  Outland dungeon bosses' 11-82% (Exarch Maladaar the worst); no dungeon
  boss one-shots the tank. Doom Lord Kazzak's hits are 315% of it (his
  damage multiplier 65 and two-second swing; world bosses fight as 3
  levels above their target, so he never crushes). Lord Kazzak, the
  Blasted Lands entry (97%), is not spawned anywhere and has no script: a
  leftover row.
- **Spells are not measured.** A boss's spells and their damage live in
  the game's spell data (`data-files/dbc/Spell.dbc`, the file the server
  reads) and in its script (C++ boss scripts under
  `source-beta/src/server/scripts/`, or the world database's
  `smart_scripts` for creatures run by data), which says what is cast and
  how often.

## Intended Behavior

- **Azeroth's level-60 fights stay about as hard as they are**, once
  spirit heals in combat: the raids (Molten Core, Blackwing Lair,
  Zul'Gurub, Ruins and Temple of Ahn'Qiraj, Onyxia and Naxxramas at 60 by
  155h) keep their stock numbers unless spirit's healing measurably
  softens a fight, and then that fight's bosses get a multiplier.
- **Outland's dungeons become doable at 60, and hard**: as hard as a
  raid, by 155f's origin, but no boss deals in one hit or one breath more
  than a geared tank can take, and the fight is long enough for healing
  and spirit to matter.
- **Spells count as much as melee.** A boss's damage is its melee plus
  its spells at their cast rate; both are tuned through the multiplier
  table's melee and spell columns.
- **Every value comes from a tool.** A generator reads the measured
  numbers and the targets and writes the table's rows (with a comment
  saying why each), and every change is logged in
  `docs/balance-updates.md`.

## Suggested Implementation Steps

1. **Spells measured.** Extend `scripts/tank-damage-taken` (or a sibling)
   to read each boss's spell list from its script (spell numbers and
   timers from the C++ boss script's events, or `smart_scripts` cast
   actions with their repeat times) and each spell's damage from
   `Spell.dbc` (base points plus dice per effect, the school, whether it
   hits one target or an area), giving damage per second from spells
   beside melee, on the tank and on the rest of the group.
2. **A baseline group.** Decide the level-60 characters the targets are
   measured against: a tank's health and armour (blues and Outland gear
   scaled by E031), a healer's healing per second, and the group's size
   (five for dungeons; forty or twenty for raids).
3. **Targets.** For each fight, in numbers: the biggest single hit (or
   spell) as a share of the tank's health, and the damage per second as a
   share of what the baseline healers and spirit heal (the open questions
   below).
4. **Azeroth checked.** Run the measure for the level-60 raid bosses at
   divisor 100 and compare against stock spirit (B049 off), to see which
   fights spirit softens and by how much.
5. **Rows generated.** A generator (`scripts/generate-basic-fight-
   multipliers-sql` or similar) writes `basic_creature_multipliers` rows
   from the measure and the targets, as an install step's SQL.
6. **Playtest**, then adjust by the balance log.

## Open Questions

1. **Crushing blows** for level-60 tanks against Outland's level 71-78
   bosses: keep basic's rule (every landed swing crushes from 71: +50% to
   their melee), push the start further up, or remove crushing blows
   entirely (then the multipliers carry all the difficulty)?
2. **"Doable", in numbers:** what share of a geared tank's health may a
   boss's biggest hit take (today up to 82% from melee alone), and how
   long should an unhealed tank last (today 4 to 26 seconds)?
3. **The baseline tank and healer:** which gear do we measure against for
   Outland's dungeons (Azeroth's best blues and epics, or the Outland
   greens and blues scaled to 60 by E031)?
4. **Doom Lord Kazzak:** a level-60 raid boss (155j), so measured against
   a raid of forty or twenty-five, with his 14,000-per-hit melee brought
   down to what a raid tank survives?
5. **Azeroth and spirit:** if spirit's healing makes some vanilla fights
   easier, should those bosses be raised to make up for it, or is the
   easier fight acceptable as the price of spirit being worth having?
