# 185 - The Level-Up Command: Level, Gear and Professions Together

## Status
- Created: 2026-10-12
- Phase: 1
- Related: 617a6 (buddies by stage: what an owner's level change does to
  their buddies), 617r (gearsets: the white gear by level), 617k (buddy
  professions), 617t2 (the Ragefire scene: its first user), 718 (death
  knight buddies' professions raised to 300)
- Related (2026-10-15): 187 (the purse and the visiting trainer after
  the level rises)
- Priority: High (617t2 waits on it)
- State: planned; open questions first

## Origin

Verbatim, 2026-10-12:

> Also, can you make the "levelup" script that we're using to adjust
> player and buddy-bot levels while keeping their equipment correct, also
> increase to the right level their professions? So we can pick up
> exactly where we'd like need to.

Answers, 2026-10-13 (verbatim):

> let's build our own implementation that changes level, adjusts gear,
> etc. We should be able to offer extra information to it via cli flags,
> like "quality=green" or "quality=poor" or whatever, and it'll generate
> appropriate gearsets to equip each player with depending on their spec
> profile. It should also adjust professions, if any, and if not, it'll
> train them to the correct level.

On five skill points a level, and teaching the recipes a trainer would
have taught: "yes and yes".

Answers, 2026-10-15 (verbatim):

> we have a script for adjusting level just like the class change quest.
> If it isn't there, rebuild it from scratch I guess. Easier than
> searching.

> The buddy class-change and level-change upgrade should apply to all the
> bots in a clan if possible. Well, only the level-change one. And it
> should keep in mind their relative difference in terms of monsters to
> slay at that level to achieve such a differential, and it maintains the
> same degree. So, a character whose buddy-bots are always higher level is
> like the little sibling. But, a player who knows how to grind can keep
> up with them. Then they are leveling apace. Growing up together, how
> sweet.

## Current Behavior

No such script exists. Levels are changed by hand with the server's own
`.character level <name> <level>` command (used on Constine, 2026-09-29).
What follows from it:
- the player's level changes, and their talent points with it;
- their buddies (buddy module, `buddies_stage.cpp`): only a fall in the
  owner's level does anything: buddies above the owner are made again at
  the owner's level, or wait while their slot is above it. A rise
  changes nothing for them; they level on their own as they fight;
- gear: nothing changes. White gear for each tenth level exists as
  gearsets (`src/lua-basic/data/gearsets/buddy-white-1.lua` through
  `buddy-white-60.lua`), put on by the `.gearset` console command, by
  hand;
- professions: nothing changes. A buddy's crafting and gathering
  professions and cooking, first aid and fishing are learned at 1 of 75
  when it is made, and never rise except by use. Only death knight
  buddies are raised (to 300, 718).

## Intended Behavior

One console command, `.levelup <character> <level>` (a Lua command, so it
reloads without a build), that brings a character and their buddies to a
level as if they had played there:
1. the character's level set (through the server's own level command, so
   talent points follow);
2. each buddy of their clan moved by the same distance in *monsters to
   slay*, not in levels (2026-10-15): the experience a buddy is ahead of
   (or behind) its owner is measured in kills of a monster of the
   owner's level, and after the change it stays the same number of such
   kills ahead (or behind) at the new level. A buddy two levels ahead at
   10 stays "that many kills" ahead at 30, which is fewer or more levels
   as the experience curve bends;
3. everyone dressed in the white gearset of that level's tier
   (buddy-white-1, -10, ... -60);
4. every profession each of them has raised to the skill that level
   gives, with the trainer ranks that skill needs (Apprentice 75,
   Journeyman 150, Expert 225, Artisan 300; basic stops at 300);
5. the purse and the visiting trainer of 187, for the player;
6. a reply naming each character and what changed, and anything that
   could not be done.

Usable from `scripts/gm-command` (so scenes such as 617t2 can call it)
and in game.

## Suggested Implementation Steps

1. Answer the open questions.
2. The skill for a level, and the ranks it needs, as one table in
   configuration (the rank spells as `buddies_create.cpp`'s Artisan list
   names them, with the lower ranks' spells beside them).
3. The command in `src/lua-basic/`, registered in
   `config/custom-gm-commands.lua` (help text, console allowed); the
   generated command reference rebuilt.
4. A test of the skill table offline (levels 1, 9, 10, 35, 60, 80).
5. In game: Birth to 15 (617t2).

## Open Questions

7. The kills-ahead measure: experience per kill of a monster of the
   owner's level (the server's own kill-experience formula, no group
   bonus or rest), or of the buddy's level?

1. (Answered 2026-10-13: five points a level, to 300 on basic.)
2. (Answered 2026-10-13: yes, the recipes too, from the trainers' lists:
   every spell a trainer of that profession teaches at or below the new
   skill and level, the rank spells, Journeyman at 10, Expert at 20,
   Artisan at 35, among them.)
3. (Answered 2026-10-13: none yet means trained.) Which ones, for a
   character with none: named by a flag (`profession=leatherworking`),
   or chosen as a buddy's are (a random crafting profession and the
   gathering one that feeds it)?
6. "quality=green": a new gear file per quality and tier, generated as
   the white ones are (`scripts/translate-buddy-kit-to-gearset`, scored by
   the bot module's stat weights for the character's talent shape). White
   gear comes from vendors; where may green, blue and purple come from:
   any item of that quality, or only what drops in the world and
   dungeons (no quest rewards, no crafted)?
4. Lowering a level (60 to 20): skills lowered to match, or kept?
5. Gear: the white gearset every time, or only when the tier changes
   (crossing 10, 20, ...), so better gear found in play isn't replaced?
