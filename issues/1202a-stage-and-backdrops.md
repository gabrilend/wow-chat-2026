# 1202a - The Stage and Its Backdrops

## Status
- Created: 2026-10-17
- Phase: 12
- Parent: 1202 (the robot stage show)
- Blocked by: nothing
- Related: 506 (the design-and-vote loop), the studio skill
  (`canvas-and-paintbrush`: describe, render, rate, keep)
- Priority: Medium

## Current Behavior

The project generates assets through describe-render-rate loops (the
gear gallery, 506; the sprite and picture generators), keeps every
result with its rating, and draws on the best. Nothing makes theatre
scenery.

## Intended Behavior

A toy theatre seen from the audience: a proscenium arch, a curtain that
opens and closes between acts, a floor the robots stand on, and a
painted backdrop behind them. Four backdrops to start: a coral reef, a
harbour at dusk, the inside of a sunken ship, a starry night over the
sea. Painted-flat style: soft shapes, warm colours, nothing frightening
(no deep dark, no sharp teeth).

Each scene is a small file: its backdrop picture, the stage area for
1202b (where robots may stand), and its **clickable things**, each with
an outline, a name ("the striped shell") and a few words of what it is
("it hums when you hold it"), which 1202c gives the robots to talk
about.

The pictures are the project's own, made by a describe-render-rate loop
like the gallery's: a written description of each backdrop renders to a
picture (SVG drawn by a generator, or an image model if one is wanted;
open question), every result is kept, rated, and the best is used.

## Suggested Implementation Steps

1. The scene file format (a Lua table, read by a tool that writes the
   page's JSON), with the four scenes described in words.
2. The theatre frame and curtain, drawn once.
3. The backdrop generator and its rating page.
4. A check: every clickable thing lies inside the picture and outside
   the stage floor's walkable area, and every scene has at least three.

## Open Questions

- Backdrops drawn by our own SVG generator (fully the project's own,
  simple), or by an image model through the gallery's loop (richer;
  where does the model run, and what may it be trained on)?
