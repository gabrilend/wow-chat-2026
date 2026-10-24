# 155z - The Dark Portal Front

## Status
- Created: 2026-10-04
- Phase: 1
- Parent: 155 (basic profile)
- Priority: Medium
- Related: 155k (Outland's monsters +4, its friendly people left alone),
  155l (the Dark Portal the only door; the portal's flight masters),
  617r (elite outfits), 617f (mirror-image looks), 617o (navigation mesh)

## Origin

Verbatim, 2026-10-04:

> also can you make the guards and townspeople in Outland be roughly scaled
> to the threats they are to diminish? It should be an even fight, and one
> should come through the portals with a random running trajectory that
> they adjust like a compass toward a foe. Also there should be 3 different
> "sizes" of monster that attacks. Imp size, character size + 10%, then
> overlord size with between character size * 2 and 15. And they should
> continually attack, and the number of allied fighters that spawns is
> about as many as can fit width wise through the portal per second. They
> charge and attack the monsters that are attacking up a narrow causeway.
> At any time, the player can take a gryphon or flying steed. The
> characters are human and orc and other creature alike. Sometimes there's
> murlocs and furlbogs who spawn. No Quilboar or Quiraji, the jerks. (they
> have other things to focus on)
>
> The paths that they pathfinding take are determined deterministically,
> with a series of lines, curves, splines, running mostly forward. They
> cannot intersect, and they must maintain a certain distance from one
> another. They cannot slow down. They will avoid players, and the profile
> outfits we're making called "elite" will sometimes spawn as hero units
> that help fight. But players are pathfound around because the movement
> pattern is so deterministic - straight ahead, right angle from the
> portal. They only fight monsters who are directly in-front of them, and
> the monsters do the same. They will sort themselves to fill the correct
> amount of space, with larger monsters always having priority, but not
> displacing more than a few. They will attack what's directly ahead.
> Spellcasters on the Horde and Alliance side will cast spells from afar
> (standing still where there's sufficient flowrate to get past them)
> otherwise casting from the front. Ranged casters will clump up ideally,
> causing melee to push forward across their face. Because when you fight
> what's directly ahead, you can fight those just to the side of them when
> you slay a foe. We will iterate on successively more successful tactical
> planning degrees when we have more time to talk. For now, fight to the
> last.

On elites, the same day:

> an elite doesn't get buddy-bots. They are just NPCs that help fight at
> the dark portal. They don't belong to a player. Elites are the
> level-60ish tier (but make sure they're specialized in stats for
> something they can technically use, but which is sub-optimal, like mp5
> on a resto druid) They should fight like the rest of the buddy-bots,
> casting spells if they're ranged characters (only one type per class)
> while clumping on one side of the cause-way. Priests can heal and cast
> smite, druids can cast wrath but not moonfire and rejuvenation (which
> they do to a random injured ally around them every 5 seconds or
> whatever) and other such priorites. Please print a suggested table for
> me when the issue is implemented.

## Current Behavior

Not built. On basic, Outland's hostile creatures are four levels above
stock (155k) and its friendly people (guards, vendors, townspeople) are
stock, so a guard loses to the monsters around its own town. The Dark
Portal's Outland side (the Stair of Destiny, Hellfire Peninsula) has its
stock spawns: a standing line of defenders and the stock demon waves.

## Intended Behavior

A war that never stops at the Dark Portal. Allied fighters pour through
the portal onto the Stair of Destiny, demons climb it, and both sides
meet head on; a player can join it, watch it, or fly off at any moment.
Across Outland the friendly people are a match for the monsters they keep
back. Each part is its own sub-issue:

| ID | Name | Dependencies | Description |
|---|---|---|---|
| 155z1 | outland-folk-scaled-to-threat | None | Guards and townspeople in Outland raised to match the hostile creatures around their own spawn: an even fight |
| 155z2 | front-lanes | None | The paths: lines, arcs and splines, mostly straight ahead at a right angle from the portal; never crossing, a minimum gap, never slowing; players stepped round |
| 155z3 | portal-reinforcements | 155z2 | Allied fighters through the portal, as many a second as fit across its width; humans, orcs and other races, sometimes murlocs and furbolgs; a random start that turns like a compass onto a lane toward a foe |
| 155z4 | demon-tide | 155z2 | Demons up the causeway without end, in three sizes (imp; character +10%; overlord, 2 to 15 times character size); the larger first when lanes are claimed, displacing no more than a few |
| 155z5 | front-combat | 155z3, 155z4 | Everyone fights only what is directly ahead, and the one beside it after a kill; casters stand back where the flow can pass them, else cast from the front, and clump so melee pushes across their face; fight to the last |
| 155z6 | elite-heroes | 155z5 | Elites (617r's outfit format) appear now and then as hero units: level ~60, gear specialised in a usable but off-best stat, one ranged spell kind per class, clumped on one side of the causeway, each class with a short spell priority |
| 155z7 | flight-at-hand | None | A gryphon or flying steed can be taken at any moment of the battle |

Execution order: 155z1 and 155z7 stand alone; 155z2 → (155z3, 155z4 in
parallel) → 155z5 → 155z6.

**What runs where.** Hundreds of moving units on a fixed lane geometry,
each needing a position every tick, is engine work: the lane geometry and
movement belong in C++ (a module beside `mod-buddies`, built by the
owner), with the spawn mix, sizes and tuning as data. The guards' scaling
(155z1) is world-database data, written by a generator as 155k's are.

## Suggested Implementation Steps

1. 155z1 first (data only, no compile).
2. 155z2's lane geometry offline, drawn to an image the owner can look at
   (the way buddy roaming was designed from animations), before any
   server code.
3. 155z3 and 155z4 spawning onto the drawn lanes; then 155z5 combat; then
   155z6 elites; 155z7 at any point.
4. When 155z6 is built, print the elites' suggested table (class, role,
   off-best stat, the one ranged spell kind, the priority list) for the
   owner, as asked.

## Open Questions

1. "come through the portals" (plural): only the Dark Portal, or other
   portals too (Shattrath's, the Isle's)?
2. Which way does the causeway run: demons climbing the Stair of Destiny
   from Hellfire's side toward the portal, allies pouring out of the
   portal down it?
3. Are murlocs and furbolgs on the allied side, or a third side that
   fights both?
4. What happens to a player standing in a lane: stepped round (stated), but
   can a player be hit by, or hit, the fighters?
5. Do kills here give experience, loot or reputation?

## A stopgap, 2026-10-23: the wave demons halfway down

The owner, 2026-10-23: "I want to focus on The Dark Portal. Right now it's
very difficult to get through the hordes of demons - we need to fight
them back." What stands there today is the stock event: level-68 elite
defenders and scripted waves of Fel Soldiers and Infernal Siegebreakers
(70, elite), a Wrath Master (75) and the Pit Commander (76; the last two
raised four levels by E032), against players of 58 to 60. They give no
experience and drop nothing (the server's "no experience" flag, no loot),
so they are an obstacle only. Asked about bringing them to the player's
level: "let's bring them down halfway."

**Built 2026-10-23, install step E069, waiting for an install:** each of
the four moves halfway from its level toward 60, rounded up (Fel Soldier
and Infernal Siegebreaker 65, Wrath Master and Pit Commander 68), still
elite; the levels before are saved for the revert. Tested on the real
world database (applied twice, reverted, back to 70, 76, 70, 75); the
post-install checker has a check for it.

## Answers and questions, 2026-10-23

- **Lanes round players** (asked: "so, we curve the line around the
  players, and when they move away we bend it back to straight?"): yes,
  as 155z2 has it, a player is a circle the lanes bend round, and the
  lanes are laid from the players' positions, so when a player moves
  away the lane is laid straight again. Open: how often lanes are relaid
  (every second, or when a player moves more than a few yards).
- **The random heading and the straight lanes** (asked: "what's the
  relationship between the random heading and the straight-always path
  system?"): in 155z3 as written, a fighter leaves the portal on a random
  heading and turns toward the nearest foe ahead until it joins the lane
  that leads there; from then on the lane holds it. So the randomness is
  only the first few yards, a scatter out of the portal before the lanes
  take over. Open: keep that scatter, or start every fighter straight on a
  lane?
- **Outland's people** (asked: "this only matters in Thrallmar, Honor Hold,
  and Shattrath, right? We removed all the Outland NPCs, right?"): no,
  they were not removed. 155l removed Outland's quests and 155n its
  gathering and trades; about 1,475 service NPCs still stand across
  Outland's towns (26 innkeepers among them: Telaar, Garadar, Sylvanaar,
  Area 52 and the rest). So 155z1 (folk scaled to threat) touches every
  Outland town, not three. Open: all towns, or only the three?
- (2026-10-23, the same day) **The stopgap is dropped, and Outland stays
  hard:** told the portal's defenders would go from 68 to 72 (155z1's +4)
  against demons at 65 to 68: "oh what that doesn't seem right, let's bump
  the monsters back to their normal level again, and nix our previous
  thing. Actually, maybe monsters in Outland are just... really difficult?
  Can we remove the NPC level adjustment? It's okay if they die a lot.
  Outland is hard!" Install steps E069 (the demons halfway down) and E070
  (the friendly people +4) were removed before ever being installed; the
  demons stay at 70 to 76 and the defenders at 68. The front (155z2 to
  155z6) remains the plan.
