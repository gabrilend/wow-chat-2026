# 173c - Interface Pieces by Name

*Continues in the W client (`/mnt/mtwo/games/azeroth-core/custom-client/`), since the move on 2026-10-07 (173v): Phase 7 (the interface; no issue yet). This issue stays as the record of how the client began; its paths are as they were then.*

## Status
- Created: 2026-10-04
- Phase: 1
- Parent: 173 (the custom client)
- Blocked by: None
- Priority: Medium

## Origin

See 173 (the owner's words, 2026-10-04).

## Current Behavior

Not built.

## Intended Behavior

A generator that draws World of Warcraft-like interface pieces from a
short description: a named piece ("scrollbar", "x_button",
"clicking-to-drag", "frame", "tab", "tooltip", "slider", "check_box") and
its size and state, out comes the image, flat and lightly shaded. Pieces
handle their common patterns (a scrollbar's thumb and arrows, a close
button's hover and press, a frame dragged by its title). Interfaces are
assembled from pieces by a description, so a whole window can be
generated and looked at before the client draws it live.

## Suggested Implementation Steps

1. The piece vocabulary and the description format (the
   canvas-and-paintbrush studio's way: a small closed language, outputs
   kept and rated).
2. Each piece's drawing, flat with a little shading.
3. Interfaces from pieces; then the client draws the same descriptions live.

## Open Questions

1. (Answered 2026-10-07) Look: plain flat colours, or the game's
   stone-and-gold borders drawn flat? "for now we can load the WoW
   interface frames. We will create our own as time goes on." So the
   first pieces use the original's own interface pictures, read from its
   archives (the `Interface\` folders) like every other picture. The
   project's own drawings replace them one by one later.
