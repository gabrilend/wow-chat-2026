# 617e11 - Passing Each Other

## Status
- Created: 2026-10-07
- Phase: 6
- Parent: 617e (buddy area adventuring)
- Blocked by: 617e2 (the roaming core in game)
- Related: 617v (kneeling at the fallen: the kneel emote), 609 (gesture
  commands: kneeling as a language), 617c2 (proximity party)
- Priority: Medium
- State: in progress (the swerve, the greeting and the round at login built
  offline 2026-11-06 as the server's core; the Lua model, the gallery and
  the server's part not yet)

## Origin

Asked about crowding at waypoints (617e), the owner, 2026-10-07:

> we need to build an avoidance system anyway. We could maybe do that for
> this task?

And asked what two buddies crossing paths in the open should do:

> ideally, swerve. Maybe wave at each other, or if they're high level
> compared to a low level, stop and kneel for 3 seconds (when neither is
> in combat)

## Current Behavior

**The swerve, the greeting and the round at login, built 2026-11-06
(offline, on a branch for review):** `roam/buddy_passing_core.h` (with its
`.info.md`), plain arithmetic in C++ beside the roam core, checked by
`scripts/test-buddy-passing` (32 checks, a quick test; 19 of 19
deliberately broken versions caught):
- **Meeting**: two walkers projected along their lines three seconds
  ahead, and where they come nearest.
- **Swerve**: closer than their two bodies and half a yard, each bends half
  the shortfall aside, away from where the other will be; in line, they
  keep right and pass on the left (two head on both bend right; the faster
  of two going the same way bends left, the slower right); past someone
  standing, the walker bends the whole way. The bend is a half-cosine out
  and back over four yards either side of the meeting point. In 2,000
  random walkers, every near-meeting passes wider once both bend.
- **Greeting**: within five yards, neither fighting: the lower kneels for
  three seconds to one at least double its level (players included); near
  the same level both wave, the higher first (the lower id at the same
  level) and the other 0.8 seconds later. Clan-mates don't greet in
  passing (the owner: they greet only at login). A player is greeted and
  knelt to, never made to.
- **The round at login**: nearest clan-mate first, then the nearest to
  that one; each walked to and waved at, then a pause of one to two
  seconds, or, a quarter of the time, a chat of /talk emotes each with a
  one-in-five chance of being the last (five on average, checked over
  20,000 rounds).
Not built: the Lua model's swerve and the gallery's animation (steps 1 and
2; the core was written in C++ first, the server's language, as the roam
core's port was); the waypoint crowding rule's new direction (step 3: it
changes the roam core and the Lua model together, which are tested against
each other, and the gallery's figures); and the server's part (step 5:
each movement update's neighbours, the bend applied to the path, the
emotes, the round at login).

Before: Buddies don't see each other while walking. The roaming model checks for
others only when it places a waypoint: someone within 5 yards of a new
waypoint moves it 10 points of Y. Measured, that moves about 1 waypoint
in 20, because buddies mostly meet while walking, not at waypoints. In
game, two bots on crossing lines walk through each other, as stock
playerbots do.

## Intended Behavior

Buddies avoid each other (and players) as they walk, and greet as they
pass.

- **Swerve.** A buddy watches the others near its path. If one will come
  within both their body radii of it in the next few seconds, it bends
  its path to pass beside them. It bends the way the path planner bends
  around a rock (a half-cosine ease out and back), on the side that
  costs less. Both buddies may swerve. Each moves half of the way.
- **Greet.** As two buddies pass within a few yards of each other, and
  neither is in combat:
  - near the same level: one or both wave (the wave emote) as they pass;
  - a much higher level passing a much lower one: the lower one stops
    and kneels for 3 seconds (the kneel emote), then goes on.
- **Crowding at waypoints** (617e's rule, revised 2026-10-07): someone
  within 5 yards of a new waypoint moves it 10 points *toward the
  middle* if the waypoint is in the inner half of the area's radius, and
  *toward the edge* if it is in the outer half.

## Suggested Implementation Steps

1. In the roaming model (`src/lua-basic/lib/buddy-roam.lua`): each step,
   project every nearby buddy's position a few seconds ahead along its
   path. If two projected paths come within the sum of the two body
   radii, bend the path.
2. An animation in the gallery (`scripts/generate-buddy-roaming-gifs`):
   two buddies on crossing lines, before and after.
3. The waypoint crowding rule's new direction (inner half toward the
   middle, outer half toward the edge), with the generator's figures
   before and after.
4. The greeting: who counts as "much higher level", the distance, and
   which buddy waves first. Draw the kneel in the model as a 3-second
   stop.
5. In game (617e2's core): the same checks on the server, every movement
   update, using the bots' current positions and destinations.

## Open Questions

Gathered 2026-10-28 into 617's own list (question 4), merged with the
same questions from other sub-issues; answers are written back here.

- **Answered 2026-10-28** (617's question 4, clan-mates): "Clanmates only
  greet each other when they log in. They should walk to each clan mate
  and greet them, wait a second or two, and then greet someone else.
  Sometimes that second or two becomes a chat that has a 20% chance of
  ending after every /talk emote." So: at login, each buddy walks to each
  clan-mate in turn, greets, waits a second or two, moves on; now and then
  the pause becomes a chat of /talk emotes, each with a one-in-five chance
  of being the last.

- **Answered 2026-10-28** (617's question 4, in part): the lower one kneels
  to anyone at least double its level; players are passed, greeted and
  knelt to like anyone else. Whether clan-mates greet each pass stays open.

1. **"Much higher level":** how many levels apart before the lower one
   kneels? For example 10 levels, or a share of the level such as
   double? (Answered 2026-10-28, above: double.)
2. **Players:** do buddies also swerve around players, wave at them, and
   kneel to a much higher-level player? (Answered 2026-10-28, above: like
   anyone else.)
3. **Buddies of the same clan** (617l): do they greet each other every
   time they pass, or only the first time after being apart for a while?
   **Decided 2026-11-06 (the agent's call, from the owner's answer
   above):** neither: "Clanmates only greet each other when they log in",
   so in passing they swerve but don't wave or kneel; the round at login is
   their greeting.

## Decisions (2026-11-06)

The agent's calls while building the core, for the owner to curate; each
is one constant in `roam/buddy_passing_core.h`:
- **How far ahead**: three seconds ("the next few seconds").
- **Room between bodies**: half a yard beyond the two bodies.
- **Which side**: away from the other; in line, keep right and pass on the
  left, so two head on never both step the same way.
- **The bend**: a half-cosine over four yards before and after.
- **Who waves first** (step 4's question): the higher level, then the
  lower id at the same level; the other answers 0.8 seconds later.
- **"A few yards"**: five.
- **"Sometimes" a chat**: a quarter of the greetings at login.
- **The round's order**: the nearest first, then the nearest to that one.
- **Players are never moved by it**: a player is greeted and knelt to;
  the swerve is asked only for buddies (a player's walker is the other).
