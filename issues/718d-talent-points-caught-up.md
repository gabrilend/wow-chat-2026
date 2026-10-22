# 718d - A Death Knight's Talent Points, Caught Up Over 55 to 60

## Status
- Created: 2026-10-22
- Phase: 7
- Parent: 718 (death knight sacrifice and open Acherus)
- Related: 155g (basic's talent cap: nothing past the 30-point row's
  one-point capstones), 718 (the story skip keeps "the talent points ...
  gained from the quests", 2026-10-12, which this replaces), 156 (expert,
  levels 61-80, planned), 718e (where a skipper lands)
- Pattern: `strategems/talents-caught-up-over-first-levels.md`
- Priority: Medium
- State: in progress: the rule is written, waiting for the owner's compile
  and the in-game checks
- First profile: basic

## Origin

Verbatim, 2026-10-22:

> okay can we make issue files to reward 60/5 talent points to DKs at each
> level? It should actually be 6 I think, so 10 talent points per level,
> because it's 55, 56, 57, 58, 59, and 60, which is 6 times that talent
> points should be provided. There should be the correct total amount
> applied but, y'know, better math haha

Then: the total is the 51 every class has at 60 ("yes"), a death knight at
55 having far fewer than today's 46 is intended ("yes"), above 60 "1 per
level", and:

> can we give DK's 11 talent points at level 55? So they can have an extra
> ability to play with.

On the general case (any character that starts above level 10) and where
it should live:

> should be part of the level setting patch. Basically it should compress
> the number of talent points you get into the
> experience-point-level-increment-tracking-progress that you use as your
> kit. Then ideally we could create lots of starting points, like a level
> 46 druid with this type of party etc in these conditions whatever.

> it's just a pattern. It can be in a note. We'll find it if we search for
> that pattern. Every time we find it useful, we add a single-line note to
> the end "found this useful 10/26/26" or etcetera. That way we can tell
> when stuff grows stale...

The arithmetic, asked 2026-10-22 ("starting at level 10, then going to 60
tells me that you'd have 50 talent points"): 51. Level 10 gives the first
point and 60 the last, and 10 to 60 counted both ends is 51 levels; the
server's rule is `level - 9`. Confirmed in game: a death knight that
finished the story inside Acherus at 55 had 46.

## Current Behavior

The rule is written (2026-10-22) and not yet built: the owner compiles.
Until then the stock arithmetic holds.

**Stock** (`Player::CalculateTalentsPoints`, `Player.cpp`; `Rate.Talent =
1` on basic): `level - 9` for every class. A death knight outside Acherus
(any map but 609) has that: 46 at 55. Inside Acherus: `level - 55`, plus
the points the story's quests have granted (46 over 23 quests,
`quest_template.RewardTalents`), never more than `level - 9`. The server
recounts at login, at a level change and when a quest grants points
(`InitTalentForLevel`), and not when a death knight leaves Acherus. That
is why Throszurg (Gabrubre's buddy) had none on 2026-10-22: he logged in
on map 609 (0 points there), was brought to the Plaguelands, and nothing
recounted, so the buddy talent script had nothing to spend.

**Written, waiting for the build:** `src/cpp-basic/basic_rules.cpp`, the
death knight talent points (copied into the server by B030, basic only):
a six-entry table on the server's talent-count hook. A compile-time check
refuses a table that doesn't end at 51.

## Intended Behavior

A death knight on basic has 11 points at 55, then 8 more each level to
60, where it has the 51 every class has; after 60, one a level, like
everyone. Wherever it stands, and whether it played the story or skipped
it.

| Level | Points that level | Points in all |
|------:|------------------:|--------------:|
|    55 |                11 |            11 |
|    56 |                 8 |            19 |
|    57 |                 8 |            27 |
|    58 |                 8 |            35 |
|    59 |                 8 |            43 |
|    60 |                 8 |            51 |
|    61 |                 1 |            52 |
|    80 |                 1 |            71 |

Below 55 (only by a game master's hand) it has 0. Points a game master or
script grants on top (the server's bonus talent count) stay on top.

The general version, any starting level caught up over a few levels, is
a pattern, not a rule: `strategems/talents-caught-up-over-first-levels.md`
(found again by searching for it, with a "found this useful" line added
each time).

## Suggested Implementation Steps

1. ~~The rule~~ (done 2026-10-22): `basic_rules.cpp`, a player script on
   `OnPlayerCalculateTalentsPoints`, the table above, registered with the
   other basic rules.
2. ~~The pattern note~~ (done): in `strategems/`.
3. The owner compiles, validates and promotes (`scripts/compile`,
   `scripts/validate`, `scripts/promote`), then restarts the worldserver.
4. In game:
   - Gabrubre (55, 19 talents spent): at her next login her talents are
     reset (19 is more than 11) and she has 11 to spend;
   - Throszurg: 11 at his next login, spent by the buddy talent script;
   - `.character level Gabrubre 57`: 27;
   - another class at 55 still has 46.
5. `scripts/dk-story-state` shows talents spent against the rule's total
   for the death knight's level (spent: `character_talent` rows of the
   active talent group, counted by rank).
6. A line in `docs/balance-updates.md` for the table.
7. Update 718's story skip text (done 2026-10-22: a pointer here).

## Open Questions

1. **The story's own points, kept** (the owner, 2026-10-22, on whether to
   take the talent rewards out of the story quests):

   > ah... I see... We should leave them are as they are in the story,
   > and change our per-talent distribution to be... Sufficient so that at
   > level 58, the player has as many as they would at the end of the
   > questline, which I think is 46. That way, a level 58 DK has the same
   > amount of talent points if they do the story, and if they don't, but
   > if they don't, they are rewarded as if the DK got them at level up,
   > instead of from quests.

   So the story player earns its points from the quests, as stock, and
   the skipper earns them by level, and the two meet at 58. The facts:
   the story's quests grant 46 points in all, and the stock rule inside
   Acherus adds one a level past 55, so a death knight that finishes the
   story at 58 has 46 + 3 = **49**, not 46. And with 155z9 decided (3 at
   level 1, `level + 2`), every other class has 60 at 58 and 62 at 60.

   A rule that does all of it: a death knight has the larger of (a) the
   level table and (b) what its story quests have granted plus one a
   level past 55; never more than everyone's count. A proposed level
   table, meeting the story at 58 and everyone at 60:

   | Level | Level table | Story finisher | Everyone (155z9) |
   |------:|------------:|---------------:|-----------------:|
   |    55 |          11 | 0, then quests |               57 |
   |    56 |          24 |                |               58 |
   |    57 |          37 |                |               59 |
   |    58 |          49 |             49 |               60 |
   |    59 |          56 |             50 |               61 |
   |    60 |          62 |             51 |               62 |

   The story finisher's 50 and 51 at 59 and 60 would be lifted by the
   level table (the larger of the two), so both reach 62 at 60. Is that
   the shape? Or should the meeting point be the 46 you remembered (the
   quests alone, without the one a level)?

   Building it needs the quests' share read in the hook: the server keeps
   that count in a field with no reader, so the rule would add up the
   `RewardTalents` of the story quests the death knight has been
   rewarded (the story list is `src/lua-basic/data/death-knight-skip-quests.lua`;
   the C++ would read it from the world database at start).
2. **The skipper's quest points.** A skipper is rewarded every story
   quest too (that is how it gets Runeforging and the rest), so (b) gives
   it 46 + 3 at 58 as well, and it equals the story finisher at once on
   landing at 55 (46). Should the skip's rewards not count toward (b),
   so a skipper follows the level table (11 at 55)? (A ledger flag says
   who skipped.)

The table as built (11, 19, 27, 35, 43, 51) predates both answers and
changes once they are in.
