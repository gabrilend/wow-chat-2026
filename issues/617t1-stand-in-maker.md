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
(2026-10-09); not yet built into a server or tried in game, and five
questions below are open.

- `modules/mod-buddies/src/buddies_stand_ins.cpp`: the accounts (STANDIN<n>,
  50 to an account, remembered at startup and hidden through B044's list), the
  bringing in (`BuddyBringStandIn`: race and class drawn or checked, a kept
  one picked and raised, or a new one made; logged in through the random-bot
  manager with no master), the first moments (what a raised level teaches
  and its gear, the talent build, the bot's fighting rules chosen again,
  the move to its place), forgetting a deleted one, and the four
  `.buddy standin` commands.
- `buddies_stand_ins_pick.h`: the choices on plain numbers (trees for a
  role, the shape of one tree, the kept one to use, the side's pairs for a
  role, the build by where its points lie), checked by
  `tests/buddy-stand-ins/pick.cpp` through `scripts/test-buddy-stand-ins`,
  which also applies the table twice and reverts it in `_smoke_test`.
- `buddies_create.cpp`: the making steps shared as `BuddyMakeCharacter`;
  a buddy is made exactly as before, its roster row and owner after them.
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
(617j2). Its talent shape is wholly its role (617t: "a stand-in is wholly
its role"): all its points in one tree that takes the role (shapes 8, 9,
10 of 617g), the tree drawn at random among those that do.

**Accounts**: stand-ins live on hidden accounts of their own, `STANDIN1`,
`STANDIN2`, ..., a set number to an account, made as needed, with a
password nobody is told (as the companion accounts, 617a2), listed as
hidden (B044: not in /who, can't be befriended, take no whispered
commands, B045).

**Brought in** as a bot with no master, through the bot module's
random-bot manager (which only re-rolls bots on its own random accounts,
so it leaves stand-ins as they are). At its first moments in the world it
spends its talent points by the bot module's pre-made build for its class
whose points lie most in its tree, and is moved to the place asked.

**Kept** in the characters database, `buddy_stand_in`: its character, race,
class, role, talent tree, level, levelling track (617t question 7, 0
until decided), times used, when made and last used.

**For game masters and scenes**: `.buddy standin <alliance|horde>
<tank|healer|damage> <level> [race] [class]` brings one in beside the game
master (scenes call it the same way, through the Lua engine's command
runner); `.buddy standin list` shows the kept ones; `.buddy standin
dismiss <name|all>` takes them out of the world, kept.

## Suggested Implementation Steps

1. The characters-database table, with an install step for basic and
   cc-test (cc-test reads basic's buddy SQL).
2. The choosing rules in a header of their own (tree for a role, race and
   class for a side and role, the kept one to use), tested without a
   server like the kit's bag split (`tests/buddy-kit/`).
3. The making: the buddy steps shared between buddies and stand-ins
   (`buddies_create.cpp`), the owner-only parts (roster row, owner's level,
   owner's bags, the owner meeting it) kept to buddies.
4. The accounts, the bringing in, the first moments (talents, place).
5. The command; then the scenes ask for their squads through it.

## Open Questions

1. **How many stand-ins to an account?** The game's own limit is ten
   characters a realm for players; bots aren't held to it, and an Alterac
   Valley match alone wants 80. Fifty an account is the first guess.
2. **Hidden or seen?** Hidden like buddies (not in /who, not befriended,
   no commands) is the first cut. Players are meant to "play one" later
   (617t question 8): does a stand-in then take commands from the player
   playing it, or is "playing" a different thing from commanding?
3. **Names:** stand-ins take names from the same list as buddies. Should
   they look different (a title, a surname, a mark) so a player can tell a
   stand-in from a buddy at a glance?
4. **The tree for damage:** a hunter or rogue has three damage trees; a
   shaman two (elemental, enhancement). Drawn at random (first cut), or
   spread evenly over a squad?
5. **PvP jewellery** (617t: "the best PvP item available at that level"
   where no white exists): not in the first cut; the kit's white gear
   leaves neck, rings and trinkets empty. Needed before the scenes, or
   after?
