# 413 - Horseshoe Pursuits: Upside-Down Gathering Nodes

## Status
- Created: 2026-10-12
- Phase: 4
- Related: 617e3 (buddies go to chests and nodes), 173d (the custom
  client's models and world objects)
- Priority: Low
- State: planned; open questions first

## Origin

Verbatim, 2026-10-12:

> also, can we add a certain number of new resource nodes to the game?
> They should be spawned like minerals and herbs. Rather, each mineral and
> herb has an increased spawn rate, and a proportional amount of them are
> now the new resource node. They should be... Upside-down, static,
> floating at the tip of their highest modelled point at the top of the
> ground, but the model itself is upside-down turned around, ideally
> perpendicular to the nearest downward slope. Follow the points until
> they next go up, then stop following that line of outward facing
> points. Pick a direction that stays going "down" the longest, the first
> time it does so. That's the one it should be oriented perpendicular
> around. The animation should be frozen. It should have glowing sparkles
> like mineral nodes and plants do. It should just be there. The names of
> the new nodes should be in japanese, and they should be named
> "horse-shoe pursuits" but named with the most transliterated
> pronunciation like "horushupurushuts'" like "ho ru shu, pu ru shu tsu"
> but with the tiny tsu like in "mi ka" three things like "mi tsu tsu" but
> the second tsu is tiny. and it should try and describe horses (the
> animal) wearing human shoes (like boots or galoshes) and business
> pursuits to provide them. And each one should be a different poetic
> device to explain such things. Just... absolutely deliverance wretched.

## Current Behavior

Herbs and mineral veins appear through spawn pools: each pool is a group
of possible places, of which a fixed number hold a node at a time (for
example "Copper Vein Durotar Skull Rock (3 spawns 12 locs)": 12 places, 3
in use). The basic world has 3,279 herb and mineral pools with 4,341
nodes up at once (2026-10-12: pools in `acore_world_basic.pool_template`
whose description names an herb, vein, mine or deposit). No other
kind of gathering node exists. Every node stands upright, on the ground.

## Intended Behavior

**More nodes, a share of them new.** Each herb and mineral pool holds
more nodes at once than it does now; the extra ones are a new kind of
node, the Horseshoe Pursuits, in proportion to the increase.

**How a new node sits:**
- upside down, so the model's highest point becomes its lowest and just
  touches the ground; it floats there, held by that tip;
- tilted to the slope. From the node's place, lines run outward in many
  directions across the ground. Each line is followed while the ground
  keeps falling and stops where it first rises. The line that falls
  furthest wins (on a tie, the first one found), and the node is turned
  to face along that line and stand perpendicular to it;
- its animation frozen; no movement at all;
- sparkling as herbs and ore do (the server can switch on the client's
  sparkle on any object, a per-object flag);
- static: it never moves, despawns or reacts except to being gathered
  (open question 3).

**Names** in Japanese katakana: "horseshoe pursuits" in the most
transliterated spelling, ho-ru-shu pu-ru-shu-(small tsu)-tsu, ホルシュ・
プルシュッツ, the small ッ as in みっつ. Each kind of node is a different
poetic device (alliteration, chiasmus, zeugma, anaphora, ...) describing
horses wearing human shoes (boots, galoshes) and the business ventures
that supply them.

**The placing is computed by a tool, not by hand**: a generator reads each
pool's places, the extracted ground heights, and the model's height, works
out each node's height and tilt, and writes the SQL that adds the spawns.

## Suggested Implementation Steps

1. Answer the open questions.
2. The node kinds in `gameobject_template` (one per name), gatherable,
   with the sparkle flag and their loot.
3. The slope walk: a ground-height reader over the extracted maps, the
   outward lines, the longest fall; a test of it on made-up ground (a
   cone, a plane, a valley).
4. The generator: for each herb and mineral pool, its raised count and
   the new spawns at its places, upside down (a rotation of 180 degrees,
   then the tilt), raised by the model's height so the tip touches the
   ground; writes the SQL.
5. An install step for the profiles that want it.
6. The client font, if names stay in Japanese (open question 1).
7. In game: walk Durotar, find them, gather one.

## Open Questions

1. **The client can't draw Japanese.** The stock English 3.3.5 client's
   fonts have no Japanese characters, so a katakana name shows as blank
   or as boxes. Fixes: a Japanese-capable font placed in the client's
   Fonts folder under the name of the font it replaces (each player's
   client changes), the custom client drawing it, or the name in romaji
   (HORUSHU PURUSHUTTSU). Which?
2. Which model is turned upside down? A horse? A boot? An existing node
   model (an herb, an ore vein)? One model for all kinds, or one each?
3. What does gathering one give, and through which skill: herbalism,
   mining, either, or none (anyone can take it)?
4. How much more: each pool's count up by how much (a quarter more, half
   again, double), and is every extra node a Horseshoe Pursuit, or a
   share of them?
5. How many kinds (and so how many poetic devices and names)?
6. Where does the description live? A node shows only its name when
   hovered. The poem could be the text of an item it drops, or a page
   that opens when it is clicked.
7. Which profiles: basic only, or every profile?
8. "perpendicular to the nearest downward slope": the node's upright line
   at right angles to the ground (leaning with the slope), or standing
   level and only turned to face downhill?
