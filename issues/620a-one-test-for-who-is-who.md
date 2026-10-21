# 620a - One Test for Who Is Who

## Status
- Created: 2026-10-14
- Phase: 6
- Parent: 620
- Blocks: 620b, 620c, 620d, 620e, 620f, 620g
- Related: 617a2 (the companion account), 617a5 (the companion list the
  core keeps, B044), 617t1 (the stand-in account)
- Priority: High within 620 (every other sub-issue asks this question)

## Origin

Written with 620 (owner, 2026-10-14: playerbots should interact correctly
with Sargobras, buddies "and all the other features we've added"). Every
feature that must treat bots correctly first has to know which kind of
character it is looking at.

## Current Behavior

There are five kinds of character on basic, and no single place that
names them:

| Kind | How it is told apart today |
|---|---|
| human player | not a bot (no bot brain attached to its session) |
| alt bot | a bot whose account is a human's own account; nothing in our code checks for it |
| random bot | a bot on one of the bot module's random-bot accounts; nothing in our code checks for it |
| buddy | its account is on the companion list (`BuddyIsCompanionAccount`, filled from `buddy_clan` by mod-buddies, kept in the core by B044) |
| stand-in | its account is the stand-in account (`BuddyIsStandInAccount`, `buddies_stand_ins.cpp`) |

The buddy module checks stand-in, then buddy, and treats everything left
as a human owner (`buddies_login.cpp`, `OnPlayerLogin`). The Lua scripts
have only `player:IsBot()` (true for alt bots, random bots, buddies and
stand-ins alike) and roster queries; `sargobras.lua` checks nothing.

## Intended Behavior

One answer, the same in C++ and Lua, to "what kind of character is this?":
human, alt bot, random bot, buddy, or stand-in.

- In C++: a function in mod-buddies' shared header (beside
  `BuddyIsCompanionAccount`) returning one value of a five-value kind. It
  reads the account lists already kept (companion, stand-in), whether the
  session has a bot brain, and the bot module's own record of whether a
  bot is a random bot.
- In Lua: the same value through one ALE call (a small B-patch beside
  B041's per-player calls), or, if a patch is not wanted, a Lua helper in
  `src/lua-basic/lib/` built from `IsBot()` and the roster tables. The
  C++ answer is the source of truth; the Lua one is tested against it.
- Every existing account check in mod-buddies goes through it, so the
  next kind added (a cross-server visitor, 913) is added in one place.
- A dispatch table keyed by kind, not a chain of ifs, wherever a feature
  does different things per kind.

## Suggested Implementation Steps

1. Read how the bot module records random bots (its random-bot manager
   keeps the list of random-bot accounts) and how an alt bot's session
   differs from a human's.
2. Add the five-value kind and the function to `patches/B036-mod-buddies/mod-buddies/src/`
   (header `buddies.h`), replacing the stand-in/companion/else chain in
   `buddies_login.cpp` and the other places that test the companion
   account to decide "is this a player?" (`buddies_party.cpp`'s dungeon
   draw and role count, among others: grep for `BuddyIsCompanionAccount`).
3. The Lua side: an ALE method `player:GetCharacterKind()` (new B-patch,
   following the `upstream-patch-system` skill) or the Lua helper.
4. Tests: an offline test of the Lua helper's table, if that route is
   taken; in game, a `.buddy` GM command (`buddy-gm.lua`) that prints the
   kind of the selected character, tried on each of the five.
5. Write the kind table into `docs/` beside the buddy module's datapath
   document.

## Open Questions

- An ALE patch (one exact answer in Lua) or a Lua-only helper (no new
  patch, but it must guess "random bot" from the account name or the bot
  module's database)?
