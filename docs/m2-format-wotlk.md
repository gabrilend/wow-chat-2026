# The Game's Model Files: M2 and .skin (WotLK, version 264)

How the 3.3.5 client's model files are laid out, as far as the Feldowinn
pipeline needs them (issue 506h). Written from three sources, in this order
of trust:

1. **The client's own files, measured.** A stock helm
   (`Helm_Plate_D_01_HuM`), shoulder (`LShoulder_Plate_A_01`) and
   two-handed sword (`Sword_2H_AhnQiraj_D_01`) from `common-2.MPQ`, dumped
   record by record (`scripts/extract-m2-references` copies them out;
   `scripts/test-model-formats` holds our reader and writer to them).
2. **The server's model extractor**, which reads the same header
   (`source-beta/src/tools/vmap4_extractor/modelheaders.h`).
3. **Public format notes** kept by the modding community, used only to
   name fields the first two don't explain, and described here in our own
   words (the rubric strategem: others' readers give the rules, we write
   our own code).

The code that follows this document: `src/tools/model/m2.lua` (reader and
static writer; its record layouts are asserted against the sizes below at
load).

## The two files

- `NAME.m2`: the model: its name, vertices, bones, animation sequences,
  textures, materials and a set of small lookup tables.
- `NAME00.skin` (and `01`..`03` for lower detail levels): how the model's
  vertices are cut into triangles and draw calls ("batches"). WotLK moved
  this out of the `.m2` (older versions kept it inside, counted as "views";
  the header still says how many skins there are).
- Animations whose sequence lacks flag 0x20 keep their keyframes in
  separate `NAME####-##.anim` files; everything the item models use is
  inline (flag 0x20), and the static writer only writes inline.

Every number is little-endian. An **array** is 8 bytes: a count and an
offset from the start of the file. In the stock files every block starts on
a 16-byte boundary and the file's length is a multiple of 16.

## The header (304 bytes)

| Offset | Field | Notes |
|---|---|---|
| 0 | magic `MD20`, version 264 | |
| 8 | name (array of chars, with its closing zero) | stock: the name block sits right after the header, at 304 |
| 16 | global flags | 0 for items |
| 20 | global sequences | looping timers some tracks follow |
| 28 | sequences (64 bytes each) | the animations |
| 36 | sequence lookup (int16) | animation id -> sequence index |
| 44 | bones (88 bytes each) | |
| 52 | key bone lookup (int16) | named bones (arms, head...) -> bone; items: one entry, -1 |
| 60 | vertices (48 bytes each) | |
| 68 | skin count (one number, not an array) | 1 for items |
| 72 | colors | |
| 80 | textures (16 bytes each) | |
| 88 | transparency tracks (20 bytes each) | |
| 96 | texture animations | |
| 104 | texture replace lookup (int16) | replaceable texture kind -> texture |
| 112 | materials (4 bytes each) | render flags and blending |
| 120 | bone lookup (int16) | the bones a skin section uses |
| 128 | texture lookup (int16) | |
| 136 | texture unit lookup (int16) | which texture coordinates a batch uses |
| 144 | transparency lookup (int16) | |
| 152 | texture animation lookup (int16) | -1: none |
| 160 | bounding box min (3 floats), max (3), radius | holds every vertex |
| 188 | collision box min, max, radius | items: all zero |
| 216 | collision triangles, vertices, normals | items: none |
| 240 | attachments, attachment lookup | where things attach (weapons in hands, effects) |
| 256 | events | sounds and effects fired by animations |
| 264 | lights, cameras, camera lookup | |
| 288 | ribbon emitters, particle emitters | |

## The records

**Vertex, 48 bytes**: position (3 floats); four bone weights (bytes,
summing to 255); four bone indices (bytes, into the skin section's bones);
normal (3 floats); two texture coordinates (2 floats each; the second
unused by items). Measured: 58 helm vertices exactly fill the 2,784 bytes
between the vertex block and the texture block.

**Sequence (animation), 64 bytes**: animation id (the game's animation
table, `AnimationData.dbc`: 0 is "Stand"), variation; duration (ms); move
speed; flags (0x20: keyframes inline, not in an `.anim` file); frequency
(how often this variation plays, out of 32767); a replay range; blend time
(ms); its own bounding box and radius; the next variation's index (-1:
none); an alias. Stock items: one sequence, id 0, flags 0x20, frequency
32767, blend 150.

**Bone, 88 bytes**: key bone id (-1: not a named bone); flags; parent
(-1: the root); a submesh id; two small numbers; three **tracks**
(translation, rotation, scale); the pivot point (3 floats). Stock items:
one bone, root, no keyframes, pivot near the piece's middle.

**Track, 20 bytes**: interpolation (0 none, 1 linear, 2 and 3 curves);
global sequence (-1: follows the animation); timestamps (an array of
arrays: one list per sequence); values (the same shape). This per-sequence
nesting is WotLK's: each animation's keys are their own list. Stock item
transparency: one track, one sequence, one key at time 0, value 32767 (fully
opaque, a fixed-point 1.0).

**Texture, 16 bytes**: kind; flags; file name (array of chars). Kind 0 is a
file named here; kind 2 is "the item's own texture", supplied by the item's
display record, so stock items leave the file name empty (one zero byte).

**Material, 4 bytes**: flags (0x4: both faces drawn, as stock helms have),
blending mode (0: opaque).

## The .skin file

| Offset | Field | Notes |
|---|---|---|
| 0 | magic `SKIN` | |
| 4 | vertex lookup (uint16) | skin vertex -> model vertex |
| 12 | triangle indices (uint16) | into the vertex lookup, 3 per triangle |
| 20 | vertex bones (4 bytes each) | per skin vertex, its bones in the section's bone list |
| 28 | submeshes (48 bytes each) | ranges of vertices and indices |
| 36 | batches (24 bytes each) | the draw calls |
| 44 | most bones in one draw (uint32) | stock items: 21 |

**Submesh, 48 bytes**: a part id (the character model's geoset numbers:
which piece of a body it is), a level; first vertex, vertex count, first
index, index count (all 16-bit: at most 65,535 each, which is why a
generated mesh must be reduced first); bone count and the first entry in
the bone lookup; bone influences; the centre bone; the centre (3 floats);
a sort centre (3 floats) and radius.

**Batch, 24 bytes**: flags (stock items 16); priority plane; shader; which
submesh; which geoset; color (-1: none); material; material layer; texture
count; first texture lookup entry; texture-coordinate lookup entry;
transparency lookup entry; texture animation lookup entry.

## What an item model needs, measured

A stock helm or shoulder, and so our static writer (`M2.write_static`):
one root bone with no keyframes; one "Stand" sequence, inline; one texture
of kind 2; one transparency track fully opaque; texture replace lookup
`-1, -1, 0`; key bone lookup `-1`; texture, texture unit and transparency
lookups `0`; texture animation lookup `-1`; one material; a skin with the
identity vertex lookup, every vertex on bone 0 with weight 255, one
submesh, one batch. The sword differs: 8 bones, 2 submeshes, 3 batches
(glow and moving parts), which the reader handles and the static writer
doesn't make.

## What the stock client needs beyond the files

Which model an item shows, and its texture, come from the client's item
display data (`ItemDisplayInfo.dbc`), which the server can't change for
the player: a new model is seen in game only once the client's data names
it. The project makes no client changes until its own client exists, and
building the pipeline is part of building that client (owner,
2026-09-27: "building this *is* the custom client though"). So the M2 is
the export for the stock client; the kept format is glTF (or the project's
own), see `docs/feldowinn-3d-pipeline.md`.

## Body armour is not a model

In WotLK only some gear is its own model: helms, shoulders, weapons,
shields and a few others. Chest, legs, gloves, boots, belts and wrists are
**textures painted onto the character's body** (regions of the body's
texture, chosen by the item's display data), plus a few body-mesh variants
(geosets: sleeves, robe skirts, boot tops). So Feldowinn's chest, gloves,
legs and boots in the stock client are images in the body's texture
layout, not meshes; a custom client can do otherwise.
