# Pathfinding improvements: a report

*Written 2026-10-27, after the first measured buddy walk (issue 617e13), at
the owner's ask: "Please feel free to create a report requesting
additional pathfinding functionality. Use your best intuitions to create
new notions of potential improvements." Each idea says what it would
change, what in the record suggests it, and how its effect would be
measured (`scripts/measure-buddy-spread`, from the recorder
`src/lua-basic/buddy-spread-recorder.lua`). Ordered from the most likely
to help to the most unusual. The owner read it the same day; each idea
carries the answer, and two ideas were set aside (4, 10).*

## What the first walk showed

Feldowinn walked from Felstone Field through The Bulwark (both its sides).
Two buddies never moved (an action gap in one town circle, and long walks
that found no way); three followed but stood on her spot (travel aimed at
her own position). The three fixes written that night are in 617e13's
Current Behavior. What follows goes beyond them.

## 1. One mover at all times (a referee)

**The idea.** A buddy's movement is decided by several actions (roam,
travel, town, crossing, fighting, the bot module's own follow), each with
its own "is this mine?" test. When every test says no, nothing moves it
(Matis, 2026-10-27). A small referee, run before them, would name the one
action that owns the buddy's movement this tick, from one table of
situations (the owner's sub-zone, the buddy's, a town circle, distance, a
fight, a boat), and log the owner of each tick in the trace.

**Why first.** It turns "nothing moved him" from a puzzle into a line in
the log, and makes every gap a missing row in one table rather than a
missing clause in five functions.

**Standing still is often right.** The owner, 2026-10-27: "sometimes they
stand still, usually in town when visiting or chatting. Or if there's
nothing to do, sometimes they'll sit down and just chill." So the referee
has a row for each kind of rest (a town pastime, a chat, sitting with
nothing to do), named in the trace like any other owner of the tick: the
fault to catch is a buddy still with *no* row naming why.

**Measured by.** Samples of a buddy standing still with no reason named:
should go to zero.

## 2. The way known before setting off

**The idea.** Ask the navigation mesh for the whole way to the
destination before the first step (the server's path generator), and act
on the answer: a full path, walk it; a partial one (the mesh ends short),
walk to its end and ask again from there; none, choose another place on
the arc, or the arc's middle, or the owner's spot, in that order, before
counting a failure.

**Why.** Today a failed long walk is only known by the walk failing; the
three-failures rule waits three steps to act on it.

**Measured by.** "Never arrived" and the median arrival time.

## 3. Following the owner's own track

**The idea.** Keep the owner's last few hundred yards of positions (a
breadcrumb trail, every few yards). A buddy that finds no way to its owner
walks the trail instead: the owner just walked it, so it is walkable, through
gates, bridges and tunnels the mesh may not join.

**Why.** Places like The Bulwark (a gate between two zones), Undercity's
lift, a cave mouth: the owner's feet already proved the way.

**As the owner shaped it** (2026-10-27): the same arc system, carried
along the track: each buddy walks to a point on an arc round the owner's
path, the arc turned to follow the path as it bends, "unless it would lead
them into an obstacle or something, then they just stick to the nearest
'center of the room' gradient, preferentially. But still remaining close."
So: a place on the arc round the trail point; if it is blocked, the
nearest point toward the room's middle (the exploring grid's distance
map, 617o3), never far from the trail.

**Measured by.** Arrivals after a sub-zone change through a gate.

## 4. Spreading by claimed patches of the sub-zone (set aside)

**Set aside**, the owner, 2026-10-27: "there are intended to be many
players on the server. We cannot create patches for each individual buddy.
That's 8 per player! 8 patches per player! No way." Even spacing has to
come from rules each buddy follows alone and cheaply (keeping a distance
from the nearest others, a pull toward the sub-zone's emptier parts as
seen from where it stands), costing nothing per player.

What it was:

**The idea.** The exploring grid (617e6) already divides an area into
walkable cells. Give each buddy of an owner a share of the cells (nearest
first, as a Voronoi split from where each one stands), and have it roam
only its share. Shares are redrawn when a buddy joins, leaves, or the owner
changes sub-zone.

**Why.** "Fill out and evenly space themselves through the questing
sub-zone" is a sharing problem; each roaming independently drifts to the
same few spots (41 stacked pairs in the first walk).

**Measured by.** The nearest-buddy distance (should rise and steady), and a
new number: the share of the sub-zone's cells within 20 yards of some buddy.

## 5. Gathering on the way, as part of the path

**The idea.** When choosing a waypoint, a herb or ore node within a
detour budget (say 30 yards off the line) becomes the waypoint itself; on
leaving a sub-zone, the nodes in it that this buddy can gather are visited
first if they are near the way out. The owner: "if they see an herb or
mineral node they'll grab that both before leaving, and along the way.
Always."

**Measured by.** A new number from the recorder: nodes passed within 30
yards and not gathered.

## 6. Not fighting on errands

**The idea.** While travelling to town to sell, or following the owner
between sub-zones, a buddy does not start fights: it only fights back, and
only what hits it. A flag on the buddy for the trip's length, cleared on
arrival.

**As the owner shaped it** (2026-10-27): "unless a foe is in their way, as
is the case when they have to fight through wilderness. This is common.
They should orbit move aside fights that they don't think they can win."
So: a foe standing on the way is fought (the way through the wilderness
goes through it); one off the way is not started on; and a fight the buddy
judges it would lose (by the foe's level and number against its own
health and its group) it walks round instead, on an orbit wide of the
foe's aggro radius, then rejoins the way.

**Measured by.** Fights started while travelling (the recorder writes
"fighting"; a column for "on an errand" would make this direct).

## 7. Spacing in a column on narrow ways

**The idea.** On a narrow path (a bridge, a ramp, a tunnel: the mesh's
width under the path below two body widths), buddies walk in a column
behind the owner, a few yards apart, and fan out again on open ground.

**Why.** Six bodies aiming at six arc places through one gate jostle and
take turns at the gap; a column passes at once.

**The owner liked it, and asked: "What if we're running up a mountain
face?"** A mountain face is the opposite case to a narrow path: wide but
steep, where walkable lines are few and each is its own way up. The
suggestion: on a slope the mesh can climb only along certain lines
(switchbacks), buddies split across those lines in parallel, each its own
way up, a few yards apart, and gather on the arc at the top; a column only
where a single line is all there is. Open question for the owner: on a
climb, should they keep beside the owner (spread across the face), or
behind (each in the owner's footsteps)?

## 8. Learning hard places

**The idea.** Each failed long walk, unstick and "no waypoint" is written
down with where it happened (a small table by map and grid cell). A cell
that fails often is avoided as a waypoint, and the report lists the worst
cells, so a person can look at them (or draw a fix, as the hand-drawn
battle areas do, 617e12).

**Measured by.** Fewer unsticks in the same places over time; the list of
hard places itself.

## 9. Watching the record live

**As the owner shaped it** (2026-10-27): "we will only record our paths in
debug mode. and then, only for GMs." The recorder now does so; a live
watcher would follow that record, so it too is a Debug-build, game-master
tool.

**The idea.** A mode of the measuring tool that follows the record as it
grows (as `scripts/compile-ledger` follows a compile) and prints a line the
moment a rule breaks: a buddy stuck for 30 s, two stacked, one wandering
off. A watcher, person or chatbot, then sees the failure when it happens,
not after the walk.

## 10. Buddies that seem to have a mind of their own (set aside)

**Set aside**, the owner, 2026-10-27: "nah. Let's just build sufficient
dynamism into the system that we don't even need an opportunity to notice
such curious quirks."

What it was:

**The idea, the most unusual.** Give each buddy a small, stable preference
drawn from its personality (a liking for high ground, for water's edge, for
the shade of trees, for staying near one particular friend), used to break
ties between equally good places. The spread stays even, but each buddy's
choices become recognisable, and the group looks like people, not a
formation.

**Measured by.** Nothing in the spread numbers should get worse; the rest
is for the owner's eye.
