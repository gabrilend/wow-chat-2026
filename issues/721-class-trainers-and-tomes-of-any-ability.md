# 721 - Class Trainers, and Tomes of Any Ability

## Status
- Created: 2026-10-17
- Phase: 7 (Character Identity — custom classes)
- First profile: beta
- Builds on: 503 (trainers who arrive as travellers), 405 (ability tomes),
  705/709/711 (the custom-class framework and its class files)
- Related: 502 (any class at any trainer, for gold: kept as a design, off
  for beta), 706 (the Knight, the first custom class), 719 (true ability
  tooltips)
- Priority: Medium (needs travellers back on beta first; roadmap step 4)
- State: planned; open questions first

## Origin

From the 2026-10-17 conversation about custom classes on the stock client.
Shown 502's design (a server setting letting any class train at any
trainer, with gold as the only limit), the owner, verbatim:

> for our purposes, let's have it off for the beta profile.

> so, that's an interesting design, but we should rename it to something
> else. For our purposes, the custom class system creates custom class
> trainer lists. So for the knight class, there's a traveller who spawns
> who is a knight trainer, who will only talk to knights, and who trains
> every ability a knight would be able to train. We should ensure that all
> abilities are available to all classes, but the only way to learn them
> is with rare tomes that teach any ability spell, and via trainer. And the
> trainers will only talk to players with the correct class, even custom
> classes. I think that'll be the most comprehensive design.

## Current Behavior

- **Trainers check the stock class only.** A trainer's window opens for
  the class in its `trainer.Requirement` (a stock class id, 1–11) and
  lists only spells whose skill line belongs to the learner's stock class
  (502's "gate one" and "gate two", `Trainer.cpp` and
  `Player::IsSpellFitByClassAndRace`). Nothing on the server knows a
  character's custom class.
- **Custom classes exist only as Lua tables.** The Knight's definition
  (`src/lua-beta/custom-classes/knight.lua`, class 1004: 18 abilities
  from nine classes, each with a level and a gold cost) loads. The
  framework that would give a character a custom class
  (`custom-classes.lua.disabled`) is switched off, so no character has one.
- **Travellers and tomes are off on beta** (`travel.lua.disabled`,
  `ability-tomes.lua.disabled`), so no trainer arrives and no tome drops.
- **Beta's trainer data is on the current tables** (branch beta-homework,
  2026-10-17, to be merged). E011 (the death knight kit), E013 (quest
  spells) and E014 (each travelling trainer's level slice) wrote
  `npc_trainer`, which the current server no longer reads, and had no
  effect; they now write `trainer` and `trainer_spell` and point
  creatures through `creature_default_trainer`, with undo files, checked
  on a stock world by `scripts/test-beta-sql-in-ram`. Step 1 below can
  build on them: a class's trainer list is a `trainer` row of its own.
- **503's custom-class redirection is the opposite rule:** a custom-class
  player meets base-class trainers of its eligible classes, chosen at
  random (travel.lua, dormant while the framework is off). This issue's
  rule (a trainer talks only to its own class) replaces it for beta.

## Intended Behavior

1. **One trainer list per class, stock or custom.** For every class the
   framework knows (the eleven stock classes and every custom class file),
   a trainer list holds every ability that class can learn, at the level
   and price the class file gives. The Knight's list is the 18 abilities
   in its definition.
2. **Trainers of a class come as travellers** (503's traveller pool): a
   Knight trainer wanders by now and then, as any trainer does.
3. **A trainer talks only to its own class.** A Knight trainer opens its
   window for Knights and for no one else; a stock paladin trainer opens
   for paladins and not for Knights (who are paladins underneath, so the
   stock check alone would let them in). Anyone else hears a line of
   refusal.
4. **Every ability works for every class.** Once learned, a spell is the
   character's whatever their class: the per-spell class check (502's
   "gate two") no longer forbids it.
5. **Two ways to learn, and only two:** from your own class's trainer, or
   from a rare tome that teaches one ability, any ability, to anyone
   (405's tomes, widened to every ability).
6. **502's any-class switch stays off on beta** (owner, 2026-10-17). It is
   kept as a design for a realm that wants it.

## Suggested Implementation Steps

1. **Write trainer lists from the class files.** A generator
   (`scripts/generate-class-trainer-sql`) reads each class file and writes
   `trainer` and `trainer_spell` rows, one trainer id per class, into
   beta's SQL folder as an install step. Fix E011/E013/E014 onto the
   current tables at the same time (see Current Behavior).
2. **Record a character's custom class.** The framework (705/709) stores
   it in the characters database (one row per character: guid, class
   definition id). Restore the framework's loading, without its AIO parts.
3. **The class check at the trainer.** A gossip hook on trainer creatures
   (Lua, `RegisterCreatureGossipEvent` on each class trainer's entry)
   compares the speaker's class (custom first, then stock) with the
   trainer's class and either opens the trainer window or speaks the
   refusal. Check whether the stock window can be opened from Lua (B029
   in basic adds a gossip trainer list); if not, a small source patch.
4. **Lift the per-spell class check for learned spells** (a source patch,
   502's gate two): a spell a character has learned is castable whatever
   their class. The resource problem 502 studied (a warrior has no mana
   for Fireball) comes with this: decide with the owner how a borrowed
   spell is paid for (open question 2).
5. **Tomes of any ability** (405): a tome item per ability, or one tome
   item whose spell is chosen at drop; rare, and dropped by the ambush's
   rares and by treasure.
6. **Tests:** offline, the class check (every class against every trainer
   class: opens or refuses) and the generator (every ability of every
   class file is in its list, at its level and price); in game, a Knight
   meeting a Knight trainer and a paladin trainer.

## Open Questions

1. 502 is to be renamed. What should it be called? A suggestion:
   "502-any-class-training-for-gold".
2. When a Knight (mana) learns Sprint (a rogue's, costing energy), what
   does it cost them: 502's conversion (a share of their own resource),
   nothing, or is a spell from a class without your resource not offered?
3. The Knight's talents: its definition has 97 points across 30 talent
   families from nine classes. The stock talent window draws only the
   character's stock class's trees, from the client's own files, and the
   server can't send it new ones; that window was what AIO was for. Without
   AIO, talents could be spent through a menu (a trainer's or Chromie's),
   each talent a passive spell taught when bought. Is that acceptable for
   beta?
4. Does a custom-class character see stock trainers of its base class at
   all (refused, as above), or are stock trainers simply not in the
   traveller pool on beta?
