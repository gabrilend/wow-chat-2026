# 173f - Painted Ground (terrain textures)

## Status
- Created: 2026-10-05
- Phase: 1
- Parent: 173 (the custom client)
- Blocked by: 173d (archives and pictures read)
- Priority: High (first of the owner's next five, 2026-10-05)

## Origin

Verbatim, 2026-10-05:

> We should figure out how to paint textures next. Then, let's render
> doodads. Then, let's apply the shadowmaps. Then, we should do Night Elf
> animation, then summon a couple arbitrary models that just stand around
> and do various animations.

## Current Behavior

Not built. The ground is coloured by steepness (forest green to rock
grey) from the server's height grids; the original client paints it
instead.

## Intended Behavior

The ground looks as the original client paints it: each map tile's own
ground file in the archives (`World\Maps\<map>\<map>_<x>_<y>.adt`) lists
up to four textures per 33-yard chunk and an alpha map for each layer
above the first; the client blends them. The custom client reads the
same files and blends the same way, so Ashenvale's grass, dirt paths and
rock sit where they do in the game. The ground's shape stays the
server's (the heights already agree).

## Suggested Implementation Steps

1. Read an ADT: its chunk list (MCNK), each chunk's texture layers
   (MCLY), its alpha maps (MCAL, both the 4-bit and 8-bit forms the
   3.3.5a client uses) and the tile's texture names (MTEX).
2. A test: Astranaar's tile reads; its layers name real textures; alpha
   maps are the right size.
3. Draw: per chunk, the base texture tiled, each layer blended by its
   alpha, in a shader; the existing lighting and fog on top.
4. A picture next to the original client's at the same spot.

## Open Questions

None yet.
