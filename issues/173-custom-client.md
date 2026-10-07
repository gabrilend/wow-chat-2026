# 173 - The Custom Client

## Status
- Created: 2026-10-04
- Phase: 1
- Priority: High (owner, 2026-10-04: "god... custom client is such a
  priority")
- Related: 155y (the map addon), 719 (true tooltips), 916o (LLM compute
  on players' machines), 617s7 (box select)

## Origin

Verbatim, 2026-10-04:

> can we work on that until it's done? I'm thinking something as simple as
> a game character able to move about the world exactly as the server
> expects. Same control scheme, no UI for now. q to quit.
>
> specifically, a night-elf in ashenvale. They should move at 120% speed.

> no need for most of the UI for the custom client. We just want to be able
> to load vmaps and such and load all the models and display it in 3d
> space.

> can we add an issue file to the custom client for the options menu and
> it's settings? We should allow all resolutions up to ultrawide. The user
> should be able to type in a value if they want. Or there's a drop-down
> with common increments.

> You know the in-game UI elements in World of Warcraft? I love those. We
> should build an image generator for those, if we possibly can. It could
> build a UI for us like we were assembling our own... Neato. Anyway, we
> should be able to draw them like gizmos. "scrollbar" and "x_button" and
> "clicking-to-drag" etc that handle common UI patterns. Then we should
> draw the UI, when it exists, very flat and possibly shaded.

## Who the client is for

Verbatim, 2026-10-06:

> I'm not sure how integrated we want our custom changes to be, so try and
> keep the client separate from the various changes we've made to the
> server profiles. We want to make something that anyone can use to play
> World of Warcraft private servers.

> let's focus on re-implementing the original client before we build new
> features.

So the client is a general 3.3.5a client. It reads the original's data
files, speaks the original's protocol to any server, and offers the
original's controls and settings. Nothing in its core assumes this
project's profiles, buddies or custom items. Features made for this
project (box select of buddies, 617s7; buddy-specific switches) wait
until the original is rebuilt. When they come, they go in a separate,
optional layer that the core doesn't depend on.

## Current Behavior

**In progress (2026-10-06): a world to walk in, no network yet.** The
client is in C on Raylib (`src/custom-client-c/`, 173k; the Lua first
version is deprecated). Run it with `scripts/custom-client`; build and test
it with `scripts/build-custom-client --test`. Players still use the stock
3.3.5a client to play. Everything below is read from the original
client's own files, nothing hand-placed:
- **The world:**
  - painted ground (173f);
  - doodads and buildings with their furniture, moving doodads, and
    pieces with layered and moving pictures (173g);
  - particles, fading into the fog (173o);
  - the zone's light, the sky, and skyboxes (173n);
  - shadows (173h);
  - water, and the view underwater (173r).
- **Movement:**
  - collision with walls, floors and bridges, and the camera kept out of
    walls (173q);
  - swimming (173r);
  - the camera's drags, following styles, its camera-panel settings,
    and first person (173m);
  - tiles streaming in and out, and the far horizon (173s).
- **Characters:**
  - her model and animations, with glowing pieces (her eyes) (173d, 173i);
  - creatures and other races standing near her (173j), and the
    world's creatures and townsfolk from a list generated out of the
    server's world database (173t);
  - equipment painted on, switched pieces, and hung items (173p).
- **Settings:** the settings store (173b1) and the first settings,
  including View Distance (173b6).
- **Anywhere:** `--map ID X Y` starts the client on any map.
- **To check against the original:** `docs/custom-client-ingame-checks.md`.

## Intended Behavior

The project's own game client, built up in steps:

| ID | Name | Dependencies | Description |
|---|---|---|---|
| 173a | first-light | None | A night elf in Ashenvale walking on the server's own ground, the stock controls, 120% speed, Escape to quit (q at first); no UI, no network |
| 173b | options-menu | 173a | Settings: any resolution up to ultrawide, typed in or from a list of common sizes |
| 173c | ui-gizmo-image-generator | None | WoW-like interface pieces drawn by name ("scrollbar", "x_button", "clicking-to-drag"), flat and lightly shaded, assembled into interfaces |
| 173d | models-and-world-objects | 173a | The game's models and buildings (from the client's data files and the server's collision meshes) drawn in 3D |
| 173e | what-the-server-checks | 173a | The pass mark: every movement order acknowledged with the server's values, honest falls, Warden answered as the original client answers |
| 173f | painted-ground | 173d | The ground's textures and blend layers from the map's own ground files |
| 173g | doodads | 173f | Trees, rocks and buildings placed as the map places them (M2 and WMO) |
| 173h | shadow-maps | 173f, 173g | The ground's baked shadows and blob shadows under characters |
| 173i | night-elf-animation | 173d | Her bones and animations: stand, walk, run, jump, fall, fidget |
| 173j | models-standing-around | 173i | A few other models standing near her, cycling their animations |
| 173k | client-in-c-with-raylib | 173a, 173d | The client ported to C on Raylib, the start of the project's engine; the Lua version kept beside it as the reference |
| 173l | same-bytes-as-the-original | 173e | A shadow custom client fed the original client's server packets and the owner's inputs; every packet it would send compared with the original's |
| 173o | particles | 173g, 173n | Torch flames, wisps, fireflies' glow: each model's particle emitters read and run, drawn as camera-facing sprites |
| 173p | equipment-on-the-body | 173d | Gear worn: armour painted onto the skin sheet, body pieces switched by the item (sleeves, boots, gloves, robes, a tauren's tail), helmets, shoulders and weapons on the bones' attachment points |
| 173q | model-collision | 173g, 173a | She stands on bridges and in buildings and is stopped by walls: models' and buildings' collision shapes, read and placed, asked by the mover |
| 173r | water-and-swimming | 173q, 173f | Rivers, lakes, the sea and buildings' pools drawn from the ground and building files, and she swims in them as the original's swimming does |
| 173s | streaming-tiles | 173f, 173g, 173q, 173r | Tiles near her loaded, tiles left behind dropped with everything they brought; the far horizon from the low-detail map |
| 173t | creatures-from-the-world-database | 173j, 173p, 173s | The world's creatures and townsfolk, read from a world database into a generated file, standing where they spawn (the network's stand-in) |
| 173u | rendering-on-the-graphics-card | 173f, 173g, 173j, 173o | The processor decides what and where, the card does the per-point and per-pixel work: batched ground and doodads, sight tests, bending in the shader (checklist: docs/custom-client-optimization-checklist.md) |
| 173n | zone-light-and-sky | 173f, 173g | The world lit by the original's own light tables: sun, ambient, fog and sky colours by place and time of day |
| 173m | camera | 173a, 173b1 | Left drag orbits, right drag steers her; following styles in a table of behaviours (the owner's default: swing back behind her, horizontally only, while she moves); every camera setting live |

173b is itself split, one sub-issue per section of the original's
Options menu (173b1 to 173b16), so that each feature is built together
with its settings. The settings store (173b1) comes before the camera.

The owner's order for the next steps (2026-10-05): painted ground, then
doodads, then shadow maps, then her animation, then models standing
around.

Later steps (not yet issues): talking to the server, the rest of the
interface, 617s7's box select, 719's tooltips.

## Suggested Implementation Steps

1. 173a (in progress).
2. 173d, then 173b; 173c alongside.
3. 173b1 (the settings store), then 173m (the camera) with 173b4
   (owner, 2026-10-06), before painted ground. Key bindings (173b3) wait
   for the action bar. All new work is in C; the Lua client is
   deprecated (173k).

## Open Questions

1. Where does the client live: inside this project (`src/custom-client/`,
   as 173a starts it) or as a project of its own?
