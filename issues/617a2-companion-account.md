# 617a2 - Companion Account

## Status
- Created: 2026-09-26
- Phase: 6
- Parent: 617a
- Blocked by: 617a1
- Priority: High

## Current Behavior

**Built 2026-09-26; compile-checked, not yet run** (needs the owner's
build and a server). `modules/mod-buddies/src/buddies_clan.cpp`, with
`buddies.h` shared across the module's files:

- **Character made**: clan row, companion account `BUDDY<owner guid>`
  with a random 16-hex-digit password that is never stored or shown, and
  slot 1 owed. A death knight made at 55 is owed slots 1-6 at once.
- **Death knights are owed nothing by level** (2026-09-26): a death-knight
  owner gets its account and clan row, and exactly four buddies at the
  soul trade (617b, 718).
- **Level reached** (any jump, one level or many): every slot whose level
  is reached (1, 10, 20, ... 60) exists as a roster row.
- **Login**: the same two steps again, catching up characters made before
  the module was installed or whose account creation failed.
- **Character deleted**: the companion account is deleted with the
  account manager's own delete (which deletes its buddies and logs out any
  online), then the owner's rows. **A deleted buddy** (by a game master)
  puts its roster row back to owed, so the owner chooses again.
- **Player account deleted**: each of its characters' clans is removed
  first (whole-account deletion skips the character-delete event).
- **Buddies are skipped** everywhere: a character on a companion account
  gets no clan of its own. An account counts as a companion when it is
  recorded in `buddy_clan`, or is named BUDDY<digits> and that owner has a
  clan row (a player-registered "BUDDY7" alone doesn't count).
- **Why the account id is looked up by name**: the account manager writes
  new accounts through the login database's queue, so the id doesn't
  exist yet the moment the account is made. The name is fixed, so the id
  is found by name when first needed and then recorded in `buddy_clan`.
- Failures are logged as errors with the owner and the step, and retried
  at the owner's next login; nothing is silently skipped.
- Tests 2026-09-26: the three module files pass a compile check with the
  build's recorded flags (the by-hand method in 617a1);
  `scripts/test-source-patches <dir> basic` round trip clean.

**Still to check on a running server** (the owner runs it):
1. Make a character: the log says "companion account BUDDY<guid>
   created"; `buddy_clan` has its row, `buddy_roster` has slot 1.
2. `.levelup 20` on it: slots 2 and 3 appear.
3. An existing character logs in: its clan, account and slots appear.
4. Delete the character: the BUDDY account and both tables' rows are gone.

## Intended Behavior

- **One hidden account per owner character** (Ritz, 2026-09-25: "one
  buddy bot account per character created"), made when the character is
  created: a name derived from the owner's character guid, a long random
  password never stored or shown, so nobody can log into it. Recorded in
  `buddy_clan`.
- **The first slot is owed at creation**: a `buddy_roster` row, slot 1,
  no buddy yet (617b's valley selector fills it). The later slots are owed
  as the owner reaches 10, 20, ... 60.
- **Deleting the owner deletes everything**: every buddy character on the
  roster, the companion account, and the owner's rows in the buddy
  tables.
- **Death-knight owners** (718): the account is made the same way; their
  owed slots are filled straight away with death knights (617b).
- Characters that existed before this was installed get their account and
  owed slots at their next login.

## Suggested Implementation Steps

1. In mod-buddies: a player script answering creation (account + clan row
   + slot 1), level change (owe a slot at each tenth level), login
   (catch-up for older characters), deletion (buddies, account, rows).
2. Test on the in-RAM server databases: create an owner, check the
   account and rows; delete it, check all are gone.

## Related Issues

- **617a** parent; blocked by **617a1**; **617a3** fills the owed slots
  this opens; **617b** the selector that chooses them
