# 173k - The Client in C, with Raylib

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

Not built. The client is Lua on LÖVE (`src/custom-client/`): map reader,
mover with the slope rule, navigation-tile slope reader, archive reader,
model, picture and table readers, character assembly, and a 3D draw with
two shaders. Tests: `scripts/test-custom-client` (22),
`scripts/test-client-models` (20).

## Intended Behavior

The same client in C on Raylib (an OpenGL library for games), the start
of the project's own engine: the same window, ground, night elf, controls,
speeds, slope rule, and picture mode, built by one script from
`src/custom-client-c/`. Every reader is a C module with its own test
program checking the same facts as the Lua tests, on the same files.
The Lua version stays beside it (the polyglot-source way) as the
reference the C is checked against, until the owner retires it.

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

1. When the C version matches, should the Lua version be kept as the
   reference or removed?
