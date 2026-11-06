# 617e18 - Buddies Point the Way to the Next Quest

## Status
- Created: 2026-10-29
- Phase: 6
- Parent: 617e (buddy area adventuring)
- Related: 617e13 (the arc follow: buddies trail behind on a half
  circle), 617d (buddy quest mirroring), 617e4c (questing roads),
  617e6 (exploration), 617e14d (bots questing)
- Priority: Medium
- State: step 1 and the arc's part of step 3 built offline (2026-11-06, on a branch for review)

## Origin

The owner, 2026-10-29:

> hey can you look up the Questie or Questmaster or... I forget the term
> but there's one that's purple. The addons that help people quest. Can
> you look those up? Then, can we have the buddy-bots guide the player
> toward the next quest they should attend to? Quest helper, I think that
> was it? Anyway, the buddy-bots should stand on their arc in the
> direction of the next best quest to work on. They can also direct you to
> places you haven't been yet, if it's time to move on. So, you know you
> can always follow your buddies to find treasure and renown.

## Current Behavior

Not built in the server. Buddies follow on an arc behind the owner while
travelling (617e13) and spread through the questing area; nothing in
their stance says where to go next.

**The choice and the lean, built 2026-11-06 (offline, on a branch for
review):** `roam/buddy_next_quest_core.h`. `Choose` takes the quests
(level, minimum level, the quest before, giver, ender, objective spots),
the owner (level, position, done quests, log with the objective spots
left) and the places with whether each is explored, and gives the hint:
a quest in the log (its nearest objective left, or its ender once every
objective is done), else a quest to take (its giver), else the nearest
place not explored, else nothing. Within each the lowest cost wins:
yards walked, plus 60 for each level off the owner's, less 40 for each
other objective or giver within 60 yards of the target, less 100 for a
quest whose chain is started; gray quests (6 or more levels under) are
passed over. `LeanPlaces` turns the arc follow's places (617e13) to the
owner's side facing the target; `Beckon` is the spot one buddy steps to
(5 yards that way) while the owner stands; `Words` says it when a buddy
is whispered "where next?". Checked by `scripts/test-buddy-next-quest`
(48 checks, a quick test) on a made-up starting valley. Not yet: the
server's reading of the world and character tables, choosing again when
the log changes or the owner moves far, the switch, `.buddy next`, and
the whisper itself (step 2 and the rest of step 3).

The questing addons looked up (2026-10-29):
- **Questie** marks quest givers and objectives on the map and minimap;
  a fork, Questie-335, runs on the 3.3.5a client.
- **Carbonite** circled quest areas on its map and listed objectives
  (Burning Crusade and Wrath era).
- **Zygor Guides** routes a whole levelling path with a waypoint arrow; a
  remastered viewer runs on 3.3.5a.
- **QuestHelper** (the original "quest helper") planned the shortest
  route through all objectives; it is no longer maintained.
Which one is "the purple one" was not found.

Each of them carries its own database of where quests start and where
their objectives are. The server has the same facts in its world
database (who gives each quest, its level, what comes before it, which
creatures and objects its objectives need and where they stand), so the
buddies need no addon.

## Intended Behavior

- **The next best quest**, chosen for the owner from the server's own
  tables: quests in the owner's log first (the nearest objective not yet
  done), then quests they can take (a giver nearby, the right level, the
  quest before it done), scored by level fit, distance, how many
  objectives lie together (a route through several, as QuestHelper did),
  and chains already started.
- **Buddies lean that way.** While following, the arc the buddies stand
  on (617e13) turns toward the next best quest: they gather on the side
  of the owner that faces it, so a glance at your buddies says where to
  go. Standing still, one buddy steps a few yards that way and waits.
- **Time to move on.** When the area's quests are done or too low for the
  owner, the buddies lean toward places the owner hasn't been yet (the
  explored areas the server keeps per character), nearest first: "you can
  always follow your buddies to find treasure and renown".
- **Never forced.** Leaning is a hint in the formation, not a leash; the
  owner can ignore it, and a whisper ("where next?") can ask a buddy to
  say it in words.
- **Behind a switch**, off until turned on.

## Suggested Implementation Steps

1. The next best quest as arithmetic over plain tables (quests, givers,
   objectives and their spawn points, the owner's log and completed
   quests), with an offline test on a few known starting areas.
2. The server side: the tables read once at start, the owner's choice
   worked out when their log changes or they move far.
3. The arc's facing turned toward it (617e13's formation), with the
   unexplored-place fallback, and `.buddy next` for game masters to see
   what was chosen and why.

## Open Questions

1. Should the hint also be spoken now and then (a buddy saying "the
   murlocs we need are down by the shore"), or only shown in where they
   stand? **Answered 2026-10-30:** "nah". Only where they stand.

## Decisions (2026-11-06)

The agent's calls while building `roam/buddy_next_quest_core.h`, for the
owner to curate (tuning goes to docs/balance-updates.md):
- **The log always comes first.** Any quest in the log, however far, wins
  over any quest to take; a quest to take is only offered once the log
  holds nothing worth doing (all gray, or empty). The issue's order
  ("quests in the owner's log first ... then quests they can take") read
  as tiers, not as one score.
- **A finished quest points to its ender.** A quest in the log with every
  objective done is handed in: its target is whoever takes it in, scored
  like any log quest.
- **Gray is 6 or more levels under the owner**, about the game's own gray
  at low levels; gray quests are passed over in the log and to take, and
  their spots don't count as lying together.
- **The scores, in yards of walking**: 60 a level off the owner's, 40
  less for each other objective or giver within 60 yards of the target,
  100 less for a quest whose chain is started (it has a quest before it).
  A first guess; the test pins each one.
- **Time to move on is the last resort**: the nearest place not explored
  is offered only when no quest is left in the log or to take.
- **Leaning buddies face the owner**, as on any arc; standing on the
  target's side says the way. Standing still, one buddy steps 5 yards
  toward the target ("a few yards"), never past it.
- **The hint in words** (`Words`) is used only when a buddy is whispered
  "where next?"; never spoken unasked (answered 2026-10-30).
