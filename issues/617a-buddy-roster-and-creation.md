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

- **A hidden companion account per owner account**, created on first need
  and never offered for login. The bot module treats it like its own
  accounts.
- **A roster table** in the characters database: owner character → buddy
  characters, with each buddy's order (1st at creation, 2nd at 10, 3rd at
  20, …) and chosen class. A buddy slot is *owed* when the owner reaches
  the level and *filled* when the class is chosen (617b).
- **Creation**: when a slot is filled, the factory creates a character of
  the chosen class on the companion account, of the owner's faction, and
  levels it to the owner's current level before its first login.
- **Name and race** (owner, 2026-09-23: "random name, random race.
  Compatible with the class that the character picked, of course."): the
  factory's random name, and a race drawn at random from the owner's
  faction among the races that can play the chosen class.
- **Deletion**: deleting the owner deletes every buddy on the roster and
  their rows.
- **Hidden**: buddies never appear on the owner's character screen and
  cannot be logged into by hand.

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
