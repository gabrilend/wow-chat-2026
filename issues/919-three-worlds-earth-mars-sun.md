# 919 - Three Worlds: Earth, Mars and the Sun

## Status
- Created: 2026-10-20
- Phase: 9 (Storytelling & World Structure)
- Blocked by: world-edit-to-execute W09 (pattern describers and the planet
  map generator, `/home/ritz/programming/ai-stuff/world-edit-to-execute/issues/W09-pattern-describers-and-planet-map-generator.md`),
  which needs that project's W02a, W02c and W02d (terrain into WoW map
  files, map registration, server data)
- Related: 905 (portal dimension system: how players would travel between
  worlds), 3xx ambush and 5xx traveller systems (what lives on the new
  ground), 920 (legendary friends, written from the same message)
- Priority: Low (design; nothing can be built until W09 makes ground)

## Origin

The owner, 2026-10-20, verbatim (the whole message, which also asked for
issue 920):

> hi can we ummmmm make some issue files, with a number 9, and a large fry and coke...
>
> three worlds.
>
> world.
>
> map.
>
> generator.
>
> earth, mars, and the sun.
>
> then, use /home/ritz/programming/ai-stuff/world-edit-to-execute/ to create data describers that correlate patterns and generate realistic or plausibly interesting conceptions for a world shaped with the same geometry, but differing components. For example, what if mars was patterned like earth? the west half of north america, or the flat plains of kansas, rolling when not at a distance? god... in a place like that, you'd have no idea if you were walking into a deathtrap. can't see anything, how can you orient yourself? I've always lived along the rockies. They feel like my spine. the very bones of the nation. anyway I was wondering what Colorado, Utah, etcetera, would look like in a World of Warcraft gameplay. We could use google maps views to generate plausible 3d structures, and then wind them around each other so it always covered all of the space, sized appropriately.
>
> ... or something like that. I only make sense when I'm stoned.
>
> oh also the sun planet should use as it's bedrock some super material that is inflexibly rigid. Essentially, adamantium. How hard is it for medieval peasants to dig into the earth? They couldn't make it far. Not even 1% of the way through the crust. It's so thick... anyway it's that hard. If we had water and wind and current cycles and seasons, how would that look / work, when projected onto the terrain-shape generating worldspace? I wonder if it'd be like Broxigar. Can you create him as an NPC if we don't have him yet? We should inform his personality according to wow-wiki. actually can you make the issue file for several unavailable characters like Alexandros Mograine and Highlord Hrothgar? you can give me ideas for additional ones if you want. They should be kept as user-based chatbot style UI messages in each player's client, like an interface addon. These three can come with the game, one from each continent. Though Broxigar represents Kalimdor, idk if he's actually from there or not. Anyway Highlord Hrothgar is, I think, if I remember correct, a Vyrkul chieftain. Hrothgar's Landing is named after him, but that might be Final Fantasy sixty-teen. Anyway he's a cool dude because he lives in Northrend. Maybe also Terokk from Terokk's quil? Or is that a demigod... Should speak in telepathic english, meaning it's perfect responses with no cawing because humans don't really "get" that very well. But sometimes they listen to command words like "help" and "crooked crime" or whatever.
>
> anyway the players would always be created with them in their friends list, so they can chat on the go. And we can make a phone app so they could talk to them IRL too, meaning you could live with your chatbot friend.
>
> anyway for the sun map, and the mars etc ones too, we'd have a "texture to world scene mesh" flattened to fit in the game's natural Z space. Or rather, curved where it's most dense. then we could use that to twist and wind our way toward acceptable parameters. For example, if we want to cover the whole planet, we're going to need to create emphasis through-itudes.
>
> then, we could model what kind of biome's theyd be like. and render it with that ground texture. Maybe, with time, we could auto-generate plausible looking things that nobody is looking at so when they turn around the corner, there it'll be. Characters, endlessly wandering, nobody knowing how to find each other or ever ever get back. That sounds terrifying! Especially since it's on the projected statistics mapping of the sun's surface, as measured from a flat photograph!

(The "number 9, a large fry and coke" is the phase: these are phase 9
issues.)

## Current Behavior

The game has the stock 3.3.5a maps only (Eastern Kingdoms, Kalimdor,
Outland, Northrend, and the instances), emptied of creatures (phase 2).
No map in the game was made by this project. world-edit-to-execute has
designed, but not built, a path from a terrain grid to WoW map files
(its W02a-W02d), and now has W09 for growing a terrain grid from real
planets' patterns.

## Intended Behavior

Three new worlds, each a map (or a set of maps, W09 open question 2) the
client loads and players walk on:

- **Earth** — Earth's continents and oceans, grown with the patterns of
  real places. The west half of North America is the first piece: the
  Rockies as the spine, Kansas's plains to the east, rolling up close and
  flat to the horizon, where a player cannot see what is coming and has
  nothing to steer by.
- **Mars** — Mars's shape (its great volcano bulge, its deep basins, its
  canyon) filled with Earth's patterns: "what if mars was patterned like
  earth?"
- **The Sun** — the statistics of the Sun's surface, measured from a flat
  photograph, as ground. Its bedrock is unbreakable ("Essentially,
  adamantium"), so water and wind cut down only to it and then spread
  sideways: flat-floored valleys and steep-walled tablelands, the shapes
  hard caprock makes on the Colorado Plateau (Utah's mesas are this, on a
  small scale). Its granulation cells (each about 1,000 km across on the
  real Sun, about 14 yards at whole-planet scale) and supergranule cells
  (about 30,000 km, about 400 yards) become the ground's honeycomb of
  basins and ridges.

### Real-world scale

The owner, 2026-10-20: "can we make it real-world scale? My character is
about 6 feet tall." At real scale one game yard is one real yard, and one
WoW map (34,133 yards on a side) holds a 31 km square of real ground,
about 974 km². What that means, worked by hand (`world-scale`, W09's
calculator, gives the exact numbers per recipe):

| Ground              | Maps at real scale | Note |
|---------------------|-------------------:|------|
| A foothills square  |                  1 | Boulder to Golden, say: 919a |
| Colorado            |                277 | each a separate map, a loading screen between |
| Earth               |            523,600 | far beyond files on disk |

So real scale changes what the generator does:

- **Real places are real.** US ground has 1 m lidar elevation (USGS 3DEP),
  finer than the client's 3.8 m terrain cells, so its heights go in as
  they are, and the describers only add what is smaller than a cell
  (stones, scrub). Mountains are their true size: the Front Range rises
  about 2,000 yards above the plains.
- **Whole planets cannot be files.** A full map of terrain files is in the
  hundreds of megabytes, so Earth would be hundreds of petabytes. A
  real-scale planet is only possible if ground is generated as players
  walk toward it: the custom client (`/mnt/kaun/custom-client/`) streams
  terrain tiles (its issue 173s) and could ask for generated ones; the
  server would need its ground heights from the generator too. The stock
  client needs files in advance, so for it the planets stay at the scaled
  sizes in W09's table, with real-scale regions as separate maps.
- **WoW is not drawn at real scale.** Its doors, trees and buildings are
  larger than life beside its characters. A tool measures the client's
  character and building models (their bounding boxes) so the recipe's
  scale can be set to "real to the character" or "real to the
  buildings" (open question 4).

### Two maps of the same ground, one overlay

The owner: "we will need to create an overlay for these two to overlay
each other with datapoints accessible from both", OpenStreetMap and the
satellite land cover, "projected onto" the elevation. W09a's grid holds all
three at once, cell by cell, and indexes both ways: from a cell to every
OpenStreetMap feature and land-cover class in it, and from a feature (a
river, a building) to every cell it covers.

Each world has weather and water by W09e (sunlight by season, prevailing
winds, rain and rain shadows, rivers, erosion), biomes from that weather,
and the biomes' ground textures from the player's own WoW client files.
What lives there comes from this project's own systems: ambushes, travellers
and treasure work on any map with ground heights.

## Suggested Implementation Steps

| ID   | Name                            | Dependencies         | Description |
|------|---------------------------------|----------------------|-------------|
| 919a | colorado-and-utah-first         | W09a-W09d            | One playable region before any planet: the Colorado Front Range, the plains east of it and the Utah canyon country, as one map at a scale where a mountain is a mountain (not whole-planet scale). Proves the describers and the generator on ground the owner knows by heart |
| 919b | the-three-planets-as-maps       | 919a, W09c-W09f      | Earth, Mars and the Sun as whole-planet maps: map ids, registration, server data, how players reach them (905's portals), and per-world settings (sky, light, weather) |
| 919c | things-made-where-nobody-looks  | 919b                 | Spawning out of sight: things appear only where no player is looking (behind every player's view, beyond the fog), and travellers who wander the planets forever with no destination |
| 919d | the-architect                   | 919a, 916, W09, W05  | A whisperable character players tell how a place really was, from memory and photographs; he generates their own version of it (looks only, functionally the same), shown in the custom client (its 909) |

Execution order: `919a → 919b → 919c`, with `919d` after 919a. The generator itself (describers,
projection, synthesis, climate, the Sun's photograph and bedrock) is W09's
in world-edit-to-execute; these issues are the game's side of it.

## Open Questions

1. **The Sun's dig.** "How hard is it for medieval peasants to dig into
   the earth?" Players cannot dig in WoW 3.3.5a, so the bedrock as written
   only shapes the ground (erosion stops at it). Is digging meant to be a
   game mechanic somewhere (it would need its own issue), or is the bedrock
   only for the shape?
2. **"Water and wind and current cycles and seasons"** on the Sun: the real
   Sun has none of these, and a tilt of 7.25° to the planets' plane. Does
   the Sun world get Earth-like weather on purpose (a fiction), or weather
   of its own kind (heat rising in each granule cell and falling at its
   edges, which is what the real cells are)?
3. **Which profile** carries the new worlds? They need the client to have
   the new map files (W02c's overlay folder or `patch-W.MPQ`), so every
   player of that profile must install them.
4. **Real to whom?** At real scale, should a 6-foot character stand at
   true height beside real-sized buildings (so WoW's own oversized doors
   and trees look wrong beside them), or should the ground be scaled to
   WoW's proportions, so the game's own models fit?
