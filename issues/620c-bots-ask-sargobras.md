# 620c - Bots Ask Sargobras

## Status
- Created: 2026-10-14
- Phase: 6
- Parent: 620
- Blocked by: 620a, 620b
- Related: 617b (Sargobras), 617b1 (buddy entrance), 617f (his look), 617l
  (the clan's name), 617p (NPC awareness: buddies walking up to people),
  164 (per-player unselectable creatures), 718 (the Acherus Sargobras)
- Priority: Medium

## Origin

The owner, 2026-10-14: "making the playerbots interact with Sargobras
[...] correctly", and, on how: a bot uses him like a player.

## Current Behavior

Sargobras (`src/lua-basic/sargobras.lua`) is driven entirely by dialogue
(gossip) menus written in Lua, which the bot module never opens:

- **The valley Sargobras** (creature 6170001) stands in every starting
  valley. A bot never talks to him.
- **The wandering Sargobras** (6170002, or 6170003 with the hat) is
  summoned beside any owner owed a buddy, at login, at each tenth level
  and after a loading screen, from level 10. `sargobras.lua` does this for
  every player with no test, so an alt bot owed a buddy would get one
  trailing it, 10 yards behind, while it trails its master. A human with
  four owed alt bots would have five Sargobras following the party. None
  of them would ever be answered, so none would ever sit by his campfire
  and leave.
- **The choice** (a class or a race, worded "I want a Paladin as my first
  buddy") is made by clicking a dialogue line; `lib/buddy-choice.lua`
  turns it into a whole buddy. Nothing chooses on a bot's behalf.

## Intended Behavior

- **A bot owed a buddy goes and asks.** When a wandering Sargobras is
  summoned for it (or it is within 30 yards of a valley Sargobras and
  owed), it walks up to him, faces him, does the talking gesture for a few
  seconds, and makes its choice; he answers in /say as he does for a
  human ("A dwarf Priest. They'll find you soon.").
- **How a bot chooses:** the role its group lacks most, counted the same
  way the dungeon draw counts tank and healer (617c3), among the classes
  and races `lib/buddy-choice.lua` allows; ties broken at random. An alt
  bot's master may instead whisper it a choice (see open questions).
- **One Sargobras per owner, still.** An alt bot's wanderer trails the
  alt bot, not the human, and goes on break the same way once the bot has
  chosen. The rule that no more than two Sargobras appear within about 30
  yards (617, origin) keeps a party of alt bots from crowding.
- **The clan's name** is 620b's generated name, given at the first pick
  in place of the pop-up box.
- **Death knights:** out of scope while basic keeps "no playerbot plays a
  death knight" (620, open question).

## Suggested Implementation Steps

1. Where the choosing happens: either a small bot-module strategy (C++, a
   B-patch or mod-buddies, as 617p's walk-up to NPCs is) that walks to
   Sargobras and calls the choice, or a Lua timer in `sargobras.lua` that,
   for a bot owner (620a), walks it over (`MoveTo`) and calls the same
   choose function the dialogue line calls. The Lua route reuses
   everything `sargobras.lua` already has; prefer it.
2. The role-lacking choice, as a pure function in `lib/buddy-choice.lua`,
   tested offline by `scripts/test-buddy-choice`.
3. The clan name hand-off (620b).
4. Test in game: an alt bot at 9 levelled to 10 with its master nearby:
   one wanderer appears behind the alt bot, the bot walks to him, chooses,
   he speaks, goes on break, and the buddy arrives (617b1).
5. Update 617b's Current Behavior with the bot case.

## Open Questions

- **Should an alt bot's master be able to choose for it** (a whisper such
  as "Sargobras: paladin"), or does the bot always choose by itself? On
  basic, chat commands to buddies are dropped (B045), but alt bots still
  take commands.
- **Should a bot's Sargobras still sit by a campfire and tell jokes** once
  it has chosen, or leave at once (nobody is there to hear him)?
