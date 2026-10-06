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

## Current Behavior

Not built (first light under way, 173a). Players use the stock 3.3.5a
client.

## Intended Behavior

The project's own game client, built up in steps:

| ID | Name | Dependencies | Description |
|---|---|---|---|
| 173a | first-light | None | A night elf in Ashenvale walking on the server's own ground, the stock controls, 120% speed, q to quit; no UI, no network |
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

The owner's order for the next steps (2026-10-05): painted ground, then
doodads, then shadow maps, then her animation, then models standing
around.

Later steps (not yet issues): talking to the server, the rest of the
interface, 617s7's box select, 719's tooltips.

## Suggested Implementation Steps

1. 173a (in progress).
2. 173d, then 173b; 173c alongside.

## Open Questions

1. Where does the client live: inside this project (`src/custom-client/`,
   as 173a starts it) or as a project of its own?
