# 173f - Painted Ground (terrain textures)

*Continues in the W client (`/mnt/mtwo/games/azeroth-core/custom-client/`), since the move on 2026-10-07 (173v): 301, 302. This issue stays as the record of how the client began; its paths are as they were then.*

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

**Built 2026-10-06** in C. The steepness colouring is gone.
- **`adt.h` / `adt.c` read the original's ground files.** For each chunk
  they read its position, its 145 heights, its holes, its 1-4 ground
  pictures, its blend maps (all three forms: 4-bit, plain 8-bit and
  packed 8-bit), its baked shadow, and its colour tints (MCCV). They
  also read the map's WDT, which says which blend-map form the map uses.
- **`ground.h` / `ground.c` paint the ground.**
  - **Meshes:** one mesh per quarter tile (64 chunks), with the
    original's four triangles per cell, none over holes; a quarter out of
    the camera's sight isn't drawn (173u: from 2,304 draw orders a frame
    to about 6). The heights are the client's own.
  - **Pictures:** each ground picture is loaded once into a layer of one
    shared texture array (256 x 256 layers; a layer no loaded tile uses is
    freed), and repeats 8 times across a chunk. Each chunk's four layer
    numbers ride on its points.
  - **Blending:** each chunk's 64 x 64 blend picture is a square of its
    tile's 1024 x 1024 one; its alpha channel already holds the shadow,
    for 173h.
  - **The shader** lays each layer over the ones below by its strength,
    tints the result, then applies the old sun and fog.
  - **Light** comes from the server's heights a yard either side, so it
    runs on smoothly across chunk and tile edges.
- **`main.c`** keeps the archives open for the whole run and paints 3 x 3
  tiles around her. A tile that fails to read stops the client and names
  it. A tile with no ground file (open sea) is left empty.
- **Tests** (`tests/test_client.c`, 9 checks):
  - Kalimdor uses 4-bit blend maps and Northrend 8-bit.
  - Astranaar's tile reads, and all 5 of its pictures are in the archives.
  - Every chunk sits where its row and column say.
  - All 37,120 of its heights match the server's own map, within 0.002
    yards.
  - The unpainted edges of the 4-bit blend maps are filled as the
    original fills them.
  - A Northrend tile with packed blend maps reads.
- **A fault the Northrend check found:** in packed tiles, the size stored
  inside the blend-data block can be far too small (512 bytes against a
  real 3680), so the reader takes the size from the chunk header instead.

**Left:** the side-by-side picture against the original client at the
same spot (step 4), which needs the owner's original client running.

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
