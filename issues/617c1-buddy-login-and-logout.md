# 617c1 - Buddy Login and Logout

## Status
- Created: 2026-09-27
- Phase: 6
- Parent: 617c
- Blocked by: 617a3 (buddies exist)
- Priority: High (nothing else a buddy does happens until it is in the world)

## Current Behavior

**Built 2026-09-27; compile-checked, not yet run.**
`modules/mod-buddies/src/buddies_login.cpp`:

- At an owner's login, the owner is queued; 3 seconds later (tried every
  half second for up to 10 seconds while the owner's bot manager or the
  companion account isn't ready) the companion account is linked to the
  owner's account in `playerbots_account_links` (written directly, since
  the bot manager reads it at once), and the owner's bot manager is asked
  to log in each made buddy.
- At a buddy's login it is queued; a second later it is placed 20-30
  yards from its owner in a random direction with ground there (six
  directions tried; ground within 15 yards of the owner's height),
  facing the owner. Inside a dungeon, raid or battleground it isn't moved
  (617c3's job); with no ground found it stays where it logged in, logged
  as a warning.
- A buddy made while its owner is online (617a3) queues the owner again,
  so it logs in at once.
- Logout: the bot module's own rule logs its bots out with their master;
  nothing added.
- Read 2026-09-27 in `PlayerbotMgr.cpp`: the module allows a player's bot
  when it is on the player's account, in their guild, or on a linked
  account; the "no death-knight bots" setting (C024) only governs random
  bots, so death-knight buddies can log in.
- Tests 2026-09-27: all module files compile-check clean with the build's
  recorded flags plus the bot module's include folders.

**Still to check on a running server**: an owner with made buddies logs in;
they appear 20-30 yards around, facing the owner, and join the clan 5
seconds later (617l); the owner logs out and they go.

## Intended Behavior

- **Owner logs in: every made buddy logs in too**, as the owner's bot, a
  moment after the owner (the bot manager exists only once the owner is
  in the world). A buddy made while the owner is online logs in as soon
  as it is made.
- **Near the owner, not on top**: each buddy appears 20-30 yards from the
  owner in a random direction, on the ground, facing the owner.
- **Owner logs out: the buddies log out**, by the bot module's own rule
  (Ritz, 2026-09-25: "then they log out as well"); what they were doing is
  kept (617a).
- **The link**: each companion account is linked to its owner's account in
  the bot database, written when the owner logs in.

## Suggested Implementation Steps

1. `modules/mod-buddies/src/buddies_login.cpp`: at the owner's login,
   queue the owner; a world-update pass a few seconds later writes the
   link and asks the owner's bot manager to log in each made buddy.
2. At a buddy's login, queue it; the pass places it near its owner.
3. Creation (617a3) queues the owner again, so a new buddy logs in at once.
4. In game: log in an owner with made buddies; they appear around, not on
   top; log out, they go.

## Related Issues

- **617c** parent; **617a3** makes the buddies; **617c2** the party they
  join; **617l** they join the clan after they appear
