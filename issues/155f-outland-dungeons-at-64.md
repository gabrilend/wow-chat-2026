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

And on the loot, verbatim, 2026-09-23:

> if any of the gear dropped requires higher than level 60, we should set
> it's required level to level 60. This includes greens that might drop in
> those dungeons.

Revised, verbatim, 2026-09-23 (not built yet):

> I think we should change it so that creatures in these dungeons have +4
> levels, with a max of level 64. So HFR for example might be doable at level
> 59 or 58 even maybe, because it'd have mostly level 62 enemies. Jeez nine
> dungeons... That's probably like, level 65 gear or above, right? That's too
> powerful for a level 60 to have, though the difficulty to acquire it might
> make it worth it.

Settled, verbatim, 2026-09-24:

> I changed my mind, let's make each creature get +4 to their level.

> The higher level Outland Dungeons we want to have roughly the same item
> level as the most powerful vanilla raid gear. This is because the server is
> small right now, and I expect people to do dungeons but probably not raids.
> Though with playerbots, maybe that concern fades away...

> I want the dungeon and raids to be about the same tier, because they
> require the same number of players - you can do 5 humans in a dungeon, or
> 1 human and five of their bots, so they're slightly more accessible than
> the raids, which can use minimum 5 players but up to 40 as well.

On what +4 should change:

> Ideally, it'd only change health and damage. Armor might scale weirdly,
> but I'm open to it. We should also consider resistances and such.
> Question, can we modify the damage or healing or whatever that the boss
> and creature spells do? If so, that helps a lot.

On crushing blows, the three options named: patch them out once a
character reaches 60, patch them out for everyone, or "accept them as
trials of the champion and balance around them". Settled: "let's say that
crushing blows do not take effect for creatures level 64 and higher." On
the level-gap caps: "Seems like armor and resist scale fairly linearly, so
it's okay to keep them. I want to remove exponential difficulty increases. I
want it to be possible, but not easy." And: "The
highest level Outland dungeons will probably be impossible for a level 60
group, especially with the +4 adjustment."

On the gear ladder:

> Ideally, we'd increase the potential items that can be equipped (by
> lowering their required equip level) such that the highest dungeons we
> open up are the ones that have gear roughly equivalent to the highest tier
> vanilla raids.

Later the same day, verbatim:

> we should consider lowering the sethekk, shadow labs, and shattered halls
> to make them more in line with the growth progression of the other
> Outland dungeons

> Yeah I think Sethekk Halls, Shadow Labs, and Shattered Halls should be
> scaled down to match the progression of the other dungeons, both in enemy
> level and loot quality. We should try and scale the progression of blues
> to match the progression of Outland dungeons. So... we should scale down
> the rewards from the Sethekk Halls through MGT to match Naxxramas in
> difficulty, MTTK, and ilevel rewards, adjusted for quality of course.

On Kael'thas's epics: "Yeah. But Kael'thas should get an extra +2 levels
maybe. Idk. What would be a good level for him according to his relative
difficulty with other bosses giving similar ilevel loot?"

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

**Gear wearable at 60.** The same file lowers to 60 the required level of
every weapon or armour piece that drops in these dungeons' normal mode and
requires more than 60. It follows the raised creatures' loot tables, the
dungeons' chests, and the reference tables those point at (three levels
deep). Required level belongs to the item, so an item that also drops
elsewhere becomes wearable at 60 there too; on basic, where 60 is the cap,
that only helps. Clients see the new number once their item cache is
refreshed, which C025 (issue 160) arranges.

Original creature levels and required levels are saved
(`basic_155f_level_backup`, `basic_155f_item_backup`), and the revert
restores them. `scripts/validate-basic-state` checks after install that
every raised template is 64, that no template living only in these dungeons
was missed, and that heroic entry is still stock.

**Not yet built (2026-09-24):** the owner's +4 rule. The built file sets a
flat 64; it becomes "stock level + 4" per template (the backup table already
holds the stock levels to add to). With +4 the nine dungeons span, stock →
raised: Ramparts bosses 62 → 66, Blood Furnace 62–63 → 66–67, Slave Pens
63–64 → 67–68, Underbog 65 → 69, Mana-Tombs 66 → 70, Auchenai Crypts 66–67
→ 70–71, Sethekk Halls 68 → 72, Steamvault 72 → 76, Shattered Halls 71–72
→ 75–76 (queried from the stock world database, bosses = templates with a
`boss_` script).

**What level drives, besides health and damage** (read 2026-09-24 in the
server's combat code; this is why +4 is more than +4):

- *Crushing blows* (`Unit.cpp`, melee outcome roll): a creature 4+ levels
  above its target crushes for 150% damage, chance 2% per weapon-skill point
  over 15 above the target's (capped) defense: 25% at 64, 45% at 66, 85% at
  70, and past about 67 every hit that is not dodged, parried, blocked or
  missed is a crush. B005 does not touch this. Stock raid bosses are 63 and
  never crush on this server.
- *Armor* (`CalcArmorReducedDamage`): reduction = armor ÷ (armor + 85 × L′ +
  400), L′ = L + 4.5 × (L − 59) for attacker level L over 59. 9,000 armor
  stops 55% of a level-63 attacker's melee, 50% of a 66's, 40% of a 76's.
  Separately the creature's own armor grows with its level (warrior-class
  base 4,641 at 63, 4,937 at 64), so players' physical damage drops too.
- *Spell resists* (`GetEffectiveResistChance`): a creature above the caster
  gains 5 resistance per level, and its resistance constant grows with its
  level (136 at 64, 286 at 76), so a level-60 caster's average partial
  resist is ~11% on a 63, ~13% on a 64, ~22% on a 76.
- *Aggro radius* (`Creature::GetAggroRange`): 20 yards plus 1 yard per level
  the creature is above the player. Basic does not carry B024.
- *Rating conversion* (asked 2026-09-24): hit, crit, haste and other
  ratings turn into percentages by the **wearer's** level (at 60, 14 crit
  rating = 1% crit; at 70, about 22), never the enemy's, so Burning Crusade
  gear keeps its ~1.6× against any creature. The enemy's level acts
  elsewhere: its health, damage and armor. Per creature level above 60 (the
  server's per-level base table, warrior class, Burning Crusade column):
  health +3.2% a level from 60 to 76 (4,979 → 8,247), weapon damage +5.1% a
  level (53.5 → 124), armor +5.2% a level. Across the dungeon ladder, from
  the Ramparts' bosses (66) to Shattered Halls' (76), creatures gain 35%
  health and 46% base damage, while the gear gains ~37% stat budget (blue
  85 → 115). So the enemies keep pace with the gear and a little more:
  each tier needs the previous tier's gear, and the top stays hard.
- *Boss spells* do not scale with creature level (their damage is in the
  spell data), so +4 barely changes them.

## Intended Behavior

- Inside every Outland dungeon a level 60 can enter, every creature is its
  stock level + 4, with health and damage for that level: "as hard as
  raids". Dungeons and vanilla raids sit at about the same tier.
- +4 should change health and damage, not add steep effects: creatures of
  level 64+ never crush (803's extension, its own patch). Armor, resists
  and aggro radius follow level as stock (Ritz's call).
- **The upper dungeons follow the same ladder as the lower ones** (Ritz,
  2026-09-24): Sethekk Halls through Magisters' Terrace are brought down to
  match Naxxramas-40 in difficulty, time to kill and loot (≈ epic item level
  83–92 by stat budget), continuing the step the lower six take (about
  +2.4 budget and +0.5–1 boss level per dungeon). Proposed ladder, to be
  confirmed:

  | Dungeon | Boss level now (+4) | Proposed | Blues now (≈ epic) | Proposed |
  |---|---|---|---|---|
  | Ramparts → Auchenai Crypts | 66 → 70–71 | unchanged | 69 → 81 | unchanged |
  | Old Hillsbrad | (not measured) | 71 | (not measured) | 83 |
  | Sethekk Halls | 72 | 72 | 91–93 | 84 |
  | Black Morass | (not measured) | 72 | (not measured) | 85 |
  | Shadow Labyrinth | 76 | 73 | 91–93 | 86 |
  | Shattered Halls | 75–76 | 73 | 91–93 | 87 |
  | Steamvault | 76 | 74 | 91–93 | 88 |
  | Mechanar | 76 | 74 | 93 | 89 |
  | Botanica | 76 | 75 | 93 | 90 |
  | Arcatraz | 76 | 75 | 93 | 91 |
  | Magisters' Terrace | 74–76 | 76 (Kael'thas 78) | 93 | 92 |

  Loot is brought down by scaling each item's stats (and item level) to the
  target budget, not by swapping items. The items are shared with heroic
  mode, which basic keeps closed. Levels are set per creature (a fixed
  offset per dungeon instead of +4), and health and damage per creature
  through 155i where level alone does not land the time to kill.
- **Kael'thas's six item-level-110 epics** become wearable at 60 (Ritz:
  "Yeah") and are scaled to **item level 100**, the same as the rare
  world-drop epics (Ritz, 2026-09-24: "Can we bump the Kael'Thas epics up
  to level 100, same as the random epic drops?").
- Creature spell damage and player healing inside these dungeons have their
  own per-dungeon multipliers (155i), so difficulty is tuned there rather
  than by more levels.
- Loot tables, quests and the open world are stock; dungeon gear that
  required more than 60 requires 60, the rare item-level-100 epics in
  trash included.
- **Seven more dungeons open at 60** (Ritz, 2026-09-24): Old Hillsbrad,
  Shadow Labyrinth, Magisters' Terrace, Black Morass, Botanica, Mechanar,
  Arcatraz (normal mode; entry lowered to 60 in the dungeon-access table).
  Their attunements are removed: Old Hillsbrad needs the quest "The
  Caverns of Time" and Black Morass needs "Return to Andormu" (both
  minimum level 66, in the dungeon-access requirements table); Arcatraz
  and Shattered Halls need no key in normal mode on this client. Heroic
  requirements stay. Their bosses (70–72) become 74–76.
- **Crushing blows**: none from creatures level 64 and up (803).
- Tuning changes are logged in `docs/balance-updates.md`.

## Suggested Implementation Steps

1. Compute the dungeon list from the dungeon-access table.
2. Collect templates (spawns, C++ script ids, summons); drop those also
   spawned outside the dungeons.
3. Save levels; set 64.
4. After the owner's install: `scripts/validate-basic-state`, then a
   level-60 bot party of five in Hellfire Ramparts.

## Related Issues

- **155** parent; **155c** (B005, the accuracy cap, and the Outland decision)
- **803** monster accuracy level cap — the design behind B005; its
  extension: no crushing from level 64 up (its own patch)
- **155h** Onyxia and Naxxramas at 60 with their vanilla loot — the raid
  side of "same tier"
- **155o** Darkmoon cards: Tempest Keep bosses drop one Burning Crusade
  card each, Magisters' Terrace bosses two
- **155i** per-dungeon creature damage and healing multipliers — the knob
  that tunes these dungeons instead of more levels
- **156** expert — at 61–80 these are ordinary levelling dungeons again;
  expert decides whether basic's level-64 version carries over

## Open Questions

- Confirm the proposed upper-dungeon ladder above (levels and budgets).
  Drawn in the gear-ladder chart's Proposed view
  (`docs/profiles/basic-gear-ladder.html`), as the owner asked ("I'm a
  visual learner"). Raw blue item levels for the targets: Old Hillsbrad
  102, Sethekk 104, Black Morass 105, Shadow Labyrinth 106, Shattered
  Halls 107, Steamvault 109, Mechanar 110, Botanica 111, Arcatraz 112,
  Magisters' Terrace 113; Kael'thas's epics 100.
- **Boss levels against loot** (Ritz, 2026-09-24: "It's interesting to me
  that Kael'Thas is level 78 while the Fel Reaver is 70 and Kazzak and
  Doomwalker are 73. That feels... wrong somehow, especially since they
  drop such different tiers of gear."): the proposal to raise the world
  bosses to 80 and drop Kael'thas to 77 was declined ("I think they would
  be impossible at level 80. Let's leave them as they are and see if
  that's fine."). Kael'thas stays at 78, the world bosses at stock.
- (Answered 2026-09-24) The rare item-level-100 trash epics stay as they
  are: "they are very rare. That's okay I think."
- **Rating conversion (revised 2026-09-24).** Ritz asked: "yes, but
  when the expansion released, they converted them to ratings. Can you
  validate this concern?" Validated, and the first proposal was wrong: in
  this client the vanilla items' equip effects *are* ratings. Band of
  Accuria's "+2% hit" is spell 15465, "Increased Hit Rating 20" (aura type
  189, modify rating), and Onslaught Girdle's "+1% crit" is spell 7597,
  "Increased Critical 14" (read from Spell.dbc). Of 344 vanilla raid epics,
  282 carry such an equip effect. They are sized for level 60 (14 crit
  rating = 1% at 60). So converting at the level-70 rate would cut vanilla
  gear's crit and hit by ~37% too. New proposal: leave the conversion
  alone and discount the rating stats on **Burning Crusade items only**
  (× ~0.63, i.e. 14 ÷ 22.1) inside the same stat-scaling pass that brings
  their budgets to the ladder. Vanilla gear keeps its intended values,
  Outland gear stops getting the 1.6× bonus, and the HoT/DoT gap narrows
  as intended. **Decided 2026-09-24: "Sounds good."**
- (Superseded) First proposal. Ritz, 2026-09-24: "maybe we could modify the
  scaling to make it about 1x effect? What do you think that would cause to
  happen? I worry because we don't want some crit focused characters to
  benefit more from HoT and DoT characters who can't benefit from crit very
  much in WotLK." Proposal: convert ratings at the level-70 rate for every
  character below 70 on basic. Effects: rating stats on Burning Crusade
  gear lose ~37% (crit, hit, haste, expertise, defense, dodge, parry,
  block); primary stats, spell power and attack power are unchanged; vanilla
  gear is unchanged (its secondary stats are equip effects, not ratings).
  The gap between crit/haste-stacking specs and HoT/DoT specs narrows
  (in this client heal-over-time never crits, most damage-over-time doesn't,
  and haste doesn't add ticks). Hit and defense caps take more gear to
  reach. The character sheet's percentages come from the server and stay
  right; the client's own rating tooltips would show the old numbers
  unless the client's rating table is patched too (Ritz: "good to keep
  this in mind").
- (Answered 2026-09-24) Kael'thas's difficulty is mostly spells: "this
  system only really works if we can patch spells, which I think we can.
  At least, things like damage and healing we can." Yes: damage and
  healing through 155i's per-creature hooks; other spell properties
  (durations, radii, cooldowns) through the server's spell-corrections
  file, as a source patch.
- (Answered 2026-09-24) Magisters' Terrace's Kael'thas epics: wearable at
  60. His level: +2 over the dungeon's other bosses was the owner's idea;
  proposed 78 in the ladder above.
- (Answered 2026-09-24) Crushing blows: creatures level 64 and higher never
  crush (803).
- (Answered 2026-09-24) Open the seven extra dungeons at 60, attunements
  removed: "Theoretically yes, if we remove the attunement requirements".
- (Answered 2026-09-24) The item-level-100 rare epics: required level 60,
  "let them be 60".
- (Answered 2026-09-24) +4 per creature, no cap. Gear stays wearable at 60;
  dungeons and vanilla raids should be the same tier.
