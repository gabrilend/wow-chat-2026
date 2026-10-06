# The Custom Client's Data Path

How data flows through the custom client (issue 173), from the original
3.3.5a client's files to the picture on screen and the steps she takes.
Everything in the world is read from the original's own files. Nothing
is placed by hand. The code is in `src/custom-client-c/`. Each file's
header comment says what it holds and lays out its formats.

For what is built and what is left, read the issues (173 and its
sub-issues). For what the client guesses and the owner checks against the
original, read `docs/custom-client-ingame-checks.md`. For current numbers
(checks, counts), run `scripts/build-custom-client --test` and the
picture options; this page doesn't copy numbers that go stale.

## 1. Sources

| Source | Read by | Holds |
|---|---|---|
| The original client's archives (`Data/*.MPQ`, newest patch first) | `mpq.c` | every file below, unpacked on request |
| The server's map files (`data-files/maps`) | `maps.c` | the ground's heights the server uses (for the mover) |
| The server's navigation tiles (`data-files/mmaps`) | `navmesh_slope.c` | the steepest walkable slope |
| The player's settings file (`src/custom-client-c/settings/Config.wtf`) | `settings.c` | the player's choices (`SET name "value"`) |

## 2. From the archives to things in memory (no window needed)

| Reader | From | To |
|---|---|---|
| `dbc.c` | the client's tables (`DBFilesClient\*.dbc`) | rows and fields (Map, Light*, LiquidType, CharSections, ItemDisplayInfo, CreatureDisplayInfo ...) |
| `blp.c` | pictures (`.blp`) | RGBA images |
| `adt.c` | ground files (`World\Maps\<map>\<map>_<ty>_<tx>.adt`) | chunks (heights, layers, blend maps, shadows, tints), water layers, placements of doodads and buildings |
| `m2.c` | models (`.m2` + `00.skin`) | points, pieces, units (pictures, layers, blends, tints), solid shapes |
| `anim.c` | the same models (and `.anim` files) | skeletons, animations, poses, bent points, picture animations |
| `particles.c` | the same models | particle emitters, and their particles run over time |
| `wmo.c` | buildings (root + group files) | materials, furniture sets, parts' points and batches, solid flags |
| `character.c` | a character's look (race, sex, choices, items) | its model with the right pieces shown, its painted skin sheet, fur, hair, cloak, and the items to hang |
| `light.c` | the light tables | the light here and now: sun, shade, sky, fog, water colours, skybox |
| `liquid.c` | ground files' water | the water's surface anywhere (for the mover) |
| `collide.c` | models' and buildings' solid shapes, placed | floors, walls and lines of sight (for the mover and camera) |

## 3. From memory to the screen (Raylib)

Each frame, in this order (`main.c`):

1. **Tiles** (`refresh_tiles`): tiles round her are loaded. Each tile's
   ground file is read once and handed to:
   - `ground.c`: meshes, blend pictures;
   - `water.c` and `liquid.c`;
   - `doodads.c`: copies, solid shapes into `collide.c`.
   Tiles left behind are dropped from all of them (173s).
2. **Input and movement:**
   - the mouse drags the camera and the wheel zooms it, all the way in
     to first person (`camera.c`);
   - the keys and the world move her (`mover.c`, asking `main.c`'s
     ground, wall and water questions);
   - the camera follows (`camera.c`); in first person it sits at her
     eyes, lifted by Head Bob, and she isn't drawn.
3. **Animation:**
   - `moves.c` chooses her animation from what she did, and `figure.c`
     bends her and hangs her items;
   - the bystanders cycle theirs;
   - `doodads.c` bends moving doodads, poses camera-facing ones per copy,
     and runs particles near the camera.
4. **Light:** `light.c` gives the light at her place and hour. View
   distance and being underwater adjust the fog. Every shader is handed
   the light (`sky_light_shader`).
5. **Drawing**, back to front:
   - the sky dome and skybox (`sky.c`, `doodads_draw_skybox`);
   - the painted ground with its shadows (`ground.c`);
   - her and the figures (`figure.c`): solid pieces, then glowing and
     see-through ones (her eyes' glow) over them, each tinted by its
     animated colour (`anim.c`);
   - doodads and buildings: solid, then see-through, then particles,
     which fade into the fog by distance (`doodads.c`, `particles.c`);
   - water, see-through (`water.c`).

## 4. The mover's questions

The mover (`mover.c`) only asks. `main.c` answers from the readers:
- **Ground:** the higher of the server's ground and a model's floor, at
  or below her feet plus a step (`maps.c` + `collide.c`).
- **Walls:** a step that hits something too steep to stand on
  (`collide.c`).
- **Water:** the surface above her (`liquid.c`). Deep enough, she swims.

## 5. Checking

- `scripts/build-custom-client --test` builds the client and the test
  program (no window) and runs every check against the original's files.
- `--asan` adds an address-checked client for hunting memory faults.
- Picture mode (`scripts/custom-client --shot ...`) runs the world a few
  seconds and saves a picture; its options (place, time, camera, walk,
  dive, clothes, map) are listed in `scripts/custom-client`.
