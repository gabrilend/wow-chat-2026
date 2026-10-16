# 187 - A Trainer and a Purse After a Level or Class Change

## Status
- Created: 2026-10-15
- Phase: 1
- Related: 185 (the level-up command: its first user), 186 (gear of equal
  strength: the other half of a change), `scripts/change-character-class`
  (the class-change tool: its second user), 617n (buddies' lessons: free,
  so buddies need no purse), 503 (trainers that appear on demand)
- Priority: High
- State: planned; open questions first

## Origin

Verbatim, 2026-10-15:

> on the level-up and class-change scripts, can we be sure to modify the
> level of coins available to be worth as much as a trainer? And, for the
> level change, can we spawn a class-appropriate (and on class-change)
> trainer? So what I mean is, the player upon level/class changing, should
> always be able to train all of their abilities. They only develop as a
> character if they don't have all their abilities

Answers, the same day:

> every spell the player can't train yet between here and the level they
> need to change to. If it's down, they won't need gold adjustment,
> because they'll be unlearning some spells.
>
> just like how I unlearned potty training!

On the class-change tool needing the world server stopped:

> can we disconnect that player and prevent them from logging on? Maybe
> with some message to the authserver, like "you have been banned for 30
> seconds while we adjust your class" or something?

The owner, 2026-10-15 (verbatim), on this tool and its sibling: "they
should both modify buddy-bots too, if targeted specifically. If targeting
to a player, then it adjusts the whole team proportional to their level
differential with the player. Also, I want you to run the commands for
me, I don't want to run them in the meat body." So: aimed at a buddy, the
tool changes that buddy alone; aimed at a player, it changes the player
and every buddy of the player's clan, each keeping its distance from the
player (185's kills-ahead measure for levels; for a class change, the
buddies keep their own classes unless aimed at one by one). Claude runs
these tools and the `.buddy kit` / `.buddy gems` commands after them.

## Current Behavior

- The class-change tool (`scripts/change-character-class`, with
  `scripts/lib/class-change-sql.lua`) refuses to run unless the world
  server is stopped. It gives no money and summons no one; the changed
  character must find a trainer of the new class and pay for every lesson.
- The level-up command does not exist yet (185). Levels are changed with
  the server's own `.character level`, which gives no money either.
- Buddies need neither: they learn every lesson free when made (617n).

## Intended Behavior

1. **The purse.** When a character's level rises (or its class changes),
   it is given exactly the copper that the lessons it can't train yet
   would cost: every lesson of its class trainers (and weapon masters?
   see the questions) whose required level is above its old level and at
   or below its new level. For a class change, "old level" is 0: every
   lesson of the new class up to its level. A level that falls gives
   nothing (its higher lessons are unlearned instead).
   The sum comes from the world database's `trainer_spell` rows (their
   `MoneyCost`, `ReqLevel`), never a hand-typed table.
2. **The trainer.** A trainer of the character's class appears beside it,
   stays a few minutes (or until it walks away), and is seen only by it,
   so it can train everything at once.
3. **The class change, live.** Instead of refusing while the world
   server runs, the tool asks the running server to disconnect that one
   character's account and lock it out for a short time (a ban of about
   30 seconds, its reason "your class is being changed"), makes the
   change, then lifts the ban. The purse and the trainer are given at the
   next login (the character is offline while the tool works).
4. A reply (in game, or on the console) naming the copper given, the
   lessons it covers, and the trainer summoned, or what failed.

## Suggested Implementation Steps

1. Answer the open questions.
2. The lesson-cost sum: one query over `trainer_spell` joined to the
   class's trainers (`trainer.Type` 0 and `Requirement` the class),
   counted once per spell (many trainers teach the same lesson), from old
   level + 1 to the new level. Offline test with known sums (a warrior
   10 to 20; a mage 0 to 15 after a class change).
3. A pending-reward row the server reads at login (the character's guid,
   copper, "summon trainer"), written by both tools, removed once given.
   This survives the character being offline, the same way the
   class-change tool's other work does.
4. The visiting trainer: a creature of the class's trainer entry spawned
   by the Lua side at the character's position for N minutes (503 holds
   the earlier design; read it first). It is spawned privately to that
   character, if the engine allows it.
5. The live class change: the console's `.ban account <name> 30s <reason>`
   (it kicks and locks out) through `scripts/gm-command`, the tool's
   world-server check changed from "stopped" to "stopped, or the account
   is banned and offline", then `.unban account <name>`.
6. In game: Felicity again (priest at her level); a level-up 20 to 30.

## Open Questions

1. Weapon masters' lessons (10 silver each, Staves, Guns ...): counted in
   the purse, or taught free since buddies now learn them free?
2. The visiting trainer: seen by the character alone, or by everyone
   nearby? How long does it stay?
3. When a level rises by the level-up command, do the character's buddies
   (who learn free) get anything, or only the player?
4. The ban's message: the game client shows a fixed "this account has
   been banned" text, not our reason. Is that acceptable, or should the
   lock-out instead be a "character locked for 30 seconds" flag our own
   login hook enforces (with our words, whispered or on the login screen
   it can't be)?
