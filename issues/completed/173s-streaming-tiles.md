# 173s - Streaming Tiles

*Continues in the W client (`/mnt/kaun/custom-client/`), since the move on 2026-10-07 (173v): issue 303. This issue stays as the record of how the client began; its paths are as they were then.*

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173 (the custom client)
- Blocked by: 173f, 173g, 173q, 173r (everything a tile holds)
- Related: 173b6 (view distance, `farclip`)
- Priority: Medium

## Origin

The owner, 2026-10-06, asked whether the whole continent is in memory
in the original. Answered: the original streams its ground files,
loading the tiles near the player and dropping those left behind, and
keeps only a small low-detail height map (WDL) of the whole continent for
the far horizon. The owner's earlier wish (2026-10-06): "if we told it
to, could we build the entire continent?"

## Current Behavior

**Dropping and the far horizon built 2026-10-06:**
- **The horizon** (`horizon.h` / `horizon.c`):
  - The map's .wdl is read: one coarse 17 x 17 height grid per tile, with
    hole bits. Its corner at Astranaar's tile (164) matches the ground
    file's (164.69).
  - Each tile within 6 of hers that isn't loaded in full is drawn as a
    coarse mesh in the fog's colour, a little darker on slopes facing
    away from the sun.
  - The far plane now reaches the horizon (7 tiles out).
  - At the Crossroads the far mountains stand as blue-grey silhouettes.
  - The reader is `adt_wdl_read` (`adt.c`, no window needed). Test: the
    low-detail map covers 988 of Kalimdor's tiles, and its corner at
    Astranaar's tile agrees with the full ground within 1.5 yards.

- **What drops:** `refresh_tiles` (`main.c`) drops every tile more than
  one tile beyond the loaded 3 x 3. Each part forgets what the tile
  brought:
  - `ground_drop_tile`: meshes and blend pictures.
  - `water_drop_tile` and `liquid_drop_tile`: drawn and asked-about water.
  - `collide_drop_tile`: its solid triangles; the grid is filed afresh.
  - `doodads_drop_tile`: its copies, their particle runs and own meshes.
- **Placements:** each tile keeps its own placement list; a placement is
  realised by the first tile that meets it. After a drop, the remaining
  tiles realise again, so a doodad two tiles share stays while either
  is loaded.
- **Kept:** models, pictures and liquid pictures stay loaded once read.
- **A fault found on the way and fixed:** after a drop, copies with no
  own meshes yet slid into slots whose meshes had moved, so two copies
  shared one buffer and one freed it under the other. The address-checked
  build found it. Now only the leading run of copies that has meshes (and
  particle runs) is counted.
- **Picture option:** `--goto X Y` moves her one world-second in. Moving
  to (3500, -1500) loads 7 new tiles and drops the 3 left behind; the
  run is clean under the address checker.
- **`scripts/build-custom-client --asan`** builds the address-checked
  client (with clang).
- **Tests:** 2 checks. Dropping a tile forgets its triangles (only its
  own) and its water.
- **Counts stay level (step 4, 2026-10-07):** a jump far enough that
  every tile round Astranaar is dropped (`--goto -2000 -2000`) ends with
  the same 2,889 copies and 114,421 solid triangles as starting there
  afresh (`--map 1 -2000 -2000`): what dropped tiles brought is all
  gone. A plain long walk was tried first, but she runs into walls in
  Astranaar and stops on the Barrens' hills, so it crosses too few
  tiles to show it.

## Intended Behavior

- **Dropping tiles:** tiles more than one tile beyond the loaded square
  are dropped, with everything they brought:
  - ground meshes and blend pictures;
  - doodad and building copies;
  - solid triangles;
  - water.
  The one-tile margin means walking back and forth across an edge doesn't
  load and drop the same tile over and over.
- **Kept:** models, pictures and other shared things stay loaded once
  read (a cache), so returning is quick.
- **Placements:** a doodad listed by two tiles belongs to the first that
  loaded it. If that tile is dropped while the other stays, the other
  tile places it again.
- **The far horizon:** the WDL's low-detail heights drawn beyond the
  loaded tiles, as the original draws distant mountains.

## Suggested Implementation Steps

1. Each loaded thing remembers its tile.
2. Dropping, per part: ground, doodads, collision, water.
3. Tests (no window): collision and water forget a dropped tile.
4. A long walk: counts stay level.
5. The WDL horizon.

## Open Questions

None yet.

## Since then (checked 2026-10-17)

The custom client moved to its own project on 2026-10-07 (173v), the W
client at `/mnt/kaun/custom-client/`, and is built,
run and tested there (`scripts/build --test`; its own CLAUDE.md). Its code
was renumbered into reading order (`src/NNN-name.c`) and rewritten to its
error and handle conventions; `src/custom-client-c/` and `src/custom-client/`
here are gone. The crosswalk from every 173 issue to where it continues is
the table in the W client's `docs/009-roadmap.md`. This piece continues as
W client issue 303 (WDT and streaming), on 301's tile reader (`src/020-adt.c`).
