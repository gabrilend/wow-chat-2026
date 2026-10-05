# 617c3 - The Dungeon Draw

## Status
- Created: 2026-09-27
- Phase: 6
- Parent: 617c
- Blocked by: 617c2
- Priority: Medium

## Current Behavior

**Weighted roles, 2026-10-04, written, not yet built (the owner
compiles):** the tank and healer sums below (decision 2026-10-04) replace
"a tank first if none": `BringDrawn` in `buddies_party.cpp` scores each
eligible buddy with `RoleTenths` (10 for its plan's role, 4 for a third or
two thirds in a tree of that role) and draws until each sum reaches 10.

**Groups with several players, 2026-10-04, syntax-checked, not yet built
or run** (`buddies_party.cpp`, `BringDrawn`; roles in `buddies_roles.cpp`):
a player arriving in a five-player dungeon fills its group's empty seats
from the buddies of every player in the group; a tank first if the
group's players (by spec: the tree with the most points) and buddies
(by plan) have none, then a healer, then one at a time from each
player's draw bag in turn, players in a random order. Buddies drawn in
are kept apart from distance-seated ones, so a later player's arrival
doesn't redraw them; they rejoin the distance rule when they come out.

**Inside an instance, changed 2026-10-03 (syntax-checked, not yet built):**
seen in Zul'Farrak the same day, buddies stood at the entrance: the
open-country strategy set (no "follow") was left on them inside, since the
strategy pass skipped instances. Now the pass gives a buddy inside a
dungeon, raid or battleground the bot module's own way of running one:
"follow" on, roaming, travel and town visits off, running pace
(`buddies_roam_strategy.cpp`, `sInstance`). The bot module's bots don't
clear a dungeon by themselves: they follow the leader, attack what the
leader attacks and whatever attacks the group, and play their class's
role; the leader leads the pulls.

Before this:
**Built 2026-09-29, not yet compiled or tried in game** (owner: "we should
ensure that's working too"): `buddies_party.cpp`, "the dungeon draw". On
the owner's arrival in a five-player dungeon (the map-change hook; the
draw itself 1.5 s later in the world pass, after every map's update),
the party's empty seats up to five are filled from the bag
(`buddy_draw`, characters database, in `04-buddy-roster`): drawn at
random, marked had-a-turn; when too few are left the bag refills and the
draw goes on, skipping those just drawn. Buddies the distance rule had
seated make way; hand-invited ones keep their seats. The drawn join the
party and **walk in** (2026-09-30, owner: "they should have to walk"): to
where the owner last stood outside (kept every half second while out in
the world: the entrance), on the navigation mesh, then step through and
arrive where the owner arrived; stuck a minute, brought in with a logged
FALLBACK warning; on another map, left out with an error. The joined
party this way; the rest wait outside.
Two or more players grouped, a raid, a battleground or a dungeon-finder
group: left alone. On the owner's return to the open world, buddies still
in an instance come out beside them. Buddies in battlegrounds are simply
not drawn (617i isn't built, so none are). Inside, they fight by the bot
module's own rules until the kraken runs in game.

## Intended Behavior

617c's dungeon party, unchanged: on entering a dungeon, four buddies drawn
at random without replacement from a bag that refills when everyone has had
a turn (the `buddy_draw` table, 617a's data model), brought into the
instance; only empty slots filled when the owner is already in a party; no
auto-fill when two or more players are grouped; a buddy in a battleground
drawn last (617i).

### Decision, 2026-10-04 (Ritz): partial specs count toward a role

Verbatim: "can we make it so that when we assemble random dungeon groups
dynamically from buddy-bots in a clan, that we always ensure there's a
tank and healer present? We can count half-specs and third specs as 0.3
for the role - half and third both are 0.4 let's say, so you need at least
1 healer for example, or 3 half healers. For raids, all of your characters
join you so..."

Each role (tank, healer) is a sum the group must bring to at least 1.0:

- a player whose spec takes the role, or a buddy whose plan's role is it:
  1.0;
- a buddy whose plan puts a third or two thirds (a "third spec" or "half
  spec") into a tree of that role, without the role itself: 0.4. One
  buddy counts once per role, however many such trees.
- everyone else: 0.

The draw fills the tank sum first, then the healer sum: while a sum is
under 1.0 and seats are left, it draws the eligible buddy that adds the
most to it (a full one before a partial; a random one among equals). With
no full healer, three partial healers make 1.2. Kept as tenths (integers:
10 and 4) so no rounding decides a draw. A sum left short (nobody left who
adds to it) is logged with the sum reached. Then the rest as before.

Raids: all of a player's buddies join them (open question below).

### Decision, 2026-10-04 (Ritz): buddies have an aggro radius inside

Verbatim: "also can we make buddy-bots have an aggro radius in dungeons?
They should attack when they are ~10% farther than the monster's aggro
radius. Otherwise, they follow the player."

Corrected the same day: "walks into range and attacks / spellcasts when
the player is at 110% aggro range of the monster." The trigger is the
owner's distance, not the buddy's. Every half second (`AGGRO_LOOK_MS`),
for each owner inside a dungeon or raid: the nearest monster that would
attack the owner on sight (hostile, aggressive, not a critter or
civilian, nobody's pet, not already fighting, alive, in the owner's line
of sight) whose aggro radius for the owner, times 1.1 (`AGGRO_REACH`),
reaches the owner. Each of that owner's buddies inside and not fighting
then goes at it: target set and remembered, fighting engine on; melee
runs in, casters move into range and cast (the bot module's own fighting
does the moving). Otherwise they follow. (`buddies_roam_strategy.cpp`,
`AggroPass` and `ThreatNearOwner`; written 2026-10-04, syntax-checked,
not yet compiled.)

**The strategy set is put on once per place** (owner, 2026-10-04: "whoa 3
seconds? That seems like a bad design."): the pass used to put each
buddy's non-combat set back every three seconds, undoing any order the
owner typed (`nc -follow`, `nc +stay`). Now it is put on when the buddy's
kind of place changes (open country, town, instance) or it comes back
online, and the owner's orders stand until then.

## Open Questions

- (Asked 2026-10-04) "For raids, all of your characters join you so...":
  today nothing is drawn into a raid. Should entering a raid bring every
  online buddy of every player in the raid group, and must the raid then
  also reach a tank and healer sum (or several: one per five)?

- (Answered 2026-10-03; replaces the 2026-09-24 rule of no fill with two
  or more players) Several players entering a dungeon together: "Yes they
  should. Please ensure there's at least one tank and healer too. Player
  talents should be summed per tree, and whichever one has the most points
  should be counted as their spec for the purposes of this check. Though
  we should probably abstract that functionality because we'll probably
  need it elsewhere." So the draw fills the group's empty seats from the
  buddies of every player in it; first a tank if the group has none, then
  a healer if it has none, then the rest. A player's role is its spec's:
  the talent tree with the most points (ties: the leftmost), each tree's
  role by class (`buddies_roles.cpp`, a table shared with anything else
  that needs it). A buddy's role is its plan's (the roster's `role`).
- (Answered 2026-10-04) A feral druid player: "Yeah they can do both."
  A tree may carry two roles; feral counts as tank and damage.
- (Answered 2026-10-04) Ties between trees: "ties should pick one of the
  potentials randomly. Unless we can return a tuple of the two or
  something?" Both: the shared reader returns every tied tree (and every
  role they allow); a caller needing one tree gets one of them at random.
  The draw counts every role a tied player can take.

## Suggested Implementation Steps

(The draw for several players, 2026-10-03:) the draw runs once per group
on the first player's arrival (later arrivals find the seats taken); the
group's buddies seated by distance make way; the eligible are every
group player's online buddies; seats left = five less the members; a
tank first and a healer second when the group's players and hand-invited
buddies have none (from the eligible of that role, a random one); then
one at a time from each player's draw bag in turn (a random order of the
players), each bag as before.


1. The `buddy_draw` table (characters database, an install step).
2. A dungeon-entry hook: draw, re-form the group, bring the drawn in.
3. In game: three runs give every buddy a turn before anyone repeats.

## Related Issues

- **617c** parent; **617c2**; **617i** battlegrounds
