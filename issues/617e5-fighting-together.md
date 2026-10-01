# 617e5 - Fighting Together

## Status
- Created: 2026-09-27
- Phase: 6
- Parent: 617e
- Blocked by: 617e1, 617e3
- Priority: High

## Current Behavior

**Playable in the gallery, 2026-09-28** (the owner: "the gallery rendering
was taking too long, my computer can't keep up [...] ok let's make them
playable scenes and allow the user to change certain things with their
mouse on buttons"): "The kraken in a dungeon" (the page's Part 5,
`docs/HTML/buddy-roaming/dungeon-kraken.js` on `roam-pattern.js` and
`scene-kit.js`) replaces GIF 26: the party explores the big dungeon, packs
with a lone outlier each, patrols in the tunnels; buttons for the kraken on
or off, packs, patrols, the melee kind, speed, pause, start over; live
counts of taunts, pulls, slows, blinks, disengages, kills, patrols that
blundered in and deaths. First runs (a stand-in page, 8 simulated minutes)
showed nothing ever pulled: fights lasted about 7 seconds and the next
monsters stood 50-85 yards off, so monsters got more health (160, elites
420), area spells hit 6, the pull reach became 75 yards and each pack
gained an outlier; and the tank could stand still for good at a tunnel's
corner (a sampled line of sight looked clear), fixed by switching to a
planned path when a step is blocked and choosing a new goal after 5
seconds without progress. The rules the scene follows are written down,
language-free, in `docs/roaming-pattern.md`.

Monster reach in the owner-as-tank widget, the owner, 2026-09-28,
verbatim: "the enemies need to be slightly faster than the tank. they
should deal damage even while the tank is moving. Maybe slight increase in
range? There should be a pathing range where they path to be close to,
then a thin strip beyond that where they can attack within. They shouldn't
move after getting in range again until the tank pulls beyond their
pathing radius - this should mean that, if they're faster than the tank,
they will always be dealing damage when they should be able to." Built in
`owner-tank.js` (a pathing radius of 1.8 yards, a strip to 3.0 where they
hit, standing or chasing) and published with the page.


Nothing built in game. A buddy fights what attacks it, what the monster
nudge brings it near (617e3), and whatever playerbots' class strategies do
once in combat. Grind (charging anything within 100 yards) is off for
buddies (617e1, 2026-09-27).

**Drawn, 2026-09-27** (the roaming gallery, `docs/HTML/buddy-roaming.html`,
made by `scripts/generate-buddy-roaming-gifs`; simple simulations of the
intended behaviour, not the game's combat; each caption reports counts the
generator takes from the run, not typed in):
- **20** the first cluster pull ("the blender"): kept as the step before the
  kraken.
- **22** the kraken with a buddy tank: the maw and its quadrants, the tank's
  taunt tentacles (reaching out, and taking back monsters on others), the
  mage and the hunter pulling out-of-reach monsters (one hit and a slow),
  leading them to a neighbouring quadrant, blinking and disengaging, and
  the formation moving on stop by stop.
- **23** the owner as the tank, now an interactive widget on the page (the
  GIF is still drawn, not shown): the owner's dot eases toward the cursor
  or finger, the four buddies (mage, hunter, priest, melee) follow; a lone
  monster gets an ordinary fight; 3+ monsters within area-spell reach of
  each other start the kraken round the owner, the maw chosen by the
  damage dealers (the middle of what the owner holds, leaning toward the
  ranged buddies); the owner takes a monster by coming within 8 yards; the
  mage and hunter pull outliers (one hit and a slow, a neighbouring
  quadrant, blink / disengage, kiting round the maw) only while the
  enemies' threat is under the danger score they learn for the owner
  (starts at 2, an elite counts 3; up 0.5 after 4 healthy seconds holding
  that much, down 1 at low health or when the owner goes down), shown as
  meters; a toggle for the melee buddy's kind (whirlwind, heavy hitter on
  skull then cross, control). Script:
  `docs/HTML/buddy-roaming/owner-tank.js`, its card emitted by the
  generator in 23's place.
- **06** joining and leaving the owner's group, also an interactive widget
  now (the GIF still drawn, not shown): the owner's dot follows the cursor
  or finger; five buddies (warrior, mage, hunter, priest, rogue) roam with
  the owner's waypoint rule (the tenth-of-a-circle turn, the 1-20 point
  step, the 10-yard floor, the 5-yard crowding nudge, the slide along the
  bearing, walking round the rocks); 617c2's grouping runs twice a second
  (every 5 s in game), the rings drawn at half the real distances: join
  your group inside 60 with room, leave past 75, far parties past 74 (join
  one with a member within 70, or pair with a loose far buddy within 70;
  merge within 70 when they fit in five; leave when back within 74 of the
  owner, or more than 74 from every other member; a party of one breaks
  up); white rings and lines for your group, gold rings and lines for far
  parties, and a readout of who is where. Script:
  `docs/HTML/buddy-roaming/join-leave.js`.
- **Both widgets' scripts are embedded in the page** (the generator reads
  each `.js` source and writes it into a `<script>`): the artifact host runs
  scripts only from a few approved CDNs, so the script file published next
  to the page never ran there (the owner, 2026-09-27: "doesn't seem to be
  built and functional on my end"). Checked in headless Firefox with a test
  copy of the page (the animation clock faked, synthetic pointer moves,
  errors caught): both run without errors, the owner's dot moves, the
  kraken forms and grouping changes as the owner walks; correct at phone
  width.
- **The gallery is in parts** (Part 1 first readings; 2 the owner's
  waypoint rule; 3 paths and the ground; 4 exploring; 5 fighting together;
  6 play it yourself, the two widgets), in the page's order rather than
  the scenes' file numbers; a scene in no part, or two, stops the
  generator.
- **24** kiting alone: a mage and a hunter leading monsters toward the most
  room, with a per-direction danger memory (recent danger, and monsters they
  killed due back) turning them away from due directions.

What drawing it showed, for building it:
- Most pulled monsters are taken by the tank's taunt before they reach the
  puller: the puller only has to bring a monster within 30 yards of the maw.
- Escapes happen only because casters stand to cast. A monster as fast as
  the puller never catches one that keeps walking away; the kiting rhythm
  (cast, the monster closes, blink or disengage) comes from cast-time
  spells. A hunter needed its steady shot standing and its slow on a
  cooldown longer than the slow (as in the game) before it ever had to
  disengage.
- A ranged pull brings the monster's whole linked pack; a pulled pair keeps
  a puller kiting for a taunt cooldown while the tank takes them one at a
  time.

## Intended Behavior

Owner, 2026-09-27, verbatim:

> for fighting monsters, buddy-bots should help each other when they can.
> Also, they should try and grab extra mobs if they think they can handle
> them. It is common in World of Warcraft to grab a bunch of mobs and then
> AoE them down - we should try and find "clusters" of monsters that are
> within leash radius of each other, and have tank characters try to grab
> them all and bring them to a central location. DPS characters will
> prefer casting AoE spells on clusters of monsters, and they will prefer
> casting AoE spells over single-target unless there's a boss or
> something, in which case they'll prefer AoE and single-target spells
> roughly equally.

- **Helping**: a buddy that sees a clanmate (another buddy of the same
  owner, or the owner) in a fight within reach joins it, whether grouped or
  not.
- **Taking on more**: a buddy judges whether it can handle one more
  monster (its health, the monsters' levels and number, its role), and if
  so pulls the next one near.
- **Clusters**: groups of monsters close enough to each other to be pulled
  together (within their leash/link reach) are found; a tank buddy
  gathers a cluster and brings it to a gathering spot, where the others
  AoE it down.
- **AoE first**: damage dealers prefer area spells on clusters over single
  targets; against a boss (an elite or rare, a dungeon boss) area and
  single-target spells are weighed about equally.

### Decisions, 2026-09-27 (Ritz): moving in fights, a cluster pull to see first

> bots should keep painting while fighting, and they should move a little
> and jump about while fighting, unless they have cast time spells. Then
> they should use things like blink to try and get distance, ideally after
> doing a frostbolt to slow them down.

> [a GIF of a cluster pull first:] absolutely yes please. We might need a
> larger arena.

- **Moving in fights**: a buddy with no spell to cast (or casting only
  instant spells) shifts about and jumps now and then while fighting; one
  with cast-time spells stands to cast, and makes distance when it can:
  a slow first (Frostbolt), then a gap closer in reverse (Blink, Disengage
  and the like).
- **A cluster-pull animation first**, on a larger drawn arena, before
  building it in game.

### Decision, 2026-09-27 (Ritz): the tank gathers like a blender

> okay for the tank pulling a pack gif, the tank very clearly did not pull
> the extra mob in the first pack, preferring instead to wait until the
> third engagement. Instead, they should try and gather nearby enemies,
> using their ranged taunt abilities to pull them closer so they can be
> AoE'd down. Think like a blender reaching out and pulling foes into it's
> maw.

- The tank, holding a pack at the gathering spot, keeps reaching out:
  any other monster near enough is pulled in with a ranged taunt or pull
  (Taunt, Hand of Reckoning, Death Grip, Growl, a thrown weapon or a
  shot), so it joins the pack and dies in the same area spells.

### Decisions, 2026-09-27 (Ritz): the kraken, and kiting

Verbatim:

> for the blender, I want you to picture a kraken sitting at the base of a
> massive whirlpool. It has tentacles that reach out and grab nearby ships
> and pulls them into it's insatiable maw. That is the tank, and the DPS
> characters (or the tank) can pull characters into the center of where
> they're applying AoE. The tank should be able to move in a small radius
> from the AoE spot, just enough that the mobs stay within the AoE but the
> tank might be able to reach further mobs to taunt and pull in. The taunt
> is 30 yard range I think. Also, DPS, especially ranged DPS, can pull
> monsters. They do this by orbiting when they can, between cast-time
> spells they often can cast an instant spell while moving. So they'll do
> that to move to within range of another mob. Then, they'll hit them once
> to generate as little threat as possible, and apply a movement slowing
> effect. Then they move to the opposite side of a neighboring quadrant
> (projected out from the AoE spot) but not the opposite quadrant. The goal
> is to pull them within range of the tank, who will notice and apply
> threat generation abilities to them to get them to target. Then, the
> tank will move to the opposite side of the AoE from the pulled mob, at
> least until it's within the AoE zone, then it will continue trying to
> grab distant foes. If all the mobs are slain and the AoE zone is empty,
> then the entire structure moves on. This should be a "battle pattern"
> that buddybots can perform, and it can only be done when there's a tank
> in the party. If the player is the tank, they'll try and perform this
> behavior if they can, but only if 3 or more monsters are near each other
> and AoE-able.

> the kraken tentacles are the tank's taunt ability, and the ranged DPS who
> are doing pulls and slows. They will often use blinks or the hunter's
> Disengage ability to create more distance. This is a "kiting" pattern,
> and hunters and mages do it in the wild when alone anyway. They should
> try and kite the mobs in a circle around the DPS zone where AoE's are
> being cast, until the tank picks them up. When they're alone, they'll
> try and kite the mobs to the area that has the most distance to other
> enemy mobs - they want the most space to kite within. They will also try
> and avoid areas that they expect to find mobs spawning at soon, because
> they keep mental track of how long it's been since there was danger in
> that direction.

**The kraken** (a battle pattern; only with a tank in the party):
- **The maw**: the AoE spot, where the pack is held and the damage
  dealers' area spells land.
- **The tank**: stays within a small radius of the maw (the monsters stay
  inside the AoE), leaning out to reach farther monsters with its taunt
  (30 yards); when a monster is pulled in from one side, the tank steps to
  the opposite side of the maw until that monster is inside the AoE, then
  reaches out again.
- **The tentacles**: the tank's taunts, and the ranged damage dealers'
  pulls. A ranged pull: orbit round the maw, casting instant spells while
  moving, until in range of an outside monster; hit it once (as little
  threat as possible) and slow it; then move to the far side of a
  **neighbouring** quadrant (seen from the maw), never the opposite one,
  drawing the monster within the tank's reach; the tank notices and takes
  it with its threat abilities.
- **Kiting**: blinks and Disengage make distance; a kited monster is led
  in a circle round the maw until the tank picks it up.
- **Moving on**: when every monster is dead and the maw is empty, the
  whole pattern moves on.
- **An owner who tanks**: the buddies run the pattern with the owner as
  the tank, but only when 3 or more monsters stand near each other where
  area spells reach them all.

**Kiting alone** (hunters and mages in the wild): lead the monsters toward
the place farthest from other monsters (the most room to kite), avoiding
directions where monsters are expected to appear soon: each buddy keeps a
memory, per direction, of how long since it last met danger there (a
monster seen, a respawn), and treats a direction whose danger is "due" as
closed.

### Decisions, 2026-09-27 (Ritz): the maw, party vibes, pull limits, memory

Verbatim:

> [where the maw is when the owner tanks:] the maw should be the AoE zone,
> where the DPS characters have the most focus and attention. This should
> take their ranges into account, to know generally within where they can
> target switch and which ones they shouldn't be able to. Just
> generally... pulling your ranged dps along. Trust the DPS to find the
> optimal spot, all you gotta do is drag foes toward it. the melee DPS
> should be either spinning blades in melee, or focused heavy hitters
> designed to cull and reduce damage gain. Depending on the nature of the
> classes in the party, the "feel" or "vibe" of the party will shift, and
> the gameplay will vary accordingly. - sorry, their target priorities
> will vary accordingly, if they're focused stabs (assassination) or
> focused heavy hitter (ret paladin, arms warrior, blood death knight, in
> an alternate universe, survival hunter) then they'll target one high
> priority target together, "target the skull then the X" meanwhile if
> they're config like subtletly or frost mage you'll try and slow or
> disable foes. Frankly I think they should have a taunt too, but Blizzard
> didn't think players would be able to handle it. Problem is, the only
> reason to pull them out of the AoE is if you wanna reduce damage on the
> tank. And Blizzard made the tank's durability their own concern.

> [pulling pairs:] they should know how many a pair is, and if the tank's
> danger score or threat level (calibrated based on watching how fast they
> wanted to pull over time as they got used to each other, giving the tank
> deference until they knew if they were able to handle more. Watching
> their health totals, listening for parries and redoubts. Doing well? Or
> are the monsters more screamings?) is too parameter, they won't pull any
> more until the total "threat level" of the enemies calms down.

> [the taunt interval:] well, in-game the tank has more than just a taunt,
> they can charge (and in doing so, adjust the AoE target's location) or
> throw avenging shield or whatever. In this simulation they just are
> doing an abstract "taunting" ability which pulls an enemy's focus
> permanently on them.

> [the danger memory:] yes, reset on logout / login. Except, summarized
> heavily on login, because you were in a dream.

> [instead of the owner-tanks GIF:] can we create an interactable widget
> where the player dot follows the cursor? Not 100%, but it moves toward
> the cursor when the cursor isn't on it's location. And hte rest of the
> party follows suit.

- **The maw is chosen by the damage dealers**: the spot where their
  ranges overlap best (from where they can all reach and switch targets);
  the tank (buddy or owner) drags monsters toward it. A tank's charge or
  leap moves the pack, and with it where the maw is best.
- **Party character by composition**: melee damage dealers are either
  whirlwinds (area melee: spinning blades) or focused heavy hitters
  (assassination, retribution, arms, blood, survival in spirit) who kill
  one marked target together, skull then cross; control specs
  (subtlety, frost) slow and disable. The mix of classes sets the party's
  target priorities and so its feel.
- **Pull limits from the tank's danger**: pullers know a pack's size; they
  keep a danger score for the tank, learned while fighting together
  (starting deferential: the tank's own pulling pace; then its health
  over time, parries and dodges, how loud the fight is); while the
  enemies' total threat is above what the tank has shown it handles, no
  more pulls until it calms.
- **The simulation's taunt is abstract**: one ability standing for all of
  a tank's ways of taking a monster (taunt, charge, thrown shield).
- **Danger memory**: each buddy's own; kept through the session; at login
  only a heavy summary survives ("you were in a dream").
- **The owner-tanks scene becomes interactive**: a page widget where the
  owner's dot eases toward the cursor and the party follows and fights.

### Decisions, 2026-09-27 (Ritz): patrols, a big kraken arena, playable scenes

- "can we make 1/3rd of the monsters be patrols that wander? Just on a set
  path, an L shape is enough for this size map." (The kraken animation.)
- "can we have that behavior on a paint heat map, except without the
  paint, but with the pathing of the 3rd one? The map can be increased in
  size because we only need one - so how about 4x in size [...] more
  tunnels to explore, more connection types to see examined. The pathing
  of monsters between them will be especially apparent. L shape..."
- "can we also make the drawn gifs be interactible with the mouse?
  Highest priority. Just the ones that feature the player dot, to show
  them what mechanics they'll be working with when they're piloting a
  story." The joining-and-leaving scene becomes a widget like the
  owner-as-tank one.

### Decisions, 2026-09-27/28 (Ritz): monsters faster; the widgets a little faster

> in the simulations, the enemies should move faster than the player, so
> they can always hit.

> can we make both the players and the monsters a little faster? Maybe
> like 20%. Just for the scenes with the player dot.

- **Monsters out-pace the party** in every drawn fight: 1.6 against the
  buddies' 1.3 to 1.5 (20, 22, 23, 24, 26), so no one out-walks a
  monster; slows, blinks, disengages and taunts are what save a kiter.
- **The two widgets 20% faster** (owner and monsters alike): the owner
  8.4 yards a second (was 7), monsters 9.6 (was 8, itself up from 6.2),
  buddies in the grouping widget 4.8 (was 4). The GIFs keep their speeds.

### Findings, 2026-09-28 (Ritz): the party in the dungeon's tunnels (to fix)

Verbatim:

> for this one: The kraken in a dungeon
> the party is having trouble navigating through tunnels - can you describe
> the tunnel logic to me? Right now, usually the tank will push forward but
> one or two of the DPS / heals will be left behind. They get stuck on the
> "rim" of the tunnel, not pathing into it. Remember the paint extruding
> from the walls? Once they find a tunnel, they should try and walk down it
> unless there's combat to attend to. Also the mage can cast an AoE maybe?
> 3 or more targets, otherwise they focus the lowest health target down.
> same for the fairy dps.

What the scene does today (`docs/HTML/buddy-roaming/dungeon-kraken.js`):
- The tank alone chooses where to go: a random spot 15 to 75 yards away
  with the least buddy paint, farther from the entrance better. It ignores
  the walls' paint when choosing, and has no tunnel sense (the sensing is
  only in the other dungeon scene).
- Each follower aims at its own fixed spot in a fan round the tank, 6 yards
  out. In a room that works; at a tunnel mouth, 8 yards wide, most of those
  spots lie inside the rock. A follower asks for a path to a spot inside
  rock, gets none, and pushes at the wall: stuck on the rim, as seen.
- The mage casts an area spell when 2 or more monsters are in the maw.

Owner's answers, 2026-09-28, verbatim: "the buddy-bots should be able to
move anywhere they'd like within the areas not covered by an aggro zone
from one of the monsters." "buddy bots shouldn't follow the tank, though
having 'follow' behavior built is a good thing. They should traverse the
dungeon on their own, alongside the tank and others." "[the fairy dps:]
don't worry about it."

To fix (not built):
- No following: every buddy explores the dungeon on its own (its own
  least-paint and sensing), alongside the tank and the others; a follow
  behaviour exists as a separate capability, not the default.
- Anywhere open except inside a monster's aggro radius: a buddy's walkable
  ground is every open cell outside the living monsters' aggro circles
  (a fight is entered on purpose, by the pull, not by wandering in).
- The tank uses the sensing and the walls' paint: once a tunnel is found it
  walks down the tunnel's middle (the walls' paint is lowest there) until
  the ground opens, unless there is combat.
- Damage dealers: an area spell at 3 or more targets in reach, otherwise
  the lowest-health target first. "The fairy dps" is to be asked (the
  scene has no fairy; the healing-fairy gear theme it may have come from
  was test data, taken out of the design 2026-10-01, so it is not a fifth
  party member).
- The owner has trouble seeing updates in the page; the widgets are
  renderers of the data model, and the game client handles much of this
  in the end.

### Musing, 2026-09-27 (Ritz): seeing instead of rules

> you know, this might be overkill. We might just be able to have a
> rendering in our heads that dynamically updates accordingly. (game
> client rendered as a scene through the buddy-bots eyes - it decides
> moment to moment a place on the 2d picture to go, selects a region that
> looks preferrable, then uses that to translate directly to
> in-world-space-coordinates and uses them as potential waypoints and
> points of interest. The character is expected to be able to judge
> distance, and their intuition is created using machine learning.

Recorded as a direction, not a decision (see the reply of that date).

## Suggested Implementation Steps

1. Research what playerbots already has: assist strategies ("dps assist",
   "tank assist"), "aoe" strategies and their thresholds, "pull", how a
   bot rates danger; and the server's creature link/assist range.
2. Helping: in the roam pass, a buddy not in combat with a clanmate in
   combat within reach attacks that clanmate's target.
3. Clusters: a cluster finder over nearby monsters (link distance), the
   tank's gathering spot (the cluster's middle, or a clear spot near it),
   the tank's pull route.
4. AoE preference: the damage dealers' AoE thresholds lowered for buddies
   (playerbots' settings or strategy relevance), equal weighting on bosses.
5. The "can I handle it" judgement: a simple rule first (health above a
   share, count below a number by role), tuned in the balance file.
6. A GIF in the roaming gallery showing a cluster pull before building in
   game, if the owner wants to see it first.

## Related Issues

- **617e** parent; **617e1**; **617e3** the monster nudge
