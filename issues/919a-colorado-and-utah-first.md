# 919a - Colorado and Utah First

## Status
- Created: 2026-10-20
- Phase: 9
- Parent: 919 (three worlds: Earth, Mars and the Sun)
- Blocked by: world-edit-to-execute W09a-W09d (readers, describers,
  projection, synthesis) and W02a, W02c, W02d (terrain into map files,
  registration, server data)
- Priority: Low

## Current Behavior

No map made by this project exists. The ambush (`src/lua-beta/ambush.lua`),
traveller (`src/lua-beta/travel.lua`) and treasure systems run on any map
that has ground heights, but there is no new ground for them.

## Intended Behavior

One map, before any planet: the ground from the Colorado Front Range west
over the Rockies into the Utah canyon country, and east onto the plains.
The owner, 2026-10-20: "I've always lived along the rockies. They feel like
my spine. the very bones of the nation. anyway I was wondering what
Colorado, Utah, etcetera, would look like in a World of Warcraft gameplay."
And later the same day: "I never actually lived in Utah. It's just nice
there."

It is made at **real-world scale** (the owner, 2026-10-20: "can we make it
real-world scale? My character is about 6 feet tall."): one game yard is
one real yard. One map then holds a 31 km square, so the first map is one
square of it, where the foothills meet the plains (Boulder to Golden, say;
open question 1), and the rest of the region is more maps built from the
same recipe, each its own square (the whole stretch from the canyon country
to the plains is a few hundred). Heights go in as they are, from USGS
3DEP's 1 m lidar, finer than the client's 3.8 m terrain cells: the
mountains are their true 2,000 yards above the plains. The describers (W09b,
W09d) only add what is smaller than a cell (stones, scrub), and are checked
against the real ground they describe. Buildings and roads come from
OpenStreetMap (919d's footprint buildings), land cover from the satellite
layer.

(An earlier draft used a "regional scale" of about 18 m per yard, so the
whole region fit on one map. Replaced by real scale the same day.)

What it is for:

- **Proving the generator** on ground the owner can judge by eye: does the
  plains' ground roll when you stand on it and flatten toward the horizon?
  Do the canyons read as canyons?
- **The plains as danger.** On flat ground a player sees nothing coming and
  has no landmark to steer by ("you'd have no idea if you were walking into
  a deathtrap. can't see anything, how can you orient yourself?"). The
  ambush system spawns monsters 120-160 yards out; on the plains that
  distance is inside sight, in the mountains it is behind a ridge. The same
  rule feels different on each ground, which the map shows.
- **The first map through the whole pipeline**, so 919b's planets start
  from something that already loads.

## Suggested Implementation Steps

Nothing here is done once by hand. The owner, 2026-10-20: "as we're
building this process we should make tools and utilities to accomplish
tasks instead of doing it once for the project. That way we can build and
update them easily." So this map is a **world recipe** (a data file naming
its bounds, scale, sources and the descriptions to grow from; W09's tools
section) and every step below is one of W09's tools run on that recipe.
Changing the edges is an edit to the recipe and a rebuild.

1. Write the recipe `worlds/front-range.lua` in world-edit-to-execute,
   with the region's bounds (latitude/longitude box) from the owner (open
   question 1) and the three sub-regions to describe (plains, Front Range,
   canyon country).
2. `fetch-ground` (W09's fetcher) brings the recipe's elevation, satellite
   land cover and OpenStreetMap rivers, lakes and roads.
3. `build-world` (W09's builder) describes, grows, runs the climate pass
   (the plains dry from the mountains' rain shadow; OpenStreetMap's rivers
   and the satellite land cover check where the climate pass put them), and
   writes the WoW map files through world-edit-to-execute's W02a/W02c/W02d.
4. Register a map id from the range this project uses (W02 open question 3),
   written into the recipe.
5. Add the map to one profile (919 open question 3) with a test patch that
   teleports a test character there; take screenshots from fixed spots and
   file them in `development-history/`.
6. Walk it: at sampled points the ground height on the server matches the
   generated grid within 0.5 yards (W02's own check); ambushes spawn and
   reach the player on all three kinds of ground.

## Open Questions

1. **Where are the edges?** A suggestion: from the Utah canyon country
   (around the Green and Colorado rivers' meeting) east over the Rockies to
   the plains about 150 km east of Denver. Is that the piece, or should it
   centre on the stretch of the range the owner has lived along (which
   stretch is that)?
2. **How do the squares join?** Neighbouring real-scale maps are separate
   maps in the client, so walking off one edge is a teleport with a
   loading screen onto the next. Acceptable for the stock client, with the
   custom client's streamed tiles (its 173s) as the seamless way later?
