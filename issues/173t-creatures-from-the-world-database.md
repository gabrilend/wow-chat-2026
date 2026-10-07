# 173t - Creatures from the World Database

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173 (the custom client)
- Blocked by: 173j (figures), 173p (dressed characters), 173s (tiles come and go)
- Related: 173e (what the server checks), 173l (the network: this is its
  stand-in)
- Priority: Medium

## Origin

The owner, 2026-10-06, choosing from the list of next steps: "Real
creatures before the network: read Ashenvale's creatures and townsfolk
from the server's database and stand them in place, so the world is
populated." ("yep")

## Current Behavior

**Built 2026-10-06** (in progress: one open question, below).
- **The list** (`scripts/generate-custom-client-creatures`, LuaJIT): one
  map's spawns from a world database (default: the active profile's,
  named by the project's rule; `--db`, `--map`), through
  `scripts/mysql-client`, into `src/custom-client-c/world/creatures-<map>.tsv`
  (git-ignored). Left out: holiday spawns (`game_event_creature`, a
  positive event), triggers (`flags_extra` & 128), spirit healers and
  guides (`npcflag` & 0xC000), creatures with no model. The display is
  chosen among the creature's by their probabilities, the guid as the
  dice. Kalimdor from `acore_world_basic`: 27,453 spawns; 56 round
  Astranaar (11 sentinels, the innkeeper, trainers, vendors, deer,
  stalkers, fish). (An earlier count of "44 sentinels" was a query
  joining each spawn to its four displays: there are 11.)
- **The reader** (`creatures.h` / `creatures.c`, no Raylib): reads the
  list, files spawns by map tile (sorted, found by halving); a line that
  can't be read stops it, naming the line; no list is said, with how to
  make one, and the client runs without creatures.
- **Townsfolk** (`figure.c`): a display naming a CreatureDisplayInfoExtra
  row is built as a character (race, sex, skin, face, hair, facial hair,
  eleven item looks worn), wearing the row's baked skin sheet
  (`Textures\BakedNpcTextures\`) instead of a painted one. Seen: a
  sentinel in purple leather with blue hair beside the inn.
- **A creature's facial-hair choice beyond the table** (a sentinel's 10;
  a night-elf woman's rows stop at 9) takes the race's choice-0 pieces,
  said once as a FALLBACK (`character.c`, `CharacterLook.npc`). A
  player's look with such a choice is still refused.
- **In the world** (`main.c`): each loaded tile brings its spawns in as
  figures (`--world DIR`, passed by `scripts/custom-client`); dropped
  tiles take theirs away. Each stands where the list says, facing its
  way, playing its standing animation from its own moment, with a ground
  shadow.
- **Seen within 100 yards** (`CREATURE_SEEN_REACH`): the server tells a
  client only of creatures within its visibility distance (this server's
  `Visibility.Distance.Continents` is 100; AzerothCore's default 90), so
  the original never draws one farther; nor are creatures wholly behind
  the camera drawn. Only those within it are posed.
- **Cost, measured** (picture reports now print it): at Astranaar's
  start, 27 posed, 14 drawn, of 467 standing: about 5 ms a frame, of
  which bending each model point on the processor is about 2.3 ms,
  sending the bent points to the graphics card about 0.9, the bones'
  poses about 1.1, drawing about 0.75. Bending on the graphics card
  (skinning in the shader) would remove the first two; not built.
- **Sharing:** pictures read from the archives are kept in one cache
  (`figure.c`), and the archive reader remembers files it has unpacked
  (`mpq.c`, up to 256 MB, the one read longest ago forgotten first):
  building 467 creatures went from 12.7 to 1.3 seconds. Painted skins
  belong to their figure and are freed with it (before, no figure's
  pictures were ever freed).
- **Picture reports** now name the five creatures nearest her, and the
  average frame time.
- **Tests:** the list reader (spawns by tile, a bad line, no list); a
  sentinel's display is a dressed night-elf woman with her baked skin in
  the archives; the facial-hair fallback for a creature and the refusal
  for a player; the archive memory serves a second read, same bytes.

**Left:**
- Weapons and shields (`creature_equip_template`), and whether they are
  held or sheathed.
- Sitting, kneeling and emotes (`creature_addon`), walking routes and
  wandering: with the network, or later here.
- Ground height: each stands at the database's height, not the ground's.

## Open Questions

1. A townsperson whose facial-hair choice lies beyond the table (eleven
   sentinels: choice 10) is drawn with the race's choice-0 pieces. What
   does the original show for them? (Check list 13.)

## Intended Behavior

- **Generating** (a script, separate from the client): the creatures of
  one map are read from a world database and written to a plain file the
  client reads: one line a spawn with its id, the creature's number and
  name, the display to draw (chosen among the creature's displays by
  their probabilities, the same choice for the same spawn every time),
  its size, position and facing. The left-out kinds above are left out.
  The database defaults to the active server profile's world database
  (the spawns the server would send); any other can be named. The file
  is generated, not hand-edited, and not committed (each server's
  differs).
- **Showing** (the client): each loaded tile's spawns stand where the
  file puts them, facing where it says, each drawn with its display:
  - a creature display as today's bystanders are (173j);
  - a humanoid display as a character (173d, 173p) with the extra row's
    race, sex, choices and clothes, its skin the baked picture.
  Spawns come and go with their tile (173s), and the display's model and
  pictures are read once and shared by every spawn using it.
- **Moving:** they stand and play their standing animation, each from
  its own moment (not in step). Walking routes, wandering, sitting and
  emotes come with the network (the server moves them) or later here.
- **Without the file** the client says so and runs without creatures:
  this is a stand-in for the network, which will send the same things.

## Suggested Implementation Steps

1. `scripts/generate-custom-client-creatures`: queries `creature`,
   `creature_template`, `creature_template_model`, `game_event_creature`
   through the project's MySQL client; writes
   `src/custom-client-c/world/creatures-<map>.tsv` (git-ignored).
2. `creatures.h` / `creatures.c` (no Raylib): reads the file into a list
   of spawns, and answers "which spawns lie in tile (tx, ty)?". Tested
   against a small written file.
3. `figure.c`: `figure_from_display` builds a humanoid display as a
   character: CreatureDisplayInfo field 4 names the CreatureDisplayInfoExtra
   row (1 id, 2 race, 3 sex, 4 skin, 5 face, 6 hair style, 7 hair colour,
   8 facial hair, 9-19 the item looks worn: head, shoulders, shirt,
   chest, waist, legs, feet, wrists, hands, tabard, back; 20 flags, 21
   the baked picture's name, in `Textures\BakedNpcTextures\`), the baked
   picture replacing the painted skin sheet.
4. `main.c`: tiles loaded bring their spawns' figures; dropped tiles free
   them. One figure per spawn (each bends on its own), standing
   animation with a per-spawn starting moment.
5. Tests: the file reader, a humanoid display built as a character with
   its baked skin, and the left-out kinds absent from a generated file.
6. Picture: Astranaar with its sentinels and townsfolk.

## Related Documents
- `docs/custom-client-datapath.md` (a new source: the generated
  creature file)
- `docs/custom-client-ingame-checks.md`
