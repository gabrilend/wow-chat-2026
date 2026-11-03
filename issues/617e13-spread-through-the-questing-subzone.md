# 617e13 - Spread Through the Questing Sub-Zone, Measured

## Status
- Created: 2026-10-26
- Phase: 6
- Parent: 617e (buddy area adventuring)
- Related: 617e2 (the roaming core in game), 617e3 (creatures, chests and
  gathering nodes), 617e4 (town visits: going back to sell), 617e10
  (closer in danger), 617o (the navigation mesh decides the walking),
  617c2 (the proximity party)
- Priority: High (the owner, 2026-10-26: "pathfinding is mega bugged")
- State: plan only; nothing built

## Origin

The owner, 2026-10-26:

> oh also, it seems like pathfinding is mega bugged. Can you create some
> tests and do some dynamic measurements to try and get the behavior that
> we want? We mostly want buddy-bots to fill out and evenly space
> themselves through the questing sub-zone that the player is in. They
> should leave when the player leaves, and follow generally as they go to
> a new one. It's okay if they're slow, and if they see an herb or mineral
> node they'll grab that both before leaving, and along the way. Always.
> Also sometimes they get distracted and start fighting, especially if
> you're going back to sell (or a group is) and they have lots of room.
>
> but, let's just create a plan for that now, and focus on the
> recompilation for the crashing fixes.

## Current Behavior

**The owner's spawn zones first, built and compiled 2026-10-31, not
yet seen in game** (question 1): a kind of creature's spawn zone is
the ground round its spawn points in the world's spawn table, a circle
round each as wide as it wanders plus 20 yards (at least 30), read once
when first asked (`buddies_spawn_zones.cpp`, `BuddyInSpawnZone`). A
roaming buddy choosing its next monster (`PreyNear`,
`buddies_roam_strategy.cpp`) takes the nearest whose kind's zone holds
the owner, every overlapping zone counting, before any other; with none
near (the owner on a road, between zones) the nearest of all as before.
Only monsters have zones (kinds with an NPC service, and critters, are
left out); kinds only scripts spawn (the ambush system's) have none. The
spread across those monsters is the roaming core's, as before. The same
zones bound the wandering (617e12, question 7): a waypoint is dropped
unless one of the monster kinds living where the owner stands lives
there too (`BuddySpawnZonesAt`, `BuddySharesSpawnZone`), the area being
the owner's sub-zone already; with no monster living where the owner
stands (a road, a camp) any waypoint of the area will do.

**Following, 2026-10-27; syntax-checked and its core tested, not yet built
or run.** The owner's following design is a pure core,
`roam/buddy_follow_core.h` (the track every 2 yards, her table of side
offsets, the half circle 1 to 2 yards back measured along the track so it
bends with it, the spots shared out by least walking so nobody crosses,
the 10-yard rest with a one-in-ten mingle every 5 seconds), checked by
`scripts/test-buddy-follow-core` (34 checks). The server's behaviour
"buddy follow" (`buddies_follow.cpp`) notes each owner's track four times
a second and walks each follower to its spot (moved onto the navigation
mesh; with no mesh near, the track point it was measured from). It is
the dungeon set's following in place of the bot module's "follow", and
the "told to follow" set of step 5's orders, which are built (617y).
Past five followers they stand in layered arcs (built 2026-10-30 in the
core, compiled 2026-10-31; the owner's answer below): three in the
front arc, two behind in its gaps, two behind them, the last size
repeating for more, each arc 1.5 yards behind the one before
(`ArcSpots` in `roam/buddy_follow_core.h`, the shared half-circle piece
any caller can use; `Settings::layerSizes`, `layerStep`); checked by
`scripts/test-buddy-follow-core` (51 checks, 7 new: the table kept up to
five, 3-2-2 for seven, the gaps, repeating, all behind, no two closer
than 0.9 yards). Before, they spread evenly across the 2 yards, a third
of a yard apart for seven. The mingle interval of 5 seconds is ours.

The roaming core runs in game (617e2) and is checked against its Lua
model offline (`scripts/test-buddy-roam-core`), but there is no
measurement of what buddies actually do in a running world: where they
stand over time, how evenly, whether they follow the owner from one
sub-zone to the next, and what pulls them away. The owner reports it
"mega bugged" (2026-10-26); which parts are wrong has not been measured.

**Seen in game, 2026-10-27** (Feldowinn and six buddies, walking from The
Bulwark in Tirisfal Glades into Western Plaguelands, still in the sub-zone
The Bulwark): the buddies followed into Western Plaguelands, then stopped
at the owner's exact spot, not on the arc round her that every placement
toward a person or a place uses; they kept running back through The
Bulwark; "shoo" said in party chat did nothing (the orders are not built
yet), three stayed circled round her and the rest were "lost in geometry".

**The recorder, built 2026-10-27** (step 1): `src/lua-basic/buddy-spread-recorder.lua`
writes every 5 seconds, on a Debug build only and for game masters' walks
only (the owner: "we will only record our paths in debug mode. and then,
only for GMs"),
each owner's and buddy's map, zone, sub-zone, position, fighting and dead
to `tmp/shared-memory/buddy-spread.tsv`; `scripts/measure-buddy-spread`
prints the spread, following and wandering numbers from it; checked by
`scripts/test-measure-buddy-spread`. Loaded at the next server start (or
`.reload ale`); not yet run on a real walk.

**The first measured walk, 2026-10-27** (Feldowinn from Felstone Field
through The Bulwark, Western Plaguelands side, area 813, to its Tirisfal
side, area 152; 38 samples over 165 s; `scripts/measure-buddy-spread`):
60% of buddy samples in the owner's sub-zone, median 59 yards from her,
41 pairs stacked within 3 yards, 24 samples of a buddy within 2 yards of
her; two sub-zone changes, 10 arrivals with a median of 5 s; Matis and
Lariadel never arrived. Per buddy, two failures show:
- **Stuck**: Matis and Lariadel stood still in 37 of 38 samples, 300-340
  yards off. Matis's trace: "standing by idle" each half second; his
  actions: "buddy roam step" USELESS (he is not in the owner's sub-zone),
  "buddy travel step" USELESS or FAILED, "buddy town step" FAILED. The
  travel step counts as useless when owner and buddy are in "the same
  town" (`BuddyTownArea`, a town circle or a town area), while roaming
  refuses for being in another sub-zone and for the owner being in a town:
  The Bulwark is two sub-zones (152, 813) in one town circle, a gap where
  nothing moves a buddy unless the town visit does, and it failed. When the
  travel step did run it failed (its long walk found no way, from
  (1781.6, -747.7)); Lariadel's 90-second unstick moved her 9 yards, then
  "found no waypoint in area 813" (no clear spot, no sight of the centre,
  or no path).
- **Stacked on the owner**: Kalinlia, Lorneas and Zearea followed (in her
  sub-zone 34-36 of 38 samples) but were within 3 yards of her a third of
  the time: the travel step walks to the owner's exact position
  (`BuddyTravelStepAction::Execute`, `MoveFarTo` the owner), not to a place
  on the arc round her.

**The first fixes, 2026-10-27** (`buddies_town.cpp`, the travel step): in
a build at 01:09 (compiled into it: the 80-yard town rule, since taken out,
and the arc with skipped places); since changed, compile-checked, not yet
in a build: inside the owner's town the town visit has a buddy wherever it
is (the owner, of travelling to the owner inside one town circle: "that's
not intended behavior"; Matis's real trouble was every long walk failing
while the owner was outside the town). Travel ends on an arc in front of
the owner (5 yards out, places 4 yards apart, as wide as the travellers),
its places shared out again at every step, nearest pairs first: a buddy
whose place goes to a nearer one walks to its new place, its waypoint moved
mid-walk (the owner: "not skipped. We should move the other buddy to a
different part of the arc, even as they're in motion"). Three long walks in
a row that found no way unstick it at once, a second unstick in a row
reaching 60 yards instead of 30. The knobs:
`docs/balance-updates.md`, 2026-10-27. Further ideas:
`docs/pathfinding-improvements.md`.

## Intended Behavior

1. **Spread**: the owner's buddies fill the questing sub-zone the owner is
   in, evenly spaced through it, not bunched round the owner or one spot.
2. **Follow by sub-zone**: when the owner leaves the sub-zone, they leave
   too, and follow generally toward the new one; slow is fine. Arriving,
   each takes a place on the arc round the owner (lib/buddy-arc.lua, as the
   hearthstone and the summon place them), the place nearest itself; a place
   another buddy holds or is walking to is not taken, the others shifting
   round (the owner, 2026-10-27).
3. **Gathering, always**: a herb or mineral node a buddy sees is gathered,
   both before it leaves a sub-zone and along the way to the next.
4. **Not distracted**: on the way back to town to sell (the owner's trip,
   or a group's), a buddy does not stop to fight what it passes, even with
   plenty of bag room.
5. **Two orders** (the owner, 2026-10-26: "also there should be a follow
   command that applies to the party and a shoo command that spreads them
   out"): "follow", said to the party, has its buddies follow the speaker
   closely until told otherwise; "shoo" sends them back out to spread
   through the sub-zone (1). Heard wherever it is said, and obeyed by the
   buddies of that context (the owner, 2026-10-26: "should apply to
   whatever context they hear it, so party chat, raid chat, whatever. A DM
   is for just them, and in guild chat it's all of them even if they aren't
   in a party"):
   - party or raid chat: the buddies in that party or raid;
   - a whisper: only the buddy whispered;
   - guild (clan) chat: every buddy of the speaker's guild in the world,
     in a party or not;
   - said aloud (/say, /yell): heard by the speaker's own buddies (their
     clan) within hearing, and no one else's (the owner, 2026-10-27: "if
     it's heard, then follow or shoo. Only to your buddy-bot clan, not to
     the other players").
   Heard as the "go sell" and "attack" orders are (`buddies_orders.cpp`).
   **How following looks** (the owner, 2026-10-27, "this is how they
   should follow the player"): the formation of
   `docs/pathfinding-questing-and-dungeons.md` ("Following"): a half
   circle 1-2 yards behind the owner, "behind" being the way the owner
   came, each buddy within a yard of the owner's trail and walking beside
   it; following starts again only when the owner is more than 10 yards
   away, and until then each buddy mingles (a 10% chance) or stands and
   turns to face the owner, as Sargobras does.

## Suggested Implementation Steps

1. **Measure first** (dynamic measurements, no behaviour changed): a
   recorder that, every few seconds, writes each buddy's position, sub-zone
   (area id), state (roaming, following, fighting, gathering, travelling to
   town) and its owner's position and sub-zone, to a RAM log
   (`tmp/shared-memory/`); the movement trace (`.buddy trace`) is a start.
   From the log, numbers that say how well each behaviour holds:
   - spread: the buddies' share of the sub-zone covered, the smallest and
     mean distance between buddies, the distance from the owner;
   - following: seconds from the owner's sub-zone change to each buddy's;
   - gathering: nodes in sight passed by without being gathered;
   - distraction: fights started while travelling to town.
   A script prints them per run, so a change is judged by its numbers.
2. **A scripted run without a player at the keyboard**, so the numbers can
   be taken again after each change: the owner (or a test character)
   placed in a known sub-zone, then moved to the next on a timeline,
   buddies logged in, the recorder on, the receipt in `output/goodbye`
   with the run's counts (the house rule for programs driven without a
   person).
3. **Offline tests of each rule**, in the Lua model and the C++ core, one
   per intended behaviour: buddies spread in a drawn sub-zone; they leave
   when the owner's sub-zone changes; a node in sight is always taken
   before leaving; a buddy travelling to town picks no fight.
4. **Fix by the numbers**: change the core or the strategy, rerun 2, keep a
   change only when its numbers improve and the others hold. Each run's
   numbers appended to `docs/balance-updates.md` with what changed.

## Open Questions

Gathered 2026-10-28 into 617's own list (questions 1, 10, 12, 39), merged with the
same questions from other sub-issues; answers are written back here.

- **Answered 2026-10-28** (617's question 10): "Never. But we must ensure
  they can navigate the map with ease." No buddy counts as left behind.

- **Answered 2026-10-28** (617's question 2): the formation built here is
  the **arc follow**, for moving distances; the **close follow** (617s's
  ring round the owner) is for combat or when asked. (The owner: "When
  moving distances, we should do an "arc follow" which means they trail
  behind you. When doing a "close follow" in combat or when specified,
  they circle around you.")
- **Answered 2026-10-28** (617's question 12): tests may log in a test
  clan of their own on basic ("they're all testing servers right now"),
  with the realm locked to game masters while a test runs (1100e); never
  on beta.

1. **The sub-zone's edges.** The client's area table gives each sub-zone
   (area id) but not its outline; the area centres (617e2) and the map's
   area grid can. Spread "through the sub-zone": over the parts of it that
   are walkable and hold quest monsters, or all of it? **Answered
   2026-10-30** (asked as "which monsters count as quest monsters", the
   owner, word for word): "any monsters that are in the same spawn-zone
   as the player. Remember, there are overlapping spawn-zones." Buddies
   spread over the monsters of every spawn zone (the fences of one kind
   of creature, 617e14d) the player stands in, all of them where zones
   overlap, whether or not anyone has a quest for them.
2. **How far behind** a following buddy may be before it counts as left
   behind?
3. **A test character for the scripted run**: may the test log in a
   character of its own (a test account), or should it use Feldowinn?
4. **More than five followers**: the owner's table gives the sideways
   places for one to four (five fills its gap). A clan is seven. Ours,
   until answered: evenly across the 2 yards, the ends at a yard each side
   and the middle on the track, which puts seven a third of a yard apart,
   closer than a body is wide. Wider for more (the half circle growing),
   or a second row behind the first? **Answered 2026-10-30** (the owner,
   word for word): "wider but no more than half a circle. Make it dynamic
   too because we'll use semi-circle arc positioning in many situations.
   Could also add a second layer arc, so it's like... maybe 3 in the
   closest radius, then 2 more behind, then another 2 behind them." The
   arc widens with the number of followers up to a half circle, never
   more; past what a half circle holds at a body's width apart, arcs are
   layered behind, 3 in the nearest, then 2, then 2 for a clan of seven.
   The arc placement is one shared piece (a count, a radius, the facing,
   the layer sizes in; the spots out), reused wherever buddies stand in
   a half circle, not built into following alone.
5. **How often a follower at rest rolls its one-in-ten mingle**: every 5
   seconds is ours, until answered. **Answered 2026-10-30** (the owner,
   word for word): "naturalizing NPC behavior is a complex topic. We
   should just build a bunch of activities they could do and try to make
   them feel natural." The mingle stays as one activity among many; what
   a buddy does at rest becomes a set of activities to build and judge
   by feel, not a tuned number. **Built and compiled 2026-10-31, not yet
   seen in game** (`buddies_follow.cpp`, the rest
   activities): when the core's look says mingle, one of five is drawn
   by weight: wander near its place (4, the mingle as it was), talk to
   the nearest fellow follower within 6 yards (3; nobody near: a look
   round), face a random way (2), a small gesture (laugh, point, cheer
   or bow; 2), or sit where it stands until the next walk (1). The
   weights are ours, to be judged in game.
