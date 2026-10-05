# 173d - Models and World Objects

## Status
- Created: 2026-10-04
- Phase: 1
- Parent: 173 (the custom client)
- Blocked by: 173a
- Priority: Medium

## Origin

See 173 (the owner's words, 2026-10-04).

## Current Behavior

Not built.

## Intended Behavior

The world's buildings and trees and the characters' models drawn in 3D:
the server's collision meshes (`data-files/vmaps`) for buildings and
large objects at first (the shapes the server uses for line of sight),
then the game's own models from the client's data files (MPQ archives:
M2 for characters and doodads, WMO for buildings) with their textures.

## Suggested Implementation Steps

1. Read the server's vmap tiles and draw them with the ground.
2. Read MPQ archives (a library), M2 and WMO models, textures.
3. The night elf's own model in place of the stand-in.

## Open Questions

1. The client's data files: read from the installed game's Data folder, or extracted once into the project?
