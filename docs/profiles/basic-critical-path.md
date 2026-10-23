# Basic's Critical Path

Written 2026-10-23, at the owner's request: "okay we have like, wayyyyyyy
too many issue files open. Can we pick some that seem *critical* and build
a roadmap to completing them?"

## Where things stand

Open and finished issues by phase: run
`/home/ritz/programming/ai-stuff/scripts/progress-dashboard.lua /mnt/kaun/wow-chat-2026 -m`
(on 2026-10-23: 505 open, 45 finished).

Sorted by what each open issue's own text says (2026-10-23):

- **about 90 are already built.** 45 say outright that they wait for an
  in-game look; about 45 more say "built" without saying what's left.
  This is the cheapest work in the project: each closes with a check in
  game, not with new code.
- **8 mention crashes;** most are fixed or quiet (below).
- **7 are in progress**, about 40 are ideas with open questions, and the
  remaining 350 or so carry no state line (mostly plans not started).

So the critical path is not new features. It is: keep the server
standing, get the built work in front of a player, and close what passes.
Everything not on this page waits.

## Stage 1 - Before the compile (no game needed)

1. **Room on the RAM disk** (`/dev/shm`): the database test of every basic
   change (`scripts/test-basic-sql-in-ram`) needs about 3 GB free; on
   2026-10-23 it had a few hundred MB. Free space, then run it. It covers
   the two newest steps (the boss enchanting scrolls and the Profession
   Mentors), which have only been tried on the real database so far.
2. Nothing else: all code waiting for the compile is written.

## Stage 2 - The compile (the owner)

`scripts/compile`, then `scripts/validate` and `scripts/promote` if the
compile's own test start doesn't promote, then restart the worldserver.
Then `scripts/validate-basic-state`: every check should pass, including
the new ones for the boss scrolls and the Profession Mentors.

Waiting in this compile: death knight talent points (718d), the buddy
quest crash fix and buddies' quest catch-up (617d), the Visiting Mentor's
quiet hiding of other classes' lines (B029, 155e), the boss scrolls (812),
the Profession Mentors (155e1).

## Stage 3 - The first session: is it standing? (about 15 minutes)

Play normally with buddies for a while, turn in a few quests, then read
the server log. Each item closes an issue when it holds:

| Check | Closes |
|---|---|
| Turning in a quest whose reward casts a spell (as "A Fistful of Slivers" does) with a buddy beside you: no crash | the buddy quest crash, within 617d |
| A buddy that was offline logs in caught up on your finished quests (its login line in the server log) | 617d (with stage 4's quest checks) |
| No "nil bot periodic event" crash in the log | 306 (bot crash) |
| The server boots and runs with the bot engine's repair patch (it has since 2026-10-09; confirm in the log) | 308 (bot engine crash) |
| (No check: fixed upstream on 2026-09-09, its patch retired) | 141 (Lua query crash) |
| The Lua engine registry crash has never been seen on basic, only on beta in April | 208 stays open for beta; not on basic's path |

## Stage 4 - A death knight session (about 30 minutes)

Gabrubre and one brand-new death knight. `scripts/dk-story-state <name>`
checks each state from the database.

| Check | Closes |
|---|---|
| Gabrubre's talents reset at login (19 spent, more than 11) and she has 11 to spend; her buddy Throszurg logs in with 11 and spends them | 718d (talent points) |
| `.character level Gabrubre 58`: 49 points | 718d |
| The Ebon Hold shows its after-the-story state, runeforges reachable | 718 (the pledge in the skip) |
| A new death knight: Sargobras, the clan name, the skip, the fall, the rise, 11 points on landing, the pledge done | 718 (the sacrifice, the skip, the rise) |
| A new death knight that plays the story: 0 points in Acherus, then what the quests grant | 718d |

## Stage 5 - A buddy session (about an hour)

The buddy system is the largest built-but-unseen block (about 25 issues).
One session that walks through a buddy's life:

| Check | Closes |
|---|---|
| A buddy is offered, made, and arrives (Sargobras at the valley; its entrance) | 617b, 617b1, 617a2, 617a3 |
| Its kit: gear, food, money, bags | 617a4, 617r1 |
| It is hidden from /who and friends, and locked from others | 617a5 |
| It logs in and out with you, groups with you when near | 617c1, 617c2 |
| It roams, explores, gathers, visits towns (mail, vendor, sleep) | 617e1, 617e2, 617e3, 617e4, 617e6 |
| It follows you across maps | 617e8 |
| It spends talents by its shape; re-rolls when you respec | 617g |
| It rolls on loot sensibly; uses the auction house; plays battlegrounds | 617j, 617h, 617i |
| Its professions; its clan guild | 617k, 617l |
| Dungeon draw and loyalty | 617c3, 617c4 |
| Elite outfits | 617r |

## Stage 6 - A world session (about an hour)

Basic's world changes, built and never looked at:

| Check | Closes |
|---|---|
| Rotating starting valleys; "another valley please" | 155d, 155d1 |
| Talents past the 30-point row refused except capstones | 155g |
| Dungeon damage and healing multipliers; Kazzak weekly | 155i, 155j |
| Outland without quests; Inscription without glyphs | 155l, 155o |
| An ability book (Growth's Book of the Wild: does the learned spell cast at 60?) | 155q |
| No world chat channels; no map or minimap | 155x, 155y |
| A Profession Mentor in Darnassus: lines, lists, look; the goblin dances in Thunder Bluff | 155e1 |
| A classic dungeon boss drops one enchanting scroll | 812 |
| Creatures only one player can select | 164 |
| Druids hearth by Moonglade; group hearthstone | 211a, 211 |

## Stage 7 - The paperwork

For each check that passed: the issue's Current Behavior says so, it moves
to `issues/completed/`, its phase progress file is updated, and a commit
goes in. Also moved to completed, as decided rather than built: talents
from level 1 (155z9) and a death costing rested experience (155z12), both
"will not be built". The "built" issues not checked in stages 3-6 (the
patch system, the custom client's pieces, the documentation tools) are
read once each and closed or given their missing check.

**If every stage passes, about 90 issues close**, and every open issue
left is either in progress or not yet started.

## After the path

Only then new work, chosen from the in-progress list first (the patch
priority queue, 189; the neuron bridge, 162) and then the owner's
newest plans (the death knight's fall and wisps, 718e; weapon
preferences, 625b; monster bots, 634; the gem chain, 155p1 and 155p2).
The issue renumbering (196) is tech debt for later.
