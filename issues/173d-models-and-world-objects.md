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

**Finding (2026-10-06, 173j): CharSections names pictures the archives
lack.** For a tauren man (race 6, sex 0, all choices 0), the scalp layer
names `Character\Tauren\ScalpUpperHair00_00.blp`, and the hair section's
first picture is `Character\Tauren\TaurenMaleFaceLower04_18.blp`, a
face's name in the hair's row. Neither is in any archive. `character.c`
now leaves such a layer unpainted and reports it. Open: whether the hair
row is read right for races other than the night elf (the column layout
was checked only on her), or whether the original also lacks these.
The owner (2026-10-06): in the original "the tauren looks mostly fine but
he's missing his tail". So the tail is a piece (geoset) `character.c`
doesn't switch on, separate from the pictures. His pieces, listed
(2026-10-06): 0-73, 102-109, 202-208, 302-309, 401-404, 505, 701, 702,
802, 803, 903, 1002, 1102, 1104, 1202, 1301, 1302, 1501-1506, 1703, 1802.
`character.c` shows the body (0), the hair style's piece and the fixed
"bare" set 401, 501, 702, 1301 and 1501 (and, later, 1702), which was checked only on the
night elf. He has no 501 (his feet are 505), and his facial-hair groups 1
to 3 start at variant 2. The fix belongs here: choose each group's piece
by the game's own tables (CharacterFacialHairStyles for groups 1-3, the
race's defaults for the rest) rather than by fixed numbers, then check the
tail and hooves against the original.

**The tail found and fixed (2026-10-06).** It isn't a piece left off.
- **Where it is:** his tail is piece 1501 (group 15, "no cape": the
  bare back). Measured, it sits half a yard behind him at waist height.
  `character.c` already shows 1501.
- **The cause:** the tail is drawn with picture slot kind 8, the fur:
  the skin row's second picture in CharSections. The figure filled only
  kinds 1 (skin) and 6 (hair), so every piece using the fur was skipped:
  the tail, and parts of his coat and face.
- **The fix:** `character.c` now loads the fur (`Character.fur`),
  reporting it by name if its file is missing, and `figure.c` fills kind
  8 with it.
- **Seen:** from behind, he has his tail and coat.
- **Test:** a tauren man's tail shows, painted with his fur.

**Glowing and see-through pieces on figures (2026-10-06).**
- **The eye glow:** a night elf's glowing eyes are piece 1702 (group 17:
  1701 none, 1702 the race's glow, 1703 a death knight's), drawn as
  added light with a picture named inside the model. `character.c` now
  shows 1702 among the bare pieces (a model without it, as the tauren's,
  shows none), and `figure.c` loads pictures named inside a character's
  model (kind 0), which it never did, so the glow had no picture.
- **Drawing by blend:** `figure_draw` now draws as the doodads do: solid
  and cut-out pieces first, writing depth; then see-through and
  added-light pieces without writing depth, each tinted by its animated
  colour and opacity (`anim_unit_tint`, now in `anim.c` and shared with
  the doodads), unlit pieces skipping the sun, added light fading to
  nothing in fog. Before, every piece was drawn solid.
- **Seen:** her eyes glow white-blue, as night elves' do.
- **Tests:** 1702 shows and 1703 doesn't; the glow is added light with
  its own picture in the archives; its tint is visible while she stands.
- **Not yet for figures:** two-picture pieces and moving picture
  positions (none of the figures shown today has either: a one-off
  probe listed every unit of the five models, 2026-10-06).

**Bare pieces from the game's tables (built 2026-10-06; Open Questions,
3).** `character.c`'s fixed list (401, 501, 702, 1301, 1501, 1702) is
gone. A bare character now shows, per piece group:
- **Groups 1, 3, 2 and 17** from CharacterFacialHairStyles.dbc, by race,
  sex and the new facial-hair choice (`CharacterLook.facial_hair`). Its
  columns (no id): race, sex, choice, then five variants. Their order
  (groups 1, 3, 2, 16, 17) was measured: over every playable race and
  sex, 185 variants name pieces the model has under 1, 3, 2, against 127
  under 1, 2, 3; the fifth always names a group-17 piece (the eye glow:
  a night-elf woman's 1702 comes from here now, not from a hand-written
  number); the fourth is always 0.
- **Group 0 below 100:** the hair style (CharHairGeosets), as before.
- **Group 7, the ears:** variant 2 (no table names it; 701 is earless).
- **Every other group:** variant 1, its bare shape, where the model has
  it. Items change these (173p).
- A facial-hair choice missing from the table is refused by name.
- The tauren bystander now wears facial-hair choice 1 (a beard).
- **Tests:** a tauren man's choice 0 shows no beard pieces, choice 1
  shows 102, 302 and 202, he has no eye glow; an unknown choice is
  refused. (Some piece ids are two meshes, one drawn with fur and one
  with skin, so pieces are counted by id.)

Group 5 for him has only 505 (no 501), so his feet show the body's own
hooves; whether the original shows 505 bare is to check in-game.
The two missing pictures (scalp, and a hair row naming a face) are
still reported.

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
2. (Answered 2026-10-05) Where looks live: "The looks can be stored on
   the client and loaded by the server by model ID and such - the reason
   is, when we implement custom assets, users should be able to supply
   whatever assets they'd like, and another player would see them with
   their own assets." So the server sends only ids (display id, race,
   sex, the creation choices, item display ids), and each client turns
   ids into models and pictures from its own asset store: the original
   archives first, a player's own assets over them. Two players may see
   the same character differently, each with their own assets. Her look
   in `main.lua` is a stand-in for the ids the server will send.
3. (Answered 2026-10-06) Which pieces a bare character shows: a fixed
   list of piece numbers (typed in from the night elf), or the game's
   own tables? The owner: "Yes? How else would we do it?" So the tables:
   facial hair from CharacterFacialHairStyles.dbc (groups 1-3, by race,
   sex and style), hair from CharHairGeosets.dbc (already), and every
   other group its bare variant (g * 100 + 1) where the model has it, the
   fixed list retired.
