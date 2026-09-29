# 617e - Buddy Area Adventuring

## Status
- Created: 2026-09-23
- Phase: 6
- Parent: 617
- Blocked by: 617c
- Priority: Medium
- Sub-issues: 617e1 (the buddy roam strategy), 617e2 (the roaming core in game), 617e3 (creatures, chests and gathering nodes), 617e4 (town visits, with area-change travel), 617e5 (fighting together), 617e6 (exploration modes in game), 617e7 (a zone seen from above); death handling, tunnels and the exploration ("painting") design stay here until split

## Origin

Verbatim, 2026-09-23 (617 has the full answers):

> They try and fight the same creatures in the same area that you do, but
> they might be on the other side of the patch of mobs and that's okay. You
> only share exp when you're close, and they don't try to stay near - they
> just attack mobs as if the NPC bot was fighting in that particular area on
> their own.

> yes it comes back to life. It'll move to the areas that the player is in
> when it can.

And for towns, verbatim, 2026-09-23:

> they should stay in the same area as you. So if you're in town, they should
> wander around town and stand in front of random NPCs, do some talking
> animations, then walk to another NPC. Walk, not run. A random NPC in the
> area. When you're in a town or a city, you should be un-grouped with them
> too.

## Current Behavior

**The roaming model, 2026-09-27, being designed with animations; nothing
runs in game.** `src/lua-basic/lib/buddy-roam.lua` (no server calls) picks
each buddy's next step inside the named area: a ring of twelve candidate
steps and standing still, steps into a rock or out of the area refused,
the rest scored by one of three readings of the owner's pinwheel ("far
enough" lists per step, a spring to the spacing, lists per circling
direction); a fourth reading, the owner's waypoint pinwheel (below), which
walks toward a waypoint instead of scoring steps, with an optional blend
that keeps waypoints apart; plus the join/leave rule of 617c2 (54 / 75
yards, four seats). The waypoint reading takes the owner's rule for the
distance from the centre (a percent 1..100 moved 1..20 points in or out
at even odds, never under 10 yards; the bearing turns a tenth of a circle
each waypoint), and either walks straight and orbits obstacles it knows,
or plans each trip with the owner's path planner (test points one body
width apart, height steps found and bulged round, bows weighed by slope
and road). A waypoint landing within 5 yards of another buddy moves 10
points toward the middle of the way out; a tunnel's mouth near a bearing
pulls that waypoint into it; a buddy whose way is walled turns at a point
in sight of both ends. The rest chance at a waypoint is in the model too.
`scripts/generate-buddy-roaming-gifs` runs it on a drawn mine-sized area
(and a cluttered copy with crates, small rocks, raised ground, hills and a
road, and a chamber with a side tunnel) and writes the gallery's
animations (twenty-one as of 2026-09-27; `BUDDY_GIF_ONLY=<name>` renders one).
The model also holds the painting design as its own reading ("paint",
off unless asked for: a clan's paint grid with sight-line deposits out to
60 yards, the walls' paint (a pulse every 3 seconds topping the ground
within 5 yards of a wall up to a level, most at the wall: it does not
pile up, so a tunnel's edges stay more painted than its middle; drawn
blue-grey), grid paths that lean through unpainted ground, rooms and
tunnels found from each spot's distance to the outline
(`Roam.paint_rooms`: at least 7 yards deep is a room's core, the ground
within 7 yards of a core joins its room, the narrow rest is tunnel), and
five ways of choosing: today's pinwheel, the pinwheel choosing by paint,
least paint with no pinwheel, the pinwheel run in the squished circle (a
harmonic map of the area onto a disc, `Roam.paint_disc_map`), and the
room orbit (the owner's pinwheel round the middle of the room the buddy
is in, until the room is 80% explored; then the paint draws it to the
least explored room or tunnel, dead ends included, farther from the
entrance weighing more; once all are past 80%, to the least explored if
clearly less explored than where it is). Animation 19 compares the first
four on a new
arena (a hall with an L-leg, a dead end, and tunnels to two rooms, 240 by
170 yards), with measures printed by the generator: the plain pinwheels
never leave the hall (every waypoint is on a straight line from the
centre, and in an L the centre sees no tunnel), least paint explores
fastest but revisits most, the squished circle explores everything with
the fewest revisits (regenerated 2026-09-27: the walls' paint had been too
weak to matter, 8 added per pulse, and was never drawn). Animation 20 is a
drawn simulation of fighting together (617e5): a tank gathering linked
packs to a gathering spot and, like the owner's blender, taunting any
other monster within 30 yards into the fight (the elite beside the first
pack now dies in the first fight), area spells, a rogue hopping, a healer,
a hunter coming to help, a mage's frostbolt and blink. Animation 21
compares least paint (the owner's favourite), the room orbit with and
without the walls' paint, and the squished circle: the room orbit
explores every room and tunnel (a first version counting a room done at
80% stopped at 88%), and with the walls' paint spends less time near
walls and walks nearer tunnels' middles, at the cost of more revisits
(buddies share the middle lines). The gallery (the GIFs are
linked beside the page, not embedded, since twelve embedded passed the
16 MB page limit),
`docs/HTML/buddy-roaming.html` (published:
https://claude.ai/artifact/WCkc7JyrBVXA4pbfNzP1vY). Three model fixes came
from watching the frames: the default spacing is 0.6 of an even share (the
whole share pinned buddies to the edges in pairs); a push back from the
area's edge within 12 yards; spacing scored by distance and as the gain
over standing still, scaled to the step (a yes/no count, or a raw score,
left a buddy inside a crowd with no reason to leave).

Stock: bots in a master's group follow the master by default. Random bots
grind where the module sends them. Neither is "in my area, on its own".

## Intended Behavior

- A buddy's playground is the owner's current **area**: the named place
  shown on screen on entry (e.g. "Fargodeep Mine" inside Elwynn Forest). It
  fights what lives there and doesn't follow the owner. Grouped buddies stay
  inside the owner's experience radius, ungrouped ones outside it (617c).
- **In a town or city** the buddies are ungrouped (617c) and don't fight.
  Each walks (never runs) to an NPC in the area, stands before it and plays
  talking animations, then walks to another. Which NPC is weighted
  (Ritz, 2026-09-23):
  - **merchants**, with priority equal to how full the buddy's bags are
    (half-full bags: 50% priority); at a merchant it sells what the bot
    module already considers junk or surplus;
  - **its class trainer**, first, when it has spells it could learn;
  - otherwise a random NPC.
  In towns with services, this is refined by 617h's errand list (repair,
  trainer, auction house, vendor, in a durability-driven order) and its
  wandering rule (Ritz, 2026-09-24).
- When the owner changes area, buddies travel there on foot, as a player
  would.
- When a buddy dies it resurrects (spirit healer or corpse run, like a
  player) and makes its way back to the owner's area.
- Grouped buddies share experience only when in range (stock rule);
  ungrouped buddies earn their own.

### Decisions, 2026-09-25 (Ritz)

- **Hearthstones.** "buddies will put their hearthstone to the same spot as
  the player. Except, they'll make a ring around the innkeeper, with the
  radius defined by the distance from the innkeeper in the player's bind
  location. Then, when they have a moment (not in combat, not dead, etc)
  they'll hearth after the player does. As soon as a player successfully
  hearths (they cancel if the player cancels, and they can never complete a
  hearthstone teleport faster than the player because the player initiates
  and they take their time) then they have 'use your hearthstone' added to
  their todo list permanently until they complete a hearthstone teleport.
  [...] Worst case scenario, they could just walk to where the player is,
  though that's annoying."
  - When the owner binds, each buddy binds at the same inn, at a point on a
    circle round the innkeeper whose radius is the owner's distance from
    the innkeeper, spread round the circle.
  - A buddy starts its hearthstone only after the owner starts theirs, and
    cancels if the owner cancels; it can't arrive first.
  - Once the owner's hearthstone lands, "use your hearthstone" stays on the
    buddy's to-do list until it has hearthed (after combat, death, a
    cooldown), then it teleports home. Walking there is the fallback.
- **Towns behave by what they have** ("we should dynamically create
  behavior based on what the town has. Some towns don't even have repair
  stations."): a buddy's town to-do list is built from the services the
  town actually offers (repair, trainer, mailbox, auction house, vendor),
  one system for every town, with 617h's order where both apply.

### Decisions, 2026-09-25 (Ritz): the owner dies, or enters an instance

**The owner dies.** "There's two resolutions - either the player resurrects
at their corpse, or they talk to the spirit healer. In either case, the
buddies should continue questing around where the player died. If they pick
the spirit healer, they should move to the player's new location and start
doing their normal activities over there."
- While the owner is dead, buddies keep adventuring where the owner died.
- Corpse run: nothing changes, the owner comes back to them.
- Spirit healer: buddies travel to where the owner rose and carry on there.

**The owner enters an instance while buddies are outside.** "a dynamic group
is created for the player (unless they already have a group, then it has to
be manually created). If it's a manually created group and a buddy-bot is
invited, they'll move to the instance, enter, and join the party. [...] if
they're lower level than the player, they'll quest in the closest
level-approprate area to the dungeon that the player is in. If they're the
same level or higher, then they'll just chill - by that I mean lighting a
fire, hanging out, eating snacks, talking to passerby if they sit at the
fire, etc. If they're near a graveyard, they'll be provided some flowers to
hold and they will wander around to the gravestones and kneel before about
1/4th of them. They might also say some dynamic chat lines depending on
their character."
- An owner with no group gets the dynamic dungeon group (617c's draw bag);
  an owner already in a group invites by hand.
- An invited buddy travels to the instance, enters and joins.
- A buddy left out:
  - **lower level than the owner**: quests in the level-appropriate area
    nearest the owner's dungeon;
  - **same level or higher**: rests. It lights a campfire, sits, eats; near
    a graveyard it is given flowers to hold, walks among the gravestones
    and kneels at about a quarter of them.
- Talking to passers-by at the fire, and in-character chat lines, wait on
  the LLM chat module (issue 916, mod-soren-chat: persona chat 916k,
  emission and rate limits 916l, proximity 916g), which today targets the
  vanilla profile and would need basic added.

### Decision, 2026-09-25 (Ritz): the owner far away

"The buddy-bot should move toward the mechanism that allowed the distance
at their earliest convenience and attempt to rejoin the player."
- When the owner travels by something other than walking (the Dark
  Portal or Isle flight, 155l; a boat or zeppelin; a summon; a mage
  teleport), each buddy, once it has finished what it is doing, goes to
  that same means (the flight master, the dock, the Dark Portal) and uses
  it, then rejoins the owner's area.
- A means a buddy can't use itself (a summon, the mage's own teleport)
  leaves the walk: it heads for the nearest way there it can use.
  Hearthstones are designed above (buddies hearth after the owner).

### Decisions, 2026-09-27 (Ritz): spacing, pinwheels, graveyards, portals

Verbatim, correcting "the four in your group stay inside the range where
kill experience is shared":

> actually they don't. It's that they leave the group when they're far
> enough away, and rejoin it when they are near and you don't have a full
> group. They wander throughout the zone pseudo-randomly, trying to
> distance themselves so that they're in roughly the same distance from one
> another. Whether that's close or far, doesn't matter, they just try and
> congregate at a certain distance. Then, they pinwheel around the center
> of the zone. a random direction is chosen for each of them, and they each
> have their own separate "far enough away from these buddy-bots" lists,
> one for each direction.

> [travel by portal:] we should make portals cost a crafting reagent from
> Jewelcrafting or enchanting

> [left out of a dungeon, same level or higher:] they have a 1/4th chance
> of pathing to a graveyard instead of resting.

Read into the design (replacing "grouped buddies stay inside the owner's
experience radius, ungrouped ones outside it" above):
- **Buddies don't stay near the owner.** They roam the whole zone
  pseudo-randomly, each trying to keep about the same distance from the
  others (a spacing, whatever it works out to), and circle ("pinwheel")
  round the zone's centre, each in its own randomly chosen direction.
- **Each buddy keeps its own "far enough away from these buddies" lists,
  one per direction** (read: for each way it could move, the buddies it is
  already far enough from; it moves where the spacing holds). Open
  question below.
- **Grouping follows distance, not a seat count** (617c2): a buddy leaves
  the owner's group once far enough away, and rejoins when near while the
  group has room.
- **Left out of a dungeon, same level or higher**: a 1 in 4 chance of
  walking to a graveyard (flowers, kneeling at about a quarter of the
  stones) instead of resting at a campfire.
- **Portals cost a crafting reagent** from Jewelcrafting or Enchanting
  (which portals: open question below).

### Suggestion, 2026-09-27 (Ritz): the waypoint pinwheel

Verbatim, after seeing the first seven animations:

> okay the bot behaviors look great, here's my suggestion - when choosing a
> new waypoint for the pinwheel, pick a position at the desired rotation,
> but it's distance from the center of the area should be fully randomized.
> And they don't pick a new rotation until they reach it. Avoiding rocks of
> course, and placing the waypoints on a percentage modifier chance some
> percentage of the distance to the edge of the area in that particular
> rotation from the center. They get a new waypoint only when they reach
> theirs, and it can't go within 5 yards of a wall. Maybe 2 yards. or 3.
> Anyway this means that a bot that gets several low percentages will hug
> the center of the room and rotate around it's center quickly, but then it
> gets one that's at 65% so it spends extra time walking toward the edge.
> Meanwhile another one that was close to the center 5 times in a row will
> be on the 5th probably before the other bot gets to it's waypoint at 65%
> of the way around.

> this behavior instead of trying to stay equidistant to their other
> buddies. We might want some combination of these behaviors.

Built into the model as the "waypoints" reading (animations 8 and 9):
each waypoint is the previous bearing from the area's centre turned a
fixed step (40 degrees for now) in the buddy's own direction, at a uniform
random share of the way to the area's edge, 3 yards clear of rocks and the
edge. A spot inside a rock's clearance re-rolls the share; a rock across
the whole bearing turns it one more step. A buddy that hasn't arrived in
twice the straight-line time gives up on that waypoint. One blend is drawn
(animation 10): of up to 8 spots on the bearing, the first 20 yards from
every other buddy's waypoint is taken, else the roomiest. The generator
measures how close buddies come in each reading and prints it in the
captions.

### Decisions, 2026-09-27 (Ritz): the distance limit, orbiting

Verbatim:

> okay how about the waypoint can't be more than +/- 30% of the distance
> from the previous one? Let's call the distance from the midpoint the "Y"
> distance, and the radian around the center the "X" distance. So next
> pick's Y value can't be more than + or - 30% of the previous Y value.
> Also, if there's an object in the way, we should try and orbit instead of
> running up right against it. Also, we should orbit around small rocks and
> differentials in the world-space coordinate Z axis - just stuff that's
> sticking up and on the ground, doodads too (only colliding ones), we
> should try and orbit around those too. Like a ruined crate, no need to
> step on that..

> reading D looks so cool!

Built (animations 11 and 12):
- **Y** is a waypoint's share of the way from the centre to the edge on its
  bearing; **X** its bearing. Two readings of the limit are in the model.
  "Points": the next share is within the last share ± 0.3, and this is the
  one animated. "Ratio", the literal wording: the last share × (1 ± 0.3).
  The ratio reading shrinks on average, because 0.7 × 1.3 = 0.91 and the edge
  caps the growth. Without a floor, every buddy ends at the centre. With a
  floor of 0.1 the buddies still spend most of their time in the middle. The
  generator measures both and prints the result in the caption.
- **Orbiting**: every obstacle (rock, small rock, colliding doodad, raised
  ground) is a circle to the model. When the straight line to the waypoint
  passes within the obstacle's radius + 2.5 yards, and the obstacle is
  within 15 yards, the buddy aims along the tangent to that orbit circle,
  on the side its waypoint lies. It keeps that side until it has passed.
  When the waypoint is straight behind the obstacle, it goes round the way
  it circles the area. The generator measures how much of the time buddies
  spend within a yard of an obstacle's edge, with and without orbiting.
- **Finding obstacles in game** (to be checked on the server): nothing
  lists small rocks and crates in advance. I believe the server's height
  lookup includes the tops of colliding doodads, because it combines the
  collision models with the terrain. If so, a crate or a raised patch of
  ground reads as a step up in height, and one probe covers rocks,
  doodads and raised ground: sample the ground height on a ring ahead of
  the buddy, and treat a rise of more than about a yard as an obstacle
  circle. A line-of-sight check at knee height would be a second probe for
  thin things. Non-colliding doodads don't show up in either, so they are
  walked through, as the owner wants.

### Decisions, 2026-09-27 (Ritz): the Y rule, the path planner, resting

Verbatim:

> basically, pick a waypoint, and then draw a line to it. Then, create
> imaginary waypoints at N percentage toward the target, based on the
> character's size. Tauren have larger hitboxes, gnomes have smaller, so
> they'll pathfind around obstacles in differing increments. so like if a
> character is 1 yard wide, then a path to a place 45 yards away will have
> 45 test waypoints placed on a line between point A and point B. They're
> just numbers. Then, we test the height differential. If we need to orbit
> for some reason, we'll create a sine wave projection or something that
> curves around it and normalizes to a straight line at the peak of the
> curve around the object. Then, we should try and find the gentlest path
> down a slope, or the flattest path up a hill. That'll help a lot...
> Maybe also can we look at the texture of the ground that we're standing
> on? If it's flagged as a "road" material, then we should prefer it as
> well. Maybe also we could just, have waypoints that go throughout the
> area that we could use. Like NPC pathing patrols, or our own custom
> ones. Treat them like rail lines... That might be overkill so let's see
> if we should use it for the adventuring pathing, or the meta-pathing
> between adventures and towns and graveyards and instances and stuff...

> okay can we change it to +/- 20% instead of 30%? Also, can we decrease
> the X value between new waypoints?

> +/- 30% of the previous y, and make it 1-20%

> also this doesn't matter for the gifs, but we can have a chance to sit
> down and eat food or regenerate health every time they reach a waypoint.
> The chance is the % of your health that's missing, divided by 2.

> no way. Why wouldn't it be randomly distributed? We're generating an
> integer between 1 and 20. Then, each waypoint has an integer between 1
> and 100. the 1 and 20 number is added or removed from that 1 in 100
> number, with a 50% chance of either. The modified 1 and 100 number,
> minimum 10 yards from the center, is the percentage of the distance
> between the center of the area and the edge of the area that the
> waypoint will be placed. The X value is a steady increment, each time a
> new waypoint is generated it's like, +2piR or something I forget how
> radians work. But just, some amount of rotation, plus the randomized
> distance (modifed from current position) should be enough. Maybe like
> 10% of a circle per increment? Something that makes sense.

Built (animations 11 to 15; `src/lua-basic/lib/buddy-roam.lua`):
- **Y rule** ("step"): Y is a whole number 1..100, the percent of the way
  from the centre to the edge on the bearing. Each waypoint adds or takes
  away, at even odds, a whole number 1..20, kept within 1..100; the
  waypoint is never nearer the centre than 10 yards. Evenly spread over a
  long run (the generator prints the figures). A spot in a rock slides
  along the bearing to the nearest clear point, one percent at a time;
  the rule's own Y is not changed by the slide (carrying the slid value
  on, or redrawing, leaned the walk outward round a rock near the
  centre). Multiplying Y by 1 ± the change was built first from a
  misreading, and leaned inward.
- **X**: a tenth of a circle (36 degrees) a waypoint.
- **Path planner** (`Roam.plan_path`): test points every body width along
  the line (body width = twice the race model's bounding radius in the
  server's `creature_model_info`: human male 0.61 yards, tauren male
  1.95; the gnome models have no entry, open question). At each, the
  ground height under the centre and both shoulders. A height change
  that stands out from the changes either side by more than 0.6 yards is
  an obstacle (a slope changes steadily and doesn't count). Round each
  obstacle the path bulges out, one body width more at a time until
  clear, on whichever side makes the cheaper path: a half-cosine ease
  out, a straight run past it at the peak, an ease back. The straight line
  and four gentle bows (15% and 30% of the trip either side) each get
  their bulges; the cheapest wins, where a yard costs 1 + 6 × grade² and
  60% of that on road. 1 to 15 ms a trip in the model.
- **Rest chance** (`Roam.rest_chance`): on reaching a waypoint, (share of
  health missing) ÷ 2: full health never, 60% health 20%, near death 50%.

Read into the design, for the server:
- **Height lookups**: the server's height lookup already takes the higher
  of the terrain-and-collision-models height and the height of moving
  objects (doors, spawned crates), so a colliding doodad reads as a step
  up (checked in the source, `Map::GetHeight`). The Lua engine's version
  searches down from the sky, so under a bridge it would return the
  bridge's height; the planner belongs in mod-buddies (C++), searching
  down from just above the buddy. Three lookups per test point, a few
  hundred per trip, once per waypoint.
- **Road material**: the server has no ground textures. Its map files
  hold heights, areas, water and holes; the textures live only in the
  client's terrain files (each map square's texture list and blend
  layers). A road grid would need our own extractor reading those files
  (the MPQ reader is already installed for the icon work), classifying
  textures by name ("road", "cobble", "path"...), and writing a grid per
  map for the planner. Planned, not built; the model's road is drawn.
- **Rail lines**: recommended for the meta-pathing (between areas, towns,
  graveyards and dungeons), not for adventuring. Playerbots already keeps
  a travel network of that kind (3,781 nodes and 1.4 million path points
  in the vanilla profile's playerbots database; tables
  `playerbots_travelnode`, `_link`, `_path`), built for exactly those
  trips. NPC patrol paths (`waypoint_data`, 7,222 paths in the vanilla
  world database) run through monster camps, so they suit neither well.
  Adventuring inside one area stays with the planner, which needs no
  prepared data.

### Decisions, 2026-09-27 (Ritz): crowding, the side tunnel

Verbatim:

> can we double the lengths of the gifs and regenerate them? Also, we
> shouldn't place a waypoint within 5 yards of another player or
> buddybot - if we do, then the next waypoint should be +10% or -10%,
> whichever one is closer to the midpoint. So for example at 20% distance
> from the interior center, then someone who's course-correcting because
> another buddybot is within the range of their waypoint when the waypoint
> is created, we'd move it to 30% distance. If it was at 70% and someone
> was inside it, then we move it to 60%. Normalizing toward the center
> just a bit, even if it makes the path longer. This is good, to spread
> out the buddies.

> can you make a gif that has a side tunnel, and ensure the buddy-bots are
> encouraged to walk through it? I'm not sure how we could encourage that,
> maybe if they walk up to it, as they walk around the center, they can't
> walk in walls... So maybe the +/- 30% should check for walls between the
> character and the chosen point, and if there are any, move the "edge" of
> the map to the closest of the walls, and recalculate distance with the
> same numbers? Does that make sense and track?

Built (animation 16; the GIFs doubled in length):
- **Crowding** (`crowd`): someone (another buddy, or a player in the
  model's list of others) within 5 yards of where the drawn Y lands moves
  Y 10 points toward 50, once; the moved Y is carried on. Measured with
  the planner: it moves about 1 waypoint in 20, and trims the time a buddy
  spends within 6 yards of another only a little (the generator prints
  the figures), since buddies mostly meet while walking, not at
  waypoints.
- **Walls as the edge**: already how the line along a bearing is measured
  (it stops at the first wall it meets, and the percent is of that
  distance). Measured from the centre rather than from the buddy, which
  gives a useful guarantee: every waypoint is in sight of the centre.
- **The way out of a tunnel** (`turning_point`): when the straight line
  from the buddy to its next waypoint crosses a wall, it walks toward the
  centre until the waypoint comes into view and turns there. The
  guarantee above means such a point always exists.
- **The pull toward openings** (`find_opening`, `openings` = 20 yards):
  the walls rule alone almost never reached the tunnel (0.3% of waypoints,
  one buddy of six), because a fixed turn makes each buddy repeat the same
  ten bearings and only bearings within a few degrees of the tunnel's line
  reach into it. Now each new bearing looks up to half a step either side;
  a run of degrees where the line reaches 20 yards farther is an opening,
  and this waypoint takes its middle (the pinwheel's own bearing doesn't
  change). Every buddy then passes the tunnel once a lap: about 5% of
  waypoints fall past its mouth, all six buddies go in. At 10 to 15 yards
  some of the chamber's corners counted as openings too.
- **In game**: "the first wall along the line" is found by stepping along
  it and stopping where the height jumps (the planner's step test) or the
  area's id changes (the named area's edge).

### Decisions, 2026-09-27 (Ritz): monsters, piercing, tunnels, area borders

Verbatim:

> for the pathing, I think we should make it so that bots will try to move
> within aggro range of monsters that they are near, nudging their
> waypoints to move the tangent line between them and the mob's aggro
> radius somewhere interior to the radius of the aggro radius, essentially
> ensuring that the monsters will notice and attack. Can you think of an
> update to the algorithm that would accomplish something similar?

> also, if the buddy-bot's waypoint gets pretty close to middle after
> having two low 1-20% rolls, we should pierce through the center and
> reverse their orientation. So like, if they start far away and then have
> at least two rolls in a row that brings them close to the center. To
> make an S shape, or a figure 8 passing through the middle of the 8, or
> similar.

> for the tunnels, basically I want to detect when a waypoint is within a
> tunnel, then follow that tunnel to where it opens up again, accounting
> for forks, and then I want to move the radius that the bot orbits around
> to be in the room on the other side of the tunnel. I think there was a
> pathfinding algorithm we designed for an earlier issue file, can you try
> and find that? I think it explicitely covered tunnels.

> the buddy-bots will move to whatever area you're in and explore there.
> So if you move to town, then they move there as well.

> we should find the borders of the area, then calculate it's rough center
> from that. It's okay if the center isn't exactly the same each time, or
> for each player. The edges should be defined somewhere, so it's a matter
> of finding those numbers and using them. We could even pre-calculate the
> midpoints at compile time...

> [resting] yeah. If the food has a well fed buff, they should wait until
> they get it or are interrupted. If not, they should eat until their
> health bars are full and drink until their mana is full (if
> appropriate).

Built in the model (animations 17 and 18):
- **The monster nudge** (`lure_point`): along the straight line to the
  next waypoint, the first living monster whose aggro radius the line
  misses by at most 25 yards bends the trip through a point 70% of the way
  in from the radius's edge, on the side the line passes (a clear place in
  sight of both ends); only the first monster, so a buddy isn't dragged
  from one to the next. Measured in the drawing: more fights per 100
  waypoints with it than without (the generator prints both). In game the
  radius is the creature's own aggro range against that buddy (the server:
  20 yards, one less per level the buddy is above it, 5 to 45), and only
  monsters that attack on sight count. Note: playerbots' `grind` (617e1)
  already charges anything worth experience within 100 yards; while it is
  on, the nudge adds little (open question).
- **Piercing the middle** (`pierce` = 25): after two inward rolls in a row
  that leave Y at 25 or under, the next waypoint goes on the far side of
  the centre at the same Y and the buddy turns the other way round: S
  shapes, then figure eights. The count starts again after each crossing.
- **The tunnel design found**: issue 612 (dungeon rail pathfinding, beta,
  code in `src/lua-beta/behaviors.disabled/dungeon-rails.lua`, never
  tested) classifies a place by sampling the ground in 8 directions: two
  walkable ways is a corridor, three or more a fork, one a dead end.
  Read for the owner's tunnel rule (not built): a waypoint whose place
  classifies as a corridor starts a tunnel walk, following 612's rail from
  corridor point to corridor point, taking a random branch at a fork (not
  the way it came), until the ground opens out (more ways than a fork, or
  wide open ground); there the pinwheel's centre moves to the middle of
  that room (its own small centre search) until the next tunnel or the
  owner's area changes.
- **Area borders** (not built): the server's map files hold each map
  square's area id on a grid, so an offline tool can read every area's
  cells once, at install time, and store each area's bounds and middle in
  a table the buddies read; no search in game.

### Proposal, 2026-09-27: exploring as painting (not built; under discussion)

Verbatim:

> [tunnels:] I'm concerned about dead ends, which do exist

> for L shapes, maybe we should project the actual borders onto a circle
> that's been squished to fit them? That way they properly orbit around
> the circle. See this web page (and download it for reference) here:
> https://muchmirul.github.io/jacobian-conjecture/

(Saved: `docs/reference/jacobian-conjecture/index.html`, "Jacobian
Conjecture for Baby": maps that bend space; the Jacobian as the local
stretch; locally invertible everywhere is not the same as invertible
overall.)

> In Darnassus, there are these winding staircases that go down in an
> area quite far, much more than 10 yards. We will need to take the
> walkable area, flatten it as a distance graph, then treat it is a
> multidimensional shape (because it is) when trying to find midpoints.
> Each bot should try and cover enough ground to "paint" the entire
> surface of the dungeon. They're exploring it! But, sometimes, they don't
> have to go down *every* single path. But, given enough time, like if the
> player AFKs in the middle and waits, then they will find every single
> path and paint it. The orbit-around-the-center mechanic is a scaffold for
> that "paint the entire map" system, and bots should provide more paint
> at their location and less and less drifting out in a radius until
> they're at their full vision distance. Say, 60 yards. They'll try and
> optimize, dijkstra heat map style, a path through and toward the least
> "painted" areas by them, prioritizing the spots farthest from the
> entrance. They should also try and "paint" areas that are less painted
> by their clanmates. Over time, the entire map will be explored, but I
> also don't want them like rubbing their noses on the far walls, hence
> the "orbit-around-the-center" system we made earlier. What do you think?
> Any clarity for combining them, or a different system...?

Proposed combination, three layers:
1. **The ground as a graph.** Each area's walkable surface as a graph of
   small patches (the server's navigation mesh polygons, which already
   follow stairs, bridges and floors, or a grid of height samples),
   joined where a character can walk between them, each edge weighted by
   walking distance. Built once at install time, like the area middles.
   Distances along it are walking distances, so Darnassus's staircases
   count at their real length and a floor below is not "near" the floor
   above.
2. **The squished circle.** A map of that graph onto a disc: the area's
   border patches placed round the circle by distance along the border,
   every inner patch placed at the average of its neighbours (a harmonic
   or Tutte map). For a convex target like a disc this kind of map never
   folds (every patch keeps its orientation, the Jacobian keeps its
   sign), so each point of the disc names one place. The pinwheel runs in
   the disc (X the angle, Y the radius, the owner's rules unchanged) and
   each waypoint is the patch at that point of the disc. An L-shape then
   orbits round its own bend, a tunnel is a thin band of the disc, a dead
   end is part of the border (visited like any rim, then left), and the
   middle is the patch at the disc's centre, a walking-distance middle.
3. **Paint.** Each buddy lays paint on the patches it can see: most where
   it stands, less and less out to 60 yards. Each clan keeps its own
   paint per area, each buddy's shared with its clanmates. When the
   pinwheel proposes the next waypoint, a few nearby points of the disc
   are weighed (the proposed one, a little further round or out or in),
   and the least painted wins, farther from the area's entrance weighing
   more; the path there costs less through unpainted patches (Dijkstra
   over the graph). The pinwheel keeps the laps interior and orderly (no
   nose on the far wall); the paint makes sure that, given time, every
   patch is visited.

Owner's answers, 2026-09-27, verbatim:

> maybe we could say that walls generate paint themselves within ~5 yards,
> with more near the wall and less farther out? That might help with our
> orbiting behavior. Maybe we could even remove it in favor of wall paint.
> I'm thinking like, a pulse every 3 seconds or so. Also bots should keep
> painting while fighting [...]

> [three layers or paint first:] need gifs to find out. Need to combine
> systems into a gif that ideally shows both behaviors so we can compare.
> Don't be afraid to re-implement the arena or other aspects of the design
> if you want to show off a specific kind of behavior.

> [fading:] last until the player leaves the area for 15 seconds. It's
> okay if the numbers increase as high as they need to go. Eventually
> they'll wrap around at 60 thousand or whenever an integer wraps, and
> that's fine because eventually they'll all wrap. Might look a little
> janky randomly, but that's okay, leave a note about it.

> [the entrance:] where you entered.

> [stray pieces, reviewing them one by one:] hmmmmm that's too many for me
> for right now

Read into the design:
- **Wall paint**: every wall paints the ground within about 5 yards of it,
  most at the wall, in a pulse every 3 seconds, so waypoints and paths
  shy away from walls by preferring unpainted ground; possibly replacing
  the orbit (to be seen side by side in animations).
- **Paint lasts** while the owner stays in the area; 15 seconds after the
  owner leaves it, that area's paint is dropped. Counts only grow; stored
  in a fixed-width integer they wrap round (at 65,536 for 16 bits) and a
  wrapped patch briefly looks unexplored. Accepted (note in the code where
  the counts are kept).
- **Painting continues in fights.**
- **The entrance** is where the owner entered the area.
- **Stray pieces** stay as they are for now (all rows kept).

After the comparison animation (19), 2026-09-27, verbatim:

> for the painting explore gifs, the third one I think looked the most
> natural. Don't forget to add the "paint from walls" behavior! It didn't
> seem to be in effect. For the first two, I think the problem is that
> their midpoint is the midpoint of the entire area, when it should be the
> midpoint of the room that they're in. That's unique to enclosed spaces I
> think, or things like outdoor structures where the movement map leaves
> the floor and forms it's own "tunnels" - we should identify rooms, as
> in, not tunnels, and we should orbit around those until the paint
> system tells us to be drawn toward a tunnel. If the walls extrude paint,
> then characters will be encouraged to walk through the center of the
> tunnel, not glide along it's walls.

- **Least paint with wall paint** (panel 3) read as the most natural.
- **Wall paint must show**: check it is in effect (it seemed not to be).
- **Build every system in game** (owner, 2026-09-27: "can you build all of
  them? I want to see what kind of mechanics they create. I'm a visual
  learner."): the pinwheel, least paint with wall paint, the room orbit,
  and the squished circle, each selectable per buddy so they can be
  watched side by side (617e6).
- **Why panel 3 looked natural** (owner, 2026-09-27: "they cut across the
  inner wall of the cavern"): its buddies cut across the inside of a bend
  instead of following the room's shape round it, as a person would; a
  measure of that (how much of each trip takes the inside line) is the
  first candidate for "natural".
- **Rooms, not areas, have midpoints**: the walkable ground is split into
  rooms (wide places) and tunnels (narrow ones between them); a buddy
  orbits the middle of the room it is in, until the paint draws it toward
  a tunnel, then walks the tunnel (kept to its middle by the walls' paint)
  to the next room and orbits there.
- **Next**: animations comparing the systems (the pinwheel alone,
  pinwheel with paint, paint with wall paint and no pinwheel, and the
  disc-mapped version), on arenas built to show them (an L-shape, a
  corridor with rooms and a dead end, a large room).

### Decisions, 2026-09-27 (Ritz): town leisure, the named area, portals

Verbatim:

> [left out of a dungeon:] they might also walk to a town. Along a road, to
> the graveyard or the town. When there, they'll just chat with NPCs.
> Sometimes they'll sit on chairs and chat for a long period of time with
> other NPCs if any are near, including other buddy bots. No chat messages
> are ever sent to the chat window, but they play the chat animations. If a
> buddy-bot sits next to another buddy-bot, then no matter how long the
> first one was there, they'll both leave when the latest-to-join's timer
> expires. Sometimes, a third might join, and it resets the timer for all
> of them. They'll chat, drink and eat food, laugh, etc. Sometimes they'll
> sleep on beds. This should all be added to the "visiting town" behavior,
> so if the player's in town then it applies too, but only when their todo
> list is done.

> [the zone:] Fargodeep Mine.

> [portal reagents:] all portals. Make it an enchanting shard, including
> the lower level ones for low-level teleports. [...] ah, nevermind.
> Abandon the idea, but mark it down as considered, and how we'd implement
> it if we could bypass that limit somehow.

- **Left out of a dungeon, same level or higher**: rest at a campfire, or
  (1 in 4) walk to a graveyard, or walk to a town; to a graveyard or town
  **along roads**.
- **Visiting a town** (whenever the buddy is in one: left out of a
  dungeon, or with its owner in town, once its to-do list is done):
  - it chats with townspeople: talking animations, **never a line in the
    chat window**;
  - sometimes it **sits on a chair** near other NPCs or buddies and chats
    a long while: eats, drinks, laughs;
  - **shared timers**: buddies sitting together all leave when the
    latest-to-arrive's timer ends; a newcomer resets it for everyone;
  - sometimes it **sleeps on a bed**.
- **The zone is the named area** shown on screen (Fargodeep Mine), not
  the big zone: the roaming (spacing, pinwheel) happens within it.
- **Portal reagents: considered, dropped** (2026-09-27). The idea: every
  portal and teleport (the mage's, and the others) costs an enchanting
  shard sized to its level (small shards for low-level teleports). Dropped
  because a spell's reagent is client data: the server can check any
  reagent it likes, but the tooltip would keep naming the old one. How it
  would be done if that limit were lifted (a custom client, whose spell
  file names the shard): the server's own copy of the spells' data would
  name the shard as the reagent, per spell, from a generator that pairs
  each portal's level with a shard tier; players would then see and pay
  the same thing.

## Suggested Implementation Steps

1. A bot strategy in mod-buddies: "adventure in owner's area". It
   replaces follow, with a grind target search bounded to creatures inside
   the owner's current area.
2. Area-change travel: path to a point inside the new area.
3. Death handling: the module's existing release-and-resurrect logic, with
   the return trip from step 2.
4. Look at beta's 601 (find monsters) and 611 (wandering) for reusable
   ideas.
5. The path planner in mod-buddies: the model's planner in C++, reading
   the map's height (searching down from just above the buddy) at every
   test point; the buddy walks the chosen points. On each waypoint
   reached, roll the rest chance and sit to eat or regenerate.
6. Test: owner stands at a camp's edge; buddies spread through the camp
   and fight; owner moves to the next area; buddies follow within a minute;
   a buddy that dies comes back.

## Related Issues

- **617**, **617c**; **601**, **611**, **613** (beta's Lua behaviors)

## Open Questions

- (Answered 2026-09-23) Buddies stay in the owner's area; in towns they
  visit NPCs on foot. The level band is whatever lives in that area.
- (Answered 2026-09-23) Towns and cities, not rested areas. The client's
  area table flags capitals and towns (`AreaTable.dbc` flags, readable
  server-side from the server's copy); the flag set to use is checked when
  617e is built.
- (Answered 2026-09-25) Which flags: "the buddies should treat any area with
  the town or city flag as a town, and they should dynamically create their
  todo lists based on the services available in that town." In the server's
  area flags (DBCEnums.h): town (0x00200000, "small towns with Inn"),
  capital (0x00000100) and the capital's subzones (0x00000008).
- (Answered 2026-09-27) The zone is the named area (Fargodeep Mine).
  Portal reagents: considered and dropped (above).
- **The pinwheel lists**: being worked out with animated interpretations
  (owner, 2026-09-27: "please create some gifs [...] try and explain any
  interpretations you can consider for the spatial pinwheel"). The owner
  proposed the waypoint pinwheel in place of equal spacing, "we might want
  some combination": pure waypoints, the waypoint-apart blend, or another
  blend (spacing steps while walking to the waypoint)?
- (Answered 2026-09-27) The Y rule: a percent 1..100 moved 1..20 points
  at even odds, never under 10 yards; X a tenth of a circle.
- **Waypoint clearance** from rocks and the edge: 2, 3 or 5 yards ("Maybe 2
  yards. or 3."; 3 here).
- **How sharp a height step counts as an obstacle** (0.6 yards beyond the
  slope around it here), and **the planner's weights** (a yard costs
  1 + 6 × grade²; road 60%).
- **Gnome body width**: the gnome models have no entry in the server's
  model table; use the client's model data, or a set width?
- **Road grid**: build the terrain-texture extractor, and which texture
  names count as road?
- **Rails for meta-pathing**: use playerbots' travel network (recommended)
  or our own?
- **The pull toward openings**: keep it (always, once a lap), make it a
  chance, or instead let the bearing wobble a few degrees so the ten
  bearings drift round over time?
- **Crowding**: also check other buddies' waypoints (where they are
  going), not only where they stand?
- **Straight-and-orbit walker or planner**: the planner replaces the orbit
  walker in game (it finds obstacles itself); keep the orbit walker only
  as the drawing's comparison?
- **Uniform share or even coverage**: a uniform share along the bearing
  puts half the waypoints in the inner quarter of the area; a share drawn
  as the square root of a uniform number would cover the area evenly but
  lose the "hug the center" runs the owner described.
