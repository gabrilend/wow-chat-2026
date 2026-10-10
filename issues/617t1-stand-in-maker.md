# 617t1 - The Stand-in Maker

## Status
- Created: 2026-10-09
- Phase: 6
- Parent: 617t (dungeon stand-ins)
- Blocks: 176a1 (Alterac Valley's 40 a side), 176a2b (Arathi Basin's
  squads), 617t's dungeon seats
- Related: 617a3 (making a buddy: the same steps), 617a4 (the kit), 617j2
  (sockets), 617c3 (roles), B044 (hidden accounts)
- Priority: High (both test scenes wait on it)

## Origin

The owner, 2026-10-08, ordering the work: "Then, let's do the stand-in
maker, which honestly might need to go earlier in the test." And
2026-10-09: "Then let's work on the stand-in builder."

## Current Behavior

In progress: written and compile-checked against the new pins
(2026-10-09); not yet built into a server or tried in game. Every question
below is answered; what is left is building it and trying it in game.

- `modules/mod-buddies/src/buddies_stand_ins.cpp`: the accounts (STANDIN<n>,
  200 to an account, remembered at startup and hidden through B044's list),
  the bringing in (`BuddyBringStandIn`: race and class drawn or checked, a
  kept one picked and raised, or a new one made with a shape of its role;
  logged in through the random-bot manager with no master), the first
  moments (what a raised level teaches, its gear and jewellery again, the
  bot's fighting rules chosen again for its talents, the move to its
  place), forgetting a deleted one, and the four `.buddy standin` commands.
- Talents: spent by its shape by the buddies' own script
  (`src/lua-basic/buddy-talents.lua`, which now reads a stand-in's shape
  from `buddy_stand_in`), at login and on each level. cc-test runs the same
  file in place through a one-file loader, `src/lua-cc-test/buddy-talents.lua`.
- PvP jewellery (`BuddyGivePvpJewellery`, `buddies_kit.cpp`): the neck, two
  rings and two trinkets from what vendors sell for honor or arena points
  at or below its level, its class and race allowed, scored by its shape as
  the gems are; the best necklace, the two best rings and trinkets. The
  battleground faction standing they need is given (the server won't let
  it wear them otherwise); items needing an old honor rank are left out.
- `buddies_stand_ins_pick.h`: the choices on plain numbers (each shape's
  role as the talent generator gives it, the shapes of a role, the side's
  pairs for a role, the kept one to use), checked by
  `tests/buddy-stand-ins/pick.cpp` through `scripts/test-buddy-stand-ins`,
  which also compares all 100 shape roles with the generated buddy talent
  data and applies the table twice and reverts it in `_smoke_test`.
- `buddies_create.cpp`: the making steps shared as `BuddyMakeCharacter`;
  a buddy is made exactly as before, its roster row and owner after them
  (a switch turns the PvP jewellery on for stand-ins only).
- Stand-in accounts skip every player-only step (`BuddyIsNotAPlayer`: no
  hidden account or owed slots of their own, no dungeon draw, no stage
  check, no quest rewards passed on) and share the buddies' hiding, the
  professions catch-up and running when a fight starts.
- The table `buddy_stand_in` (characters database), install step E056 for
  basic and cc-test; the commands' help in `config/custom-gm-commands.lua`
  (and the reference generated from it).

Before this, a character could only be made as a buddy, for an owner, into
a roster slot (617a3), and logged in through its owner's bot manager;
nothing made a character that belongs to nobody.

## Intended Behavior

One mechanism every user of stand-ins asks: "a stand-in of this side and
role, at this level, here", answered with a character in the world.

**Asked for by** side (Alliance or Horde), role (tank, healer, damage) and
level, with race and class optional (otherwise drawn at random among the
side's pairs whose class can take the role: 617t, "a random class and race
of the player's faction that can take the role").

**Kept before made** (617t, "Reused anywhere above"): a kept stand-in of
that race, class and role, not in the world, at or below the level, is
used first, the highest such; raised to the level if below it. Its level
never goes down. Only when none fits is a new one made.

**Made** by the buddy steps (617a3) with no owner: a name from the bot
module's list, looks from the client's tables, every spell up to its level
from trainers and quests, the professions, the kit's white gear by its
talent shape (617a4, no bags: it has no owner to match), sockets filled
(617j2), and the best PvP necklace, rings and trinkets of its level
(617t's rule for the slots white gear can't fill). Its talent shape is
drawn as a buddy's would be: one of its class's ten (617g) whose role is
the one asked for, at random (owner, 2026-10-09: "pick a spec profile, same
as buddy-bots. It's okay if there's two of one type in a squad"). This
replaces 617t's "wholly its role": a two-thirds-holy, one-third-
retribution paladin is a healer, as it is for a buddy.

**Accounts**: stand-ins live on hidden accounts of their own, `STANDIN1`,
`STANDIN2`, ..., 200 to an account (the ten-a-realm limit is only the
character screen's, which stand-ins never see; the login database counts
an account's characters in one byte, so 255 is the ceiling), made as needed, with a
password nobody is told (as the companion accounts, 617a2), listed as
hidden (B044: not in /who, can't be befriended, take no whispered
commands, B045).

**Brought in** as a bot with no master, through the bot module's
random-bot manager (which only re-rolls bots on its own random accounts,
so it leaves stand-ins as they are). Its talent points are spent by its
shape at login, by the buddies' talent script; at its first moments in the
world it chooses its fighting rules for those talents and is moved to the
place asked.

**Kept** in the characters database, `buddy_stand_in`: its character, race,
class, role, talent shape, level, levelling track (617t question 7, 0
until decided), times used, when made and last used.

**For game masters and scenes**: `.buddy standin <alliance|horde>
<tank|healer|damage> <level> [race] [class]` brings one in beside the game
master (scenes call it the same way, through the Lua engine's command
runner); `.buddy standin list` shows the kept ones; `.buddy standin
dismiss <name|all>` takes them out of the world, kept.

## Suggested Implementation Steps

1. The characters-database table, with an install step for basic and
   cc-test (cc-test reads basic's buddy SQL).
2. The choosing rules in a header of their own (shapes for a role, race
   and class for a side and role, the kept one to use), tested without a
   server like the kit's bag split (`tests/buddy-kit/`).
3. The making: the buddy steps shared between buddies and stand-ins
   (`buddies_create.cpp`), the owner-only parts (roster row, owner's level,
   owner's bags, the owner meeting it) kept to buddies.
4. The accounts, the bringing in, the first moments (talents, place).
5. The command; then the scenes ask for their squads through it.

## Open Questions

1. (Answered 2026-10-09) **Stand-ins to an account:** "Can we do more than
   10 on the backend? The stand-ins of course never need to see the
   character select screen." Yes: 200 (above).
2. (Answered 2026-10-09) **Hidden or seen:** "they should be able to play
   them like any other WoW character." Playing is controlling it directly,
   as one's own character, not whispering it commands. Asked whether a
   played stand-in shows in /who and can be befriended, and goes back to
   hidden after: "no change" (hidden throughout). Taking one over is
   deferred (the owner, 2026-10-09: "We can defer this aspect for a while.
   Until the custom client lets us draw a UI for selecting one maybe"):
   not part of this issue.
6. (Answered 2026-10-09) **No death knight tanks:** a buddy's death knight
   shapes are all damage (the talent data marks no Blood tank tree), so a
   stand-in death knight is never a tank, and "I think that's okay? Death
   Knight characters only ever get death-knight buddies". A death knight
   owner has exactly four death knight buddies, from the soul trade in
   Acherus (718; owed nothing by level, buddies_clan.cpp), all damage: in
   a dungeon from level 30 its missing tank and healer are stand-ins
   (617t's missing-role rule). **Reputation:** standing given for the PvP
   jewellery: "great".
3. (Answered 2026-10-09) **Names:** no mark ("nah. Their gear will give it
   away").
4. (Answered 2026-10-09) **The talents:** "pick a spec profile, same as
   buddy-bots. It's okay if there's two of one type in a squad." (above)
5. (Answered 2026-10-09) **PvP jewellery:** "let's do it now, why wait?"
   (above).
