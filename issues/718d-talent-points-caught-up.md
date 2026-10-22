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

Then, 2026-10-22, after the arithmetic of the story's points (46 from the
quests plus one a level past 55: 49 at 58):

> Hmmmmm I changed my mind, let's do the default of 51 talent points,
> starting at level 10. For DKs this system looks good though. The DKs
> should have the same number of talent points at 58 if they skipped or
> did the story, and they should have the same number of talent points as
> everyone else at levels 58, 59, and 60.

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

A story player therefore already meets everyone: it finishes the story at
about 58 with 46 + 3 = 49, everyone's count at 58, then 50 and 51 as
everyone. Only a skipper (46 at once on landing, from its rewarded story
quests outside Acherus) and a death knight buddy (0, or 46, depending on
where it logged in) differ.

**Written, waiting for the build:** `src/cpp-basic/basic_rules.cpp`, the
death knight talent points (copied into the server by B030, basic only).
On the server's talent-count hook, for a death knight: a soul-ledger row
saying the story is played keeps stock; a skipper (the ledger's skip
flag) or a death knight buddy (no ledger row, named in the buddy roster)
takes the table below; anyone else (no row and not a buddy: one made
before the rule, or a brand-new death knight at its first count, before
the Lua writes its row) keeps stock. A missing ledger is logged once as
an error. A compile-time check refuses a table that doesn't end at 51.

## Intended Behavior

Every class: the stock 51 at 60, one a level from 10 (155z9's talents
from level 1 are not wanted). Death knights:

| Level | Story player (stock)  | Skipper or buddy (table) |  Everyone |
|------:|----------------------:|-------------------------:|----------:|
|    55 | 0 + its quests so far |                       11 |        46 |
|    56 | 1 + its quests so far |                       24 |        47 |
|    57 | 2 + its quests so far |                       37 |        48 |
|    58 |                    49 |                       49 |        49 |
|    59 |                    50 |                       50 |        50 |
|    60 |                    51 |                       51 |        51 |
|   61+ |             level - 9 |                level - 9 | level - 9 |

At 58 a death knight has what everyone has, whether it skipped or played
the story, and from then on it never differs.

No sudden 49 for a story player (the owner, 2026-10-22: "make sure at 58
we aren't just, dumping 49 talent points onto them"): inside Acherus the
stock rule counts the story's points quest by quest (each quest that
grants them recounts), plus one a level past 55, so they arrive along the
way and reach 49 as the story ends. The one way a story player could see
a jump is reaching the Plaguelands map before finishing (stock there is
`level - 9`); the story's map has no way out before its end except a game
master's teleport. To confirm in game.

Nothing for a skipper before the soul is given (the owner: "we don't apply
the level 55 talent points for skippers until they sacrifice a soul
correct?"): correct. Until the trade its ledger row says owed and not
skipped, so it keeps the stock rule: 0 in Acherus, where the Lich King
withholds the first quest. The skip writes "skipped" first, before it
rewards any story quest (`death-knight-souls.lua`, the skip; until
2026-10-22 it wrote it last, and the story's recounts gave a skipper the
stock 46, kept until its next login), so the 11 arrive with the skip. Below 55 (only by a game
master's hand) a skipper or buddy has 0. Points a game master or script
grants on top (the server's bonus talent count) stay on top.

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
   - Gabrubre (a skipper, 55, 19 talents spent): at her next login her
     talents are reset (19 is more than 11) and she has 11 to spend;
   - Throszurg (a buddy): 11 at his next login, spent by the buddy talent
     script;
   - `.character level Gabrubre 58`: 49;
   - a new death knight that plays the story: 0 in Acherus, then what its
     quests grant;
   - another class at 55 still has 46.
5. `scripts/dk-story-state` shows talents spent against the rule's total
   for the death knight's level (spent: `character_talent` rows of the
   active talent group, counted by rank).
6. ~~A line in `docs/balance-updates.md`~~ (done, and a second for the
   meeting at 58).
7. ~~Update 718's story skip text~~ (done: a pointer here).

## Open Questions

None open. (Answered 2026-10-22: the total stays the stock 51; skippers
and story players meet at 58 and match everyone from 58 on; above 60 one
a level; the rule lives in basic's compiled rules, the pattern in a note.)
