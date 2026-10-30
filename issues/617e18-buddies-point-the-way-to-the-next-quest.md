# 617e18 - Buddies Point the Way to the Next Quest

## Status
- Created: 2026-10-29
- Phase: 6
- Parent: 617e (buddy area adventuring)
- Related: 617e13 (the arc follow: buddies trail behind on a half
  circle), 617d (buddy quest mirroring), 617e4c (questing roads),
  617e6 (exploration), 617e14d (bots questing)
- Priority: Medium
- State: planned

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

Not built. Buddies follow on an arc behind the owner while travelling
(617e13) and spread through the questing area; nothing in their stance
says where to go next.

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
