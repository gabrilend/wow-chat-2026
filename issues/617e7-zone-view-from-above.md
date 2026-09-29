# 617e7 - A Zone Seen From Above

## Status
- Created: 2026-09-28
- Phase: 6
- Parent: 617e
- Blocked by: None (a drawing tool; reads the map files and the world database)
- Priority: Medium

## Origin

Verbatim, 2026-09-28:

> now can you make a heatmap of a much larger arena, this one is meant to
> represent a zone? The buddy bots and player should quest about and visit
> town. Make sure the gif generator is hooked up to the output end of the
> mysql pulling script that finds the map for, say, The Barrens, and
> creates about 30 players spread throughout the three Horde towns.
> Crossroads, Ratchet, and Camp Taurajo. make sure their movement speed is
> tuned approximately correct, and then make the gif about 3x the size of
> the current ones (just in terms of x/y resolution size)
>
> they should be using our most advanced AI, which I think right now is
> the one that does frost bolts. The buddies shouldn't group up, but rather
> explore the area that they're in. Remember, we want to fit the entire map
> of The Barrens on one gif screen, so make it wayyyyy zoomed out and top
> down viewing. You can draw circles for each town, and let the different
> areas be a slight patchwork of lightly different colors than the
> background, which is a kind of gray. To change the patchwork, add either
> R, G, or B to the gray, making it darker and slightly in that direction.
> Try not to let like colors touch, and paint the map that way. This should
> give us the capability to watch the player dots rotate around the areas.
>
> if we need more space, we can make a dynamically zoomable widget
> interface hooked up to our data model, and see if that fixes it. Then it
> can zoom supreme commander style, where the camera magnifies what's at
> the mouse's area coordinates.
>
> the players should wander about, perhaps pick a random sub-area and
> adventure there for 30ish turns around the radial circle, then go back to
> town or go to another area, depending on if their bag slots are full (one
> bag slot for every slain enemy for demonstration purposes, 18 slots per
> character)

## Current Behavior

Built 2026-09-28; published privately at
https://claude.ai/artifact/AmRSb3HX5fschRtjg2mPNM (the live zoomable page,
with the GIF below it). Not yet a card in the roaming gallery (another
change was being rendered there; the card is to be added after).

- **Data** (`scripts/generate-barrens-data` -> `assets/barrens/barrens-data.lua`):
  the zone's ~33-yard squares from the server's map files (area label and
  ground height), the sub-areas whose parent chain in the client's area
  table reaches zone 17, the three Horde towns (their squares' middle and a
  radius from their square count), and the hostile monsters from the world
  database (`acore_world_release`, the installed world database with the
  most creatures in the zone), kept when hostile to a Horde player by the
  faction table's own rule, and not critters or service NPCs. Counts, as
  printed by the script: 13,432 squares, 36 sub-areas, 3 towns, 2,436
  monsters.
- **GIF** (`scripts/generate-barrens-gif` -> `docs/HTML/barrens/barrens-zone.gif`):
  873 x 960 (3x the gallery's height, the width from the zone's shape), one
  frame per 10 game seconds, 420 frames (70 game minutes), about 12 MB;
  frames compressed by one worker process per processor. Each place is a
  tint of the grey, darker and nudged toward red, green or blue, at two
  strengths (six tints), coloured greedily so touching places differ (four
  tints were enough). Towns ringed; worn ground warms in four steps.
- **Simulation** (the same in both): 30 players, each with 0 to 2 buddies,
  starting in the three towns. A player picks a place whose monsters are
  within 3 levels (not the zone's unnamed remainder, not the sea), walks
  there at 7 yards a second, and circles it for 30 stops with the owner's
  waypoint rule (the bearing turns a tenth of a circle, the percent out
  moves 1..20 at even odds, never under 10 yards; the edge on a bearing is
  where the place's squares end); buddies go to their player's place but
  explore it on their own. Fighting is the gallery's solo kiting,
  simplified: open from 30 yards with Frostbolt or Aimed Shot, blink or
  disengage out of melee, kite in circles near the monster's home, away
  from remembered danger; monsters 10% faster, aggro 20 yards one less per
  level, leash 120, respawn after their spawn time. A kill fills a bag slot;
  18 full sends the character to the nearest town to sell.
- **Page** (`scripts/generate-barrens-page` + `scripts/templates/barrens-zone.html`
  -> `docs/HTML/barrens-zone.html`): the data as inline JSON and the
  simulation ported to the page's script; scroll magnifies at the pointer,
  drag pans, pinch zooms; hovering names the place; "Follow someone"
  rides along with one player; speeds 10x, 30x, 90x; live counts.

Tuning found while building (recorded in the scripts' comments): monsters
walking into aggro range reached melee before any cast finished (9 casts
to 177 blinks in 7 game minutes), so characters now open from range; a
leash of 80 yards with straight-away kiting gave 1,083 resets to 432
kills in 20 game minutes, so kiting circles the monster's home and the
leash is 120 (65 resets to 1,173 kills).

## Intended Behavior

As the owner's words above: the whole zone in one view, players and
buddies questing about, visiting towns when bags fill, circling places;
a zoomable view when the dots are too small to follow.

## Suggested Implementation Steps

1. Data pull (done). 2. The GIF (done). 3. The zoomable page (done).
4. Add a card for it to the roaming gallery (`docs/HTML/buddy-roaming.html`)
   once the gallery's generator is free.

## Open Questions

- The page's random numbers are not the GIF's (JavaScript can't hold the
  Lua generator's products exactly), so the live run differs from the
  recorded one in its details. Acceptable?
- Monsters are drawn from `acore_world_release`; basic's own world
  database isn't installed yet. Re-pull from it when it is?
- Buddies follow their player's choice of place and each keep their own
  bags; should a buddy with full bags leave the place without its player?

## Related Issues

- **617e** parent; **617e5** (the kiting it draws); **617e6** (painting)
