# 617a - Buddy Roster and Creation

## Status
- Created: 2026-09-23
- Phase: 6
- Parent: 617
- Priority: High (every other 617 part stands on it)

## Current Behavior

No buddy exists. The pieces to build one with:

- the bot module's character factory, `RandomPlayerbotFactory::CreateRandomBot(session, class, nameCache)`
  (`modules/mod-playerbots/src/Bot/Factory/RandomPlayerbotFactory.cpp`),
  which makes a valid character of a class with a name, race, looks and a
  starting kit, on a given account's session;
- `PlayerbotHolder::AddPlayerBot(guid, masterAccountId)` (`PlayerbotMgr.cpp`),
  which logs a character in as a bot with a master account;
- core player hooks: level change (`OnPlayerLevelChanged`) and character
  deletion (`OnPlayerDelete(guid, accountId)`), in
  `src/server/game/Scripting/ScriptDefines/PlayerScript.h`;
- the project already links a project-owned module into the source tree at
  build time (B008 does this for mod-talent-bonus). A project-owned
  `mod-buddies` is the natural home for 617's C++.

## Intended Behavior

- **A hidden companion account per owner character** (Ritz, 2026-09-25:
  "one buddy bot account per character created"; this replaces "per owner
  account", which would have hit the server's characters-per-account limit
  at seven buddies per character), created with the character and never
  offered for login. The bot module treats it like its own accounts, and
  deleting the character deletes the account with its buddies.
- **A roster table** in the characters database: owner character → buddy
  characters, with each buddy's order (1st at creation, 2nd at 10, 3rd at
  20, …) and chosen class. A buddy slot is *owed* when the owner reaches
  the level and *filled* when the class is chosen (617b).
- **Creation**: when a slot is filled, the factory creates a character of
  the chosen class on the companion account, of the owner's faction, and
  levels it to the owner's current level before its first login.
- **Name and race** (Ritz, 2026-09-23: "random name, random race.
  Compatible with the class that the character picked, of course."): the
  factory's random name, and a race drawn at random from the owner's
  faction among the races that can play the chosen class.
- **Deletion**: deleting the owner deletes every buddy on the roster and
  their rows.
- **Hidden**: buddies never appear on the owner's character screen and
  cannot be logged into by hand.

### Decisions, 2026-09-25 (Ritz)

**Starting kit** ("clad in all white quality gear. They have their level
in silver, except at level 1 they have none. They have the same number of
bag slots as the player they spawn with, choosing the lowest quality bags
to match that number, spread evenly as possible. Prefer four 8 slot bags
over two 10 slots and two 6 slots."):
- **Gear**: white (common) items only, in every slot the class can fill at
  its level.
- **Money**: its level in silver (a level-30 buddy has 30 silver); none at
  level 1.
- **Bags**: as many bag slots in total as the owner has at that moment,
  split over the four bag slots as evenly as sizes allow, using the
  lowest-quality bags that make up the total: four 8-slot bags, not two
  10s and two 6s.

**Hidden from other players** ("ideally no..."): buddies don't appear in
/who, nor can they be added as friends.

**No renaming** ("can't rename"), and **the bot module's chat commands
don't work on buddies** ("the chat commands probably shouldn't work.
However, they can be called with tool calls from the LLM once we build
that"): a buddy ignores whispered or party-chat bot commands; later the
language-model layer (917, 617m) reaches the same actions as tool calls.

**No faction or race change** ("I don't intend to support faction or race
changes at this time"): basic doesn't offer them.

**Server restart** ("Ideally, they'd remember"): what a buddy is doing
(errands, task hunts, the dungeon draw bag, auction price memory) is kept
in the database, so a restart picks up where it left off.

### Data model (proposed 2026-09-25, to confirm)

Ritz: "Not sure. Suggestions?" Everything a buddy must remember lives in
the characters database (it belongs to characters and is deleted with
them); the one hand-kept list lives in the world database (it is part of
the world, like vendor prices). Every id is `int unsigned` unless noted.

| Table | Key | Fields | Holds |
|---|---|---|---|
| `buddy_clan` | owner | companion account; clan guild id | one row per owner: the hidden account (617a) and the clan guild (617l) |
| `buddy_roster` | owner, slot (`tinyint`: 1 at creation, 2 at level 10, …) | buddy character (empty while the slot is owed); class, race, profile, role (`tinyint` each: role 0 damage, 1 tank, 2 healer); created (unix time) | who the buddies are; an owed slot is a row with no buddy yet (617b fills it) |
| `buddy_draw` | owner, buddy | had a turn (`tinyint` 0/1) | the dungeon draw bag (617c): drawn without replacement; when every buddy has had a turn, all reset to 0 |
| `buddy_task` | buddy, task number | kind (`tinyint`: errand, gathering, task hunt), place in line (`smallint`; the first three hunts active, the rest the backlog, 617m), the task itself (text: the command as written, one entry per material and source), progress (text: which steps are done) | what each buddy is doing, so logout and restart resume it (617c) |
| `buddy_price` | auction house (`tinyint`: Alliance, Horde, neutral), item | steps up (`tinyint`, each +0.5× the vendor price, 617h), last listed price (copper), updated (unix time) | the rising-price memory; reset to 0 steps after a sale |
| `basic_617h_fixed_prices` (world) | item | price (copper), note (why) | the hand-kept prices for items with no vendor price (617h); a checked-in SQL file |

Choices in it, open below: price memory per auction house (shared by all
buddies selling there) rather than per buddy; the task itself as text in
the command's own form rather than one row per step.

## Suggested Implementation Steps

1. Decide the module layout: `modules/mod-buddies` in the project, linked
   into the source tree by a B-patch in the shape of B008, but failing
   loudly if the folder is missing (B008 silently skips; see 155c's
   findings).
2. Characters-database table and its SQL step (E-patch), in the rotation
   table's style (155d).
3. Companion-account creation: name derived from the owner's account id,
   flagged so the account can't log in normally.
4. Creation path: a function the selector NPC (617b) calls with (owner,
   class). It creates the character through the factory, sets its level,
   records the roster row, and hands off to 617c to log it in.
5. Deletion hook.
6. Test: create an owner, choose a class, check the roster row, the
   companion account, the buddy's class and level; delete the owner and
   check that all of it is gone.

## Related Issues

- **617** parent; **617b** calls this; **617c** logs buddies in
- **155d** B028's creation block, where the first buddy slot is owed

## Open Questions

- (Answered 2026-09-23) Random name; random race of the owner's faction that
  can play the chosen class.
- (Answered 2026-09-25) Starting kit: all white gear, the buddy's level in
  silver (none at 1), the owner's bag-slot total in the lowest-quality,
  evenly sized bags. Hidden from /who and friends; no renaming; bot chat
  commands off (tool calls later); no faction or race change; remembered
  across restarts.
- **Data model** (proposed above): does the layout fit? Two choices in it:
  should the rising auction price be remembered per auction house (all
  buddies selling there share it) or per buddy; and should a task be kept
  as one text in the command's own form, or one row per step?
