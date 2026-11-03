# 919b - The Three Planets as Maps

## Status
- Created: 2026-10-20
- Phase: 9
- Parent: 919 (three worlds: Earth, Mars and the Sun)
- Blocked by: 919a (the first generated map through the pipeline);
  world-edit-to-execute W09c (projection), W09d (synthesis), W09e
  (climate and biomes), W09f (the Sun's photograph and bedrock)
- Related: 905 (portal dimension system)
- Priority: Low

## Current Behavior

Not started. 919a, when built, makes one regional map. Nothing makes a
whole planet, and nothing in the game leads to a new map.

## Intended Behavior

Earth, Mars and the Sun each become a world a player can stand on, every
part of the sphere present somewhere on its map(s):

- **The projection** (W09c) lays the sphere flat with more yards where the
  ground is "most dense" (the owner: "curved where it's most dense"; "if
  we want to cover the whole planet, we're going to need to create emphasis
  through-itudes"). Latitude and longitude lines, drawn on the map, would
  bunch together over plain ground and spread apart over the places that
  matter, so those places get room to be walked through.
- **The height** is fitted into the range the client is tuned for ("flattened
  to fit in the game's natural Z space"), measured from the stock maps
  (W09 open question 4).
- **Getting there**: each world is entered through a portal (905's
  dimension gates are the model), and leaves the same way. Hearthstones
  bind per world.
- **Per world**: sky and light (the client's light tables for a map id),
  weather from W09e's climate (the server's weather system takes weather
  per zone, so each biome region is a zone with its own weather chances),
  and an area table so zone names show (Earth's from real place names,
  the Sun's from the owner, open question 2).

## Suggested Implementation Steps

1. Decide one map or six per planet (W09 open question 2); reserve the map
   ids.
2. Generate each world with W09 (Earth: Earth's shape and Earth's
   descriptions; Mars: Mars's shape and Earth's descriptions; the Sun: the
   photograph's statistics and the bedrock rule).
3. Convert and register with W02a/W02c/W02d; write the area table rows
   and light rows by the converter, not by hand.
4. A portal in each home continent (one install patch per world, gated on
   the chosen profile) and a return portal at each world's arrival point.
5. Weather rows per zone from W09e's output, written by the same converter.
6. A test that teleports to each world, checks ground heights at sampled
   points, and takes a screenshot from each arrival point.

## Open Questions

1. Should a player be able to walk off one edge of a world and arrive at
   the other (east edge to west edge), as on a real sphere? One map's
   edge can be a teleport line; it is a seam players will notice.
2. Who names the Sun's zones?
