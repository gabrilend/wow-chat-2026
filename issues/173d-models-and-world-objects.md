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

**Her own model, 2026-10-05.** The stand-in box is gone: the night elf is
the game's own model, read in place from the original 3.3.5a client's
archives (`scripts/custom-client` passes its Data folder; `CLIENT=` sets
another). Pure LuaJIT, each piece testable without a window:

- `lib/mpq.lua`: the archives. Opens the client's 13 archives in the
  game's search order (newest patch first), unscrambles their index and
  block lists, and unpacks files (zlib, sector by sector, with the
  file-key scrambling). Other compressions raise an error naming the file.
  Opening all 13 takes about 4 seconds (the index unscrambling, in Lua).
- `lib/m2.lua`: a model (version 264) and its first .skin: points
  (position, facing, texture position), triangles, pieces with their
  group-and-variant ids, and which picture each piece uses.
- `lib/blp.lua`: pictures (BLP2): palette, DXT1/3/5 and plain, decoded to
  RGBA bytes.
- `lib/dbc.lua`: the client's tables.
- `lib/character.lua`: one character from its creation choices: the hair
  style's piece from CharHairGeosets, everything else bare (body, bare
  hands and feet, ears, bare legs, back without cape); the skin sheet
  painted from CharSections: skin, then face lower and upper, scalp,
  underwear, laid onto the 3.3.5a client's built-in patch positions
  (doubled for a 512-pixel sheet). Hair gets its own picture.
- `main.lua` draws each shown piece with its picture (a textured shader
  that cuts out see-through pixels, so hair strands show). She stands in
  the model's resting pose.
- `scripts/test-client-models` (20 checks, on the real archives): the
  format's published keys, the patch order, her height (2.29 yards), the
  triangles, the decoded pictures, the pieces shown and hidden, the face
  painted onto the sheet. `scripts/custom-client --shot --zoom 3.5
  --front` takes a picture of her face.

Not yet: animation (her bones; she doesn't walk or run, she glides), the
eye glow, buildings and trees (the server's collision shapes, then the
game's own WMO and M2 doodads), the ground's own textures.

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
   (Chosen for now, 2026-10-05: read in place, nothing copied, so the
   project holds none of the game's files. Is that right, or should a
   copy live with the project?)
2. Her look is fixed in `main.lua` (skin 0, face 0, hair style 0, hair
   colour 0). Should it come from a character on the server, once the
   client logs in, or be chosen in the client?
