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

On crushing blows and crits, and on healing (2026-10-25):

> let's remove them. There's already crits, which... we don't want to be
> able to one-shot a tank either. Hmmm. But, I remember some really hard
> WotLK bosses (which our system is based off of) which basically required
> me to constantly cast Holy Light on the tank (Beacon to the off-tank
> usually) and if I ever stopped then the tank would go down almost
> immediately. Not ideal! I didn't like the way that WotLK felt in that
> specific respect. I wanted to be able to beacon the main-tank and flash
> of light others, with a spellpower/haste build, but it didn't really
> work out that way. Increasing flexibility is good, and because of the
> way that Blizzard split in two post WotLK, their capacity for changing
> the game changed dramatically, as they suddenly had two teams working on
> alternating expansions, which meant they always had to adjust their
> gameplay to someone else's design. This sorta had the same effect as the
> Star Wars sequels, where the first and last had one director, and the
> middle had another for some reason? And while they perhaps were decent
> movies on their own, the fact that they had to be one cohesive story
> caused the wildly different visions to clash, and made the sequel
> trilogy feel... disjointed and confused about it's narrative. Not ideal!

> For a dungeon boss, that sounds about right. Like if I let the tank go
> for ~10-15 seconds without any heals and then she dies, that makes
> perfect sense to me. Raid bosses require raid gear, and that might
> change the dynamic a bit.

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
- **No crushing blows** (B031, since 2026-10-25, not yet compiled; before,
  from level 71 every landed swing on a level-60 tank crushed, x1.5, and
  defence past 300 could not stop it).
- **Crits stay**: double damage, at 5% plus 0.04% per point a boss's weapon
  skill (level x 5) beats the tank's defence. Against crits all of the
  tank's defence counts, gear past the cap included, so 25 defence buys
  away a percent (a level-63 boss's crits are gone at 440 defence, a
  level-78's at 515). At defence 300, a maximum roll that crits is the
  biggest single hit: 95% of the tank's health for Nefarian, 110% for
  Exarch Maladaar (a one-shot, if rarely).
- **The multiplier table** (`basic_creature_multipliers`, 155i: melee,
  spell, heal and health per creature or per map) exists and is empty.
- **Measured melee**, `scripts/tank-damage-taken` (melee only, against a
  4509-health, 10,000-armour, defence-300 level-60 tank, 25% avoided, no
  crushing, crits counted): the level-60 raid bosses' biggest hits are
  50-95% of the tank's health; the Outland dungeon bosses' up to 110%
  (Maladaar); an unhealed tank lasts about 5 to 24 seconds. Doom Lord Kazzak's hits are 315% of it (his
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
  and spirit to matter. **Dungeon target** (the owner, 2026-10-25): an
  unhealed tank dies in about 10 to 15 seconds; the biggest single hit,
  crit included, below the tank's health. Raid bosses are measured
  against raid gear, which may change the numbers.
- **A healer is never chained to one target.** The owner did not like
  WotLK fights where stopping heals on the tank for a moment meant a dead
  tank: there should be room to heal a main tank and help others, with
  more than one healing build working. The 10-15 seconds is that room.
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

1. (Answered 2026-10-25: removed) **Crushing blows**: "let's remove
   them." B031 now removes them on basic.
2. (Answered 2026-10-25: 10-15 seconds) **"Doable", in numbers**: for a
   dungeon boss, an unhealed tank lasting about 10 to 15 seconds "makes
   perfect sense"; no one-shots, crits included ("we don't want to be able
   to one-shot a tank either"); raid bosses against raid gear.
3. **The baseline tank and healer:** which gear do we measure against for
   Outland's dungeons (Azeroth's best blues and epics, or the Outland
   greens and blues scaled to 60 by E031)?
4. **Doom Lord Kazzak:** a level-60 raid boss (155j), so measured against
   a raid of forty or twenty-five, with his 14,000-per-hit melee brought
   down to what a raid tank survives?
5. **Azeroth and spirit:** if spirit's healing makes some vanilla fights
   easier, should those bosses be raised to make up for it, or is the
   easier fight acceptable as the price of spirit being worth having?
6. **Crits and defence:** keep crits as they are, so a tank who stacks
   defence (25 points a percent) can push them to nothing, a real choice
   against stamina and spirit; or cap a boss's crit so even an ungeared
   tank is never one-shot by a crit?
