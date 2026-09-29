# 617a3 - Buddy Creation

## Status
- Created: 2026-09-26
- Phase: 6
- Parent: 617a
- Blocked by: 617a1, 617a2
- Priority: High

## Current Behavior

**Built 2026-09-26; compile-checked, not yet run.**
`modules/mod-buddies/src/buddies_create.cpp`:

- Every 5 seconds, up to 5 chosen rows (class and race set, no buddy yet)
  become characters on the owner's companion account: the row's race and
  class, a random gender, a random unused name from the bot module's name
  list for that race and gender (checked against the server's name rules
  and reserved names), a random face, hair and beard from the client's
  CharSections.dbc, the owner's current level set before the first save
  (the rest follows at first login, as with the server's own level
  command), no intro cinematic; death knights get Death Gate as the bot
  factory gives it. Then the row gets the character and the time.
- Checked before making anything: the companion account exists (waited
  for up to a minute, since it is written through a queue); the owner
  still exists; the race is of the owner's faction; the race can be that
  class. A failure is logged once with owner, slot, race, class and the
  reason, and the row is retried after the owner's next login.
- The bot module's own factory is not used: it picks a random faction.
  Its steps are followed with the race fixed (read 2026-09-26 in
  `RandomPlayerbotFactory.cpp`); its race-and-gender name groups are
  mirrored as a table, since its own helpers are private to it.
- **Into the clan guild**: once the owner's clan is named (617l), each new
  buddy is added to it at creation; a failure is logged.
- **Death-knight buddies owe no soul**: the death knight sacrifice (718)
  makes every new death knight owe a character at first login and keeps
  it in Acherus until paid. A buddy (a character in `buddy_roster`) is
  now skipped there (`src/lua-basic/death-knight-souls.lua`).
- Tests 2026-09-26: the four module files compile-check clean with the
  build's recorded flags.

**Checked for 617c** (corrected 2026-09-27): basic's config sets
`AiPlayerbot.DisableDeathKnightLogin = 1` (C024, "no death-knight bots"),
but the bot module reads it only in its random-bot system, so it does not
stop a player's own bots: death-knight buddies can log in (617c1).

**Still to check on a running server** (the owner runs it):
1. Write a choice into an owed row by hand, e.g.
   `UPDATE buddy_roster SET class = 1, race = 3, profile = 1 WHERE owner = <guid> AND slot = 1;`
   (a dwarf warrior; 617b will write this for real).
2. Within 5 seconds the log says "made <name> ... for owner <guid>, slot 1";
   the row has the buddy's guid; the character is on account
   BUDDY<guid>, at the owner's level.
3. A choice of the other faction's race is refused with an error naming it.

## Intended Behavior

- **A chosen row becomes a buddy**: when a `buddy_roster` row has a class,
  race and profile but no buddy, the module creates the character on the
  owner's companion account: the row's race and class, random gender,
  name and looks, then raises it to the owner's current level, saves it,
  and writes its guid into the row. 617c then logs it in.
- The row's race and class were chosen by the selector (617b: a picked
  class draws a race of the owner's faction that can play it; a picked
  race draws a class). The profile and role were drawn at the same time by
  617g's shape draw, so the tank-and-healer steering and "no two
  same-class buddies share a shape" are already settled when the module
  sees the row.
- A failure (no name left, invalid race and class) leaves the row as it
  is and logs an error naming the owner, slot, race and class; it is
  retried at the owner's next login, not silently dropped.

## Suggested Implementation Steps

1. In mod-buddies: a world-update pass (every few seconds) over chosen,
   unfilled rows; a creation function in the factory's shape with the
   race fixed.
2. Level: set the level and the matching talent points and stats the way
   the server's level command does, before the first save.
3. Test on a running basic server (the owner runs it): choose a class at
   the selector, see the character on the companion account at the
   owner's level.

## Related Issues

- **617a** parent; **617a4** gives the new buddy its kit; **617b** writes
  the choice; **617c** logs it in; **617g** its talents
