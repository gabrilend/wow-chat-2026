# navmesh-tiles.lua

Reads one tile of the server's walking mesh (`data-files/mmaps/MMMXXYY.mmtile`)
into plain tables, in the game's coordinates (issue 617e12). No server needed.

| Function | Takes | Gives |
|---|---|---|
| `read(path)` | a tile file's path | `tile`, or `nil, why` |
| `tile_path(dir, map, gx, gy)` | project folder, map id, grid along x, grid along y | the tile file's path (the core's naming) |

`tile` fields:

| Field | Type | Meaning |
|---|---|---|
| `x`, `y` | integers | the tile's place in the mesh's own grid (not the file name's numbers) |
| `bmin`, `bmax` | `{x, y, z}` floats | the tile's bounds, game coordinates |
| `polys` | list | one entry per walkable polygon, below |

Each polygon:

| Field | Type | Meaning |
|---|---|---|
| `corners` | list of `{x, y, z}` floats | its corners (3 to 6), game coordinates |
| `centre` | `{x, y, z}` floats | the corners' average |
| `neis` | list of integers, one per edge | 0 no neighbour, 1.. the polygon of this tile across that edge, -1 a polygon of another tile |
| `flags` | integer | the mesh builder's flags (ground, water, ...) |
| `area` | integer | Detour's area id (0 in this project's meshes) |

Layout notes (offsets, the (y, z, x) point order, the header found by its
`DNAV` magic) are in the file's header comment.
