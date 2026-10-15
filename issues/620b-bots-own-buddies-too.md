# 620b - Bots Own Buddies Too

## Status
- Created: 2026-10-14
- Phase: 6
- Parent: 620
- Blocked by: 620a
- Blocks: 620c
- Related: 617a (roster and creation), 617a2 (companion account), 617c1
  (buddy login and logout), 617c2 (proximity party), 617c3 (dungeon
  draw), 617l (the clan guild), 151 (bot population governor)
- Priority: Medium

## Origin

The owner, 2026-10-14, choosing how an alt bot or random bot meets the
buddy features: "Use it like a player." So a bot is owed buddies at level
1 and each tenth level, exactly as a human is.

## Current Behavior

Not planned for, not tried. Because the buddy module treats any character
that is neither a buddy nor a stand-in as an owner (620a), an alt bot or
random bot that logs in is already queued as an owner by accident:

- **Roster:** it is owed a slot at level 1 and at each tenth level
  (`buddies_roster.cpp`, `buddy_roster` table).
- **Companion account:** one hidden account per owner (617a2,
  `buddy_clan`). For random bots, that is one new account per random bot.
- **Login:** its buddies are queued to log in when it logs in
  (`buddies_login.cpp`).
- **Party:** its buddies are seated by distance into its party (617c2).
  An alt bot is usually already in its master's party, so its buddies
  would be seated into the human's party, against 617's rule that buddies
  join only their own owner's group.
- **Dungeon draw:** the draw counts every group member who is not a buddy
  as a player (`buddies_party.cpp`, the bring-the-drawn step), so an alt
  bot in a human's dungeon group has its own buddies drawn as well.
- **Clan:** an owner with no guild names its clan through the client's
  pop-up box when it picks its first buddy (617l); a bot cannot type.

## Intended Behavior

An alt bot or random bot is an owner in every way a human is, with these
differences, each decided once here:

- **Its buddies serve it, not its master.** When the bot is in a human's
  party, its buddies roam beside the bot but are not seated into that
  party by distance (the human's own buddies keep those seats). In a
  five-player dungeon, the draw fills the empty seats from every owner in
  the group, bots included, by the same tank-and-healer rule (617c3).
- **Its clan is named for it.** A bot founds its clan with a generated
  name (see open questions) at its first buddy, and its buddies join that
  clan as a human's do. An alt bot already in its master's guild keeps
  that guild, and its buddies join it there (as a human already in a
  guild does today).
- **Random bots respect the population cap.** The buddies of random bots
  count toward the governor's bot cap (151); when the cap is reached, a
  random bot's owed slots wait.
- **Deleting a bot deletes its buddies**, as for a human (617).

## Suggested Implementation Steps

1. Route every "is this an owner?" decision in mod-buddies through 620a's
   kind; humans, alt bots and random bots are owners.
2. `buddies_party.cpp`: the distance pass seats a buddy only into a group
   its owner leads, or a group with no human in it; the dungeon draw reads
   every owner in the group (humans and bots).
3. Clan naming for a bot (`sargobras.lua`, `buddies_clan.cpp`): the
   generated name, made through the same guild command so its rules
   apply, retried with the next name when taken.
4. The cap: a random bot's buddy creation asks the governor first.
5. Test in game: add an alt bot with the bot module's add command, level
   it to 10 with the project's level-up command (185), and check its
   roster rows, its companion account, its clan, and that the human's
   party holds only the human's buddies.
6. Update 617a, 617c2, 617c3 and 617l's Current Behavior with the bot case.

## Open Questions

- **How is a bot's clan named?** From a list (like `sargobras-jokes.lua`),
  from the bot's name ("Matis's Kin"), or by its master, by whisper, for
  an alt bot?
- **Should an alt bot's buddies party with it when it leaves the human's
  party** and adventures alone (the alt bot as a leader of its own group)?
- **Random bots' buddies: allowed at all**, or is a random bot an owner
  with zero buddies? (That is 620's first open question, answered here
  for buddies specifically.)
