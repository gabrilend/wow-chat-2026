# 197 - Change a Player's Class, Dressed Like a Buddy

## Status
- Created: 2026-10-25
- Phase: 1
- Related: `scripts/change-character-class` and its planner
  `scripts/lib/class-change-sql.lua` (the class change itself, built),
  186 (gear of equal strength: the other plan for gear after a change),
  187 (a trainer and a purse after a level or class change), 185 (the
  level-up command), 617r and 617r2 (gearsets: what buddies wear), 617r6
  (spec profiles choose the gems), 617j2 (gems and sockets), 621 (a strong
  enchant on a new weapon), 617a7 (the same reset for a buddy)
- Priority: Medium
- State: planned; not built (on the session's to-do list to implement)

## Origin

The owner, 2026-10-25:

> we should also have a separate tool or utility that allows us to change
> a player's class as well, while keeping their level, name, race, gender,
> etc. They should be given a set of gear that is the same set as the
> buddy-bots with the same gemming and enchanting and such rules, and
> their current gear should be mailed to them. For now, let's make it so
> they can't switch to DKs, neither players nor buddy-bots for now.

## Current Behavior

Half built. `scripts/change-character-class <name> <class>` turns a
character into another class with the world server stopped: it backs up
every row it may touch, removes the old class's skill lines, spells,
action-bar buttons, talents, glyphs and pets, adds the new class's skill
lines, and keeps race, looks, position, gear, money, professions, quests,
reputation and buddies. Its gear is left exactly as it was (items the new
class cannot use are listed, not replaced), and it accepts death knight as
a target.

## Intended Behavior

- **Everything that isn't the class is kept**: level, name, race, gender,
  looks, money, professions, reputation, buddies (as the tool does now).
- **Dressed like a buddy**: the character is given the gearset a buddy of
  the new class, its talent shape and level would wear (617r2's records),
  gemmed and enchanted by the same rules buddies follow (617r6's spec
  profiles choosing the gems, 617j2's sockets, 621's strong enchant on a
  new weapon).
- **Its old gear is mailed to it**: everything it had equipped arrives in
  its mailbox, so nothing is lost; the bags are left alone.
- **No death knights**: the tool refuses death knight as a target class,
  for players and buddies alike, saying why ("not offered for now", the
  owner 2026-10-25).

## Suggested Implementation Steps

1. Refuse death knight in `scripts/change-character-class` (and in the
   planner), with a message naming the reason.
2. After the class change: read the character's new talent shape (its
   talents are reset, so the even shape, or one chosen with an option),
   find its gearset record (`src/lua-basic/lib/gearsets.lua`,
   `Gearsets.record`), and write the items with their gems and enchants as
   the buddy kit does.
3. Mail the equipped items: move each to a mail to the character (the
   characters database's mail and mail-item tables), sender the server,
   before the new set is equipped.
4. Tests: a dry run on a test character (the tool's `--dry-run`): death
   knight refused; the new set's items, gems and enchants as a buddy's;
   the old gear in the mail; level, name, race and gender unchanged.

## Open Questions

1. (Answered 2026-10-25: a command-line option, else the even shape)
   "Okay let's pick based on a cli flag. If none is applied, then the even
   spread of points." **Which talent shape** picks the gearset for a player: the class's
   even shape (the player re-spends their talents anyway), or one the
   operator names on the command line?
2. (Answered 2026-10-25) 186 stays, "for level changes and class
   changes". **186's plan** (made copies of the old gear at equal strength) and this
   one (a buddy's set, the old gear mailed): is 186 now only for level
   changes, or retired?
3. (Answered 2026-10-25) "for the class change, just the buddy-gear
   sets." **Which gear after a class change, then:** the buddy's gearset (this
   issue), copies of the old gear at equal strength (186), or both, the
   gearset first and 186's copies when it is built?
