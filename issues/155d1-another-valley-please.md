# 155d1 - "Actually, can I go somewhere else?"

## Status
- Created: 2026-10-04
- Phase: 1
- Parent: 155d (rotating faction starting valleys)
- Blocked by: 155d
- Related: 617b (Sargobras; the valley Sargobras stands in every starting
  valley)
- Related files: `src/lua-basic/sargobras.lua`,
  `patches/B028-basic-starting-valley-rotation.sh` (holds the eight valleys'
  positions today)

## Origin

Verbatim, 2026-10-04 (from the unsorted note `new-issue-please-sort`):

> can we add an option to the initial starting valley Sargobras that says:
> "Actually, can I go somewhere else?"
>
> then, it teleports them to a random starting valley of the same faction.
> We should cycle through them without replacement, like a deck of cards,
> that way we can be sure that we will find the one we want in the fastest
> time, without needing more than one button.

> once a character hits level 2, we can drop that option / database record
> for them. If they're ever reset to level 1 for any reason, we can
> re-create it. Question... How would we do that? An on-login lua hook?
> Sounds performatively expensive.

On the design below (each character's own fixed order, stepped from where
they stand):

> ah yes, but it won't be the fastest possible combination of destinations
> you could pick. That'll always be the probabilistic one, because there's
> a chance of getting it faster and no chance of getting it slow. Only...
> There's exactly the same number of outcomes with the same type of
> outcomes as with one in a row, so yeah it's pretty random. But that's
> kinda the point? To make each character shop around. Not the player, who
> knows the order, and not the geography, that is always the same - but the
> random chance of destimagic.

> hearthstone must be set correctly

## Current Behavior

Built 2026-10-05; tested offline (`scripts/test-valley-deal`, 31 checks),
not yet tried in game. It needs the owner's rebuild (B028 changed) and an
install (E023 adds a column) before it works on the server; until then the
Lua option teleports and binds correctly but its +1 to the rotation fails
on the missing column.

- **The one list of valleys** stays in B028's C++ table;
  `scripts/generate-starting-valleys-lua` reads it and writes
  `src/lua-basic/data/starting-valleys.lua` (marked generated), and
  `--check` fails when the two differ.
- **The deck** is `src/lua-basic/lib/valley-deck.lua`: the character's
  order is a Fisher-Yates shuffle of the four driven by a Park-Miller
  generator seeded from its guid (its own numbers, so the shared
  `math.random` is never disturbed); "where it stands" is the nearest of its
  faction's four valleys on its map within 400 yards, else none (the first
  card is dealt). All 24 orders occur, evenly, across 2000 characters.
- **Sargobras** (`sargobras.lua`) shows "Actually, can I go somewhere
  else?" (the wings icon) to a level-1 character who is not a death knight,
  at the valley Sargobras only; on the full buddy menu and also when he
  has nothing else to offer. The choice is checked again on select, so a
  menu left open past level 1 does nothing. He says "<valley>, then. Hold
  still.", binds the hearthstone, teleports.
- **Counting toward the rotation**: B028 keeps its count in memory and
  writes it whole, so a +1 written beside it would be overwritten. A new
  column, `dealt_in_batch`, is the Lua script's own tally: the script adds
  one (`WHERE team = .. AND current_valley = ..`, so a deal into a valley
  that isn't the current one counts nowhere, there being no batch to
  join); B028 reads it fresh at each creation, compares
  `count_in_batch + dealt_in_batch` with 30, and sets it to 0 when it draws
  the next valley. A deal landing between B028's read and its commit can
  be lost (one count, rarely); accepted.

## Intended Behavior

While a character is level 1, the valley Sargobras also offers "Actually,
can I go somewhere else?". Choosing it teleports the character to another
starting valley of its own faction (four per faction, listed in 155d) and
binds its hearthstone there.

**The deck, with nothing stored.** Each character has its own fixed order
of its faction's valleys: the four shuffled with the character's unique id
number (an integer) as the random seed, so the same character always gets
the same order and it can be worked out again at any moment. The
character's place in the deck is the valley it is standing in; the option
deals the valley after it in its order, wrapping round after the fourth.
Pressing it three times visits every other valley once, then returns to
the first. Different characters get different orders, so which valley
comes next is chance for each character ("the random chance of
destimagic"), while the order itself is the character's own.

**Level 1 only, with no cleanup.** Sargobras shows the option only while
the character is level 1. At level 2 it is gone; if a character is ever
returned to level 1, it comes back with the same order. There is no row to
delete or re-create, and no login hook: the only work happens when the
option is clicked.

**The hearthstone.** Every deal binds the hearthstone to the valley dealt,
at the same position and area the creation step (B028) binds a new
character to. A character never hearths back to a valley it chose to
leave.

**It counts toward the rotation.** Each deal counts as one arrival in the
dealt valley's batch of 30 (155d), as a new character does. Owner,
2026-10-04: "let's say yes. you can always just loop back around, so
there's no room for griefing. Once your character is created, no other
player's behavior can affect you. But you affect others, if you choose to
endlessly cycle the map for some weird reason." A character's own deck
order never depends on the rotation, so nobody else's cycling can change
where your next deal lands.

**One list of valleys.** The eight valleys' positions are written today in
the creation patch's C++. The deck must use the same positions, from one
source: a generator writes them into a Lua data file as well, or both read
one data file. They are never typed in twice.

## Suggested Implementation Steps

1. Give the valley list one source: a data file (`src/lua-basic/data/`)
   generated from, or generating, the creation patch's table; a test that
   the two agree.
2. In `sargobras.lua`, add the option to the valley Sargobras's menu for
   level-1 characters (any class he serves; death knights never meet him).
3. On select: work out the character's order (seeded shuffle of the four),
   find the valley it stands in (the nearest of the four; if none is near,
   the deal starts at the first of the order), teleport to the next, and
   bind the hearthstone there.
4. Test offline (a stand-in world, like `scripts/test-sargobras-follow`):
   the same id always gives the same order; four presses visit four
   different valleys and return; the hearthstone matches each landing;
   the option is absent at level 2 and back at level 1.

Remaining: rebuild and install (owner), then in game: a level-1 character
presses four times, hearths after each, and the rotation table's
`dealt_in_batch` rises for deals into the current valley.

## Open Questions

None open. (Answered 2026-10-04: a dealt valley counts toward the
rotation's batch of 30.)
