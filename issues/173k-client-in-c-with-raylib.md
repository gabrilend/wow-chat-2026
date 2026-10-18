# 173k - The Client in C, with Raylib

*Continues in the W client (`/mnt/mtwo/games/azeroth-core/custom-client/`), since the move on 2026-10-07 (173v): issue 101. This issue stays as the record of how the client began; its paths are as they were then.*

## Status
- Created: 2026-10-05
- Phase: 1
- Parent: 173 (the custom client)
- Blocks: 173f, 173g, 173h, 173i, 173j, 617r5
- Priority: High (owner, 2026-10-05: "yeah let's port now")

## Origin

Verbatim, 2026-10-05:

> we need to transition it to C with Raylib. [...] yeah let's port now. We
> should build something like an engine in C anyway, for performance
> reasons.

## Current Behavior

**Ported 2026-10-05.** `src/custom-client-c/`: `maps`, `navmesh_slope`,
`mover`, `mpq`, `blp`, `dbc`, `m2`, `character` (each a `.h` saying what
it is and a `.c` ported line for line from its Lua twin) and `main.c`
(Raylib window, camera, controls, ground meshes, her model in pieces with
their textures, two GLSL 330 shaders, the `--shot`, `--zoom`, `--front`
picture options). Raylib 5.1-dev from `/usr/local` (installed static),
zlib from the system. `scripts/build-custom-client [--test]` (now `scripts/build` in the W client project, `../custom-client/`) builds both
programs into `tmp/tmp/custom-client-c/` with `-Wall -Wextra -Werror`.
`tests/test_client.c` holds the C to the Lua tests' facts on the same
files: 43 checks, every number equal to the Lua's (Astranaar 106.71,
8.4 yards a second, the 60-degree rule, her 2.29 yards and 5148
triangles, 393 face samples changed). Pictures from both versions match.
`scripts/custom-client` (now `scripts/run` in the W client project, `../custom-client/`) now runs the C version (rebuilt when its sources
are newer), `--lua` the original.

Differences from the Lua: the mover keeps doubles as LuaJIT does; the
projection is loaded by hand (this Raylib has no clip-plane setter; far
1600 yards as before); the window size follows the window manager.

## Intended Behavior

The same client in C on Raylib (an OpenGL library for games), the start
of the project's own engine: the same window, ground, night elf, controls,
speeds, slope rule, and picture mode, built by one script from
`src/custom-client-c/`. Every reader is a C module with its own test
program checking the same facts as the Lua tests, on the same files.
**The Lua version is deprecated** (owner, 2026-10-06: "We should
deprecate the lua client and possibly remove it if we have the engine
fully built in C"). All new work is in C only: the settings store and the
camera have no Lua twins. The Lua version stays runnable (`--lua`) as it
stood on 2026-10-06, and is removed once the C engine is fully built.
Before removing it, two things that depend on it must move:
- `scripts/generate-stock-options-catalog` reads the client's archives
  with the Lua archive reader (`src/custom-client/lib/mpq.lua`; the Lua version was removed when the client moved, and its C counterpart is `src/015-mpq.c` in the W client project, `../custom-client/`). Either
  that reader is kept as a tool library, or the generator is rewritten to
  use the C reader.
- `scripts/test-custom-client` (the Lua tests). Its facts are already held
  by the C tests.

- Raylib from `libs/` if present, otherwise fetched once into `libs/`
  and built there (a static library), so the client builds the same on
  any machine.
- zlib for the archives (the system's).
- The test programs compare against numbers the Lua tests already hold
  (Astranaar 106.71 yards; 8.4 yards a second; the archives' keys; her
  2.29-yard height; 581-row facts are server side and not here).

## Suggested Implementation Steps

1. Build script (`scripts/build-custom-client`), Raylib and zlib found or
   fetched.
2. Port the readers one by one, each with its test: maps, navigation
   slope, mover, archives, pictures, tables, models, character.
3. The window: camera, controls, ground mesh, her model, shaders, the
   `--shot` picture mode.
4. Pictures from both versions side by side; switch the run script to C.

## Open Questions

None. (Answered 2026-10-06: deprecated now, removed when the engine is
fully built in C.)
