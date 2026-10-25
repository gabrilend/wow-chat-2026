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
- **With a tank dressed for each boss's tier** (2026-10-25: the owner,
  "Can you test with a similar gear level as the raid tier the boss is
  from is likely to have?"; the tiers from `docs/HTML/basic-gear-ladder.html`,
  the tank's set the best tanking items of that tier in the world database,
  `scripts/tank-damage-taken --gear yes` lists them): tier tanks have
  5,900 to 9,800 health and 390 to 490 defence, so most bosses can barely
  crit them (0 to 5%). Biggest hits, a crit included: raid bosses 24-39%
  of the tank's health, Outland dungeon bosses 7-77% (Exarch Maladaar,
  then Quagmirran and Hellmaw near 57%); without a crit at most 38%. An
  unhealed tank lasts 12-26 seconds in the raids and 11-66 seconds in the
  dungeons, most dungeon bosses 18-33: from melee alone, nearly every
  dungeon boss is easier than the owner's 10-15 seconds. Doom Lord Kazzak,
  against a tank in Naxxramas-40-level gear, still hits for 209% of its
  health. The defence that stops a boss's crits is its weapon skill + 125:
  440 against level 63, 515 against level 78.
- **Exarch Maladaar's damage is melee**, not a spell: his own damage
  multiplier is 14, more than twice any other creature in Auchenai Crypts
  (stock data), and E024 raised him from 67 to 71, which adds about 18% to
  his base damage. His spells (Ribbon of Souls, Soul Scream's fear,
  Stolen Soul) are not the big hits, so spell resistance would not help
  against him.
- **In basic, Outland greens out-tank vanilla raid gear**: the tier sets
  for Blackwing Lair and Ahn'Qiraj take Outland world greens (their
  required level lowered to 60, E031) in most slots over the raids' own
  epics (the 155k ladder's doing; noted, not changed).
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
3a. **The stock fight beside ours** (the owner, 2026-10-25: "I'd also
   like to know the default values, with default scaling and all that, so
   we can compare. Ideally, we're looking for similar difficulty, but
   ideally, a little different so it feels fresh to the players."): for
   each Outland boss, the same measure at its stock level against a
   level-70 tank in its stock tier's gear, next to basic's level-60 tank
   against the raised boss, so each fight can be tuned to about the stock
   difficulty, but not a copy of it.
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
2. (Answered 2026-10-25: 10-15 seconds; crits never one-shot a tank in
   the tier's gear, and an ungeared tank should not survive) "no, but it's
   okay if there's a minimum amount of defence they need to eliminate
   crits. We should ensure that crits never kill a tank outright." "an
   ungeared or improperly geared tank should not be able to survive a
   boss fight. Tanks are the most important part of any raid for the
   reason that they are the sole gate that the boss's damage must always
   go through (aside from spells and other mechanics)." And the reason:
   "my concern with the one-shots is that it'll require tanks to gear
   almost exclusively for stamina, and not provide them the choice of
   stamina / spirit that we're trying to create. Spirit should be the
   right choice for fights where healer mana is important, and stamina
   should be the choice for fights where tank gear avoidance is more
   important." On Maladaar, if spells: "it's okay if tanks have to find
   gear with spell resistances." **"Doable", in numbers**: for a
   dungeon boss, an unhealed tank lasting about 10 to 15 seconds "makes
   perfect sense"; no one-shots, crits included ("we don't want to be able
   to one-shot a tank either"); raid bosses against raid gear.
3. **The baseline tank and healer:** which gear do we measure against for
   Outland's dungeons (Azeroth's best blues and epics, or the Outland
   greens and blues scaled to 60 by E031)?
4. (Answered 2026-10-25, in part: "nearly impossible to defeat. But, not
   impossible") Told that a melee multiplier of about 0.2 would leave his
   top hit at 42% of a Naxxramas-geared tank's health: "that seems too
   easy." Proposed next: about 0.4 (top hit 84% of that tank's health; a
   crit, 168%, kills, so his tank must be crit-proof at 440 defence, 32
   past the Naxxramas tier; about 1,500 damage a second, the tank dead in
   about 4.4 seconds unhealed), before his spells are counted. The owner
   on that proposal: the 32 defence "gems should be enough to cover";
   no break in healing, "good"; one unlucky top roll after a missed heal
   ending the attempt, "that's how it was in heroic ICC". Worked out for
   0.35 to 0.50 against a crit-proof Naxxramas-tier tank (6699 health,
   10263 armour, 42% avoided): any two landed swings kill it at every
   multiplier in that range, so a heal must land between every two of his
   hits that connect; at 0.45 his top hit is 94% of its health, 1567
   damage a second, dead in 4.3 seconds unhealed. Asked to see 0.45
   before choosing. **Chosen 2026-10-25: melee 0.40** ("This is a tank
   that's in otherwise max gear, which already is a lofty target. The
   heals will have to be geared similarly in order to keep up, and who
   knows how long they can keep going?"). The aim: "2 or 3 healers pretty
   consistently healing the main tank, and then another healer or few
   working on the raid. Kazzak is a world-boss, we can put as many players
   as we need, but being able to complete it with a single tank (or two)
   is important."
   **His spells hit the tank too** (`boss_doomlord_kazzak.cpp`, damage
   from Spell.dbc): Void Bolt on his target every 15-18 s, 4394-5105
   shadow; Cleave on his target every 8-12 s, a weapon swing that also
   hits those beside it; Thunderclap every 10-14 s, 2344-2655 nature to
   everyone near him, slowing their attacks and movement; Shadow Bolt
   Volley every 4-6 s, 1488-2011 shadow to everyone in range; Mark of
   Kazzak on a random mana user every 20 s, draining mana and exploding
   for 5000 around them at none left; Twisted Reflection on a random
   target every 15 s (their damage heals him); Frenzy every 30 s from the
   first minute; Berserk at 3 minutes (75% faster attacks: the time
   limit). Against a 6699-health tank, Void Bolt alone is 66-76% of it,
   so his spells need their own multiplier too (open below).
   Wowhead (the owner, 2026-10-25: "he hits between 7,000 and 11,000 on a
   level 70 tank? What's up with that?"): the same numbers. His swing
   before armour averages about 22,250; a level-70 tank's ~16,000 armour
   takes off ~57% against level 73, leaving ~9,500 average, ~11,200 top.
   A level-60 tank's ~10,000 armour takes off ~46%, so the same swing
   lands harder on it.
   **The healers' side** (worked out 2026-10-25 with a temporary script:
   each class's strongest heal rank up to level 60 from Spell.dbc, its
   coefficient from `spell_bonus_data`, and a healer's healing power as
   the best per slot among obtainable items of the tier, any armour kind,
   so a high estimate: about 675 at Molten Core's budget, about 875-900
   at Blackwing Lair's to Naxxramas's): the big heals (Holy Light,
   Greater Heal, Healing Touch, Healing Wave) land for about 3,000-3,700,
   and about 4,500-5,600 when they crit, before talents. So 5,000 needs a
   crit and 7,000 is out of reach for one heal; one healer on a big heal
   every 2.5-3 seconds gives about 1,200-1,300 healing a second. Against
   Kazzak at melee 0.40 (about 1,400 a second from melee; his spells add
   roughly another 1,100 a second on the tank at their stock size), two
   healers on the tank keep up with his melee alone and three with his
   melee and spells, which is the owner's aim; mana is the limit (and Mark
   of Kazzak drains it), and Berserk at 3 minutes the time limit.
   **Doom Lord Kazzak:** a level-60 raid boss (155j), so measured against
   a raid of forty or twenty-five, with his 14,000-per-hit melee brought
   down to what a raid tank survives?
5. **Azeroth and spirit:** if spirit's healing makes some vanilla fights
   easier, should those bosses be raised to make up for it, or is the
   easier fight acceptable as the price of spirit being worth having?
6. (Answered 2026-10-25, with 2 above: keep crits; a minimum defence
   that removes them is fine, and a tank in its tier's gear is never
   one-shot by one) **Crits and defence.**
7. **Dungeon bosses below the target:** from melee alone most Outland
   dungeon bosses leave a tier-geared tank 18-33 seconds unhealed, against
   the 10-15 wanted. Raise their melee to meet it, or wait for their
   spells to be counted first (step 1), since spells will close part of
   the gap?
8. (Answered 2026-10-25, in part: "I think his spells will kill our
   tanks pretty much everytime. So maybe we reduce his multiplier to 0.3
   or something.") With melee and spells both scaled (a crit-proof
   6,699-health tank, 42% avoided, no resistances counted): at 0.30 and
   gear armour 10,263 he deals about 1,500 a second to the tank (melee
   1,045, Cleave 209, Void Bolt 86, Thunderclap 62, volley 105), the tank
   dead in 4.4 seconds unhealed, his worst two seconds (a top swing and a
   Void Bolt) 86% of its health; at 0.40, 2,010 a second and 114%. Armour
   is by item level and quality, not by where an item comes from (a
   Naxxramas epic chest of item level 92 has 1,172 armour, a scaled
   Outland blue of 112 has 1,134, a level-70 Warbringer chest 1,510), and
   the level-70 raid gear that gives level-70 tanks ~16,000 armour is
   not wearable at 60 yet (Kazzak's and Doomwalker's loot still requires
   70: 155j's lowering is not built), so a tank comes in at about 10,000
   from gear, more with talents and buffs (not counted). Raid members at
   the Naxxramas tier (gear stamina about 130-170, weapons aside): about
   3,100-4,500 health unbuffed, 4,050-5,550 buffed, 4,650 on average.
   Frenzy redesigned: 155j. Decided 2026-10-25: **0.40, melee and spells
   alike**, to playtest; Berserk removed (155j). **Kazzak's spells:** scale them with his melee (0.40: Void Bolt about
   1,760-2,040, Thunderclap about 940-1,060, the volley about 600-800), or
   another figure? Unscaled, a Void Bolt right after a top swing (66-76%
   plus 84% of the tank's health) kills.
