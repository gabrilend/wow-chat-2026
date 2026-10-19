# 1201c - Humanoid Robots for the Common Infected

## Status
- Created: 2026-10-17
- Phase: 12
- Parent: 1201 (robot search party)
- Blocked by: nothing (needs the game's Authoring Tools)
- Related: 506 (the gear gallery, the template for every generated
  asset), `docs/gear-3d-pipeline.md`, `scripts/convert-gltf-to-m2`
- Priority: Medium

## Current Behavior

The project makes its own 3D assets for World of Warcraft: designs are
generated and voted on in the gear gallery (506), and
`scripts/convert-gltf-to-m2` turns a glTF model into the game's format.
Nothing makes models for the Source engine.

## Intended Behavior

A few humanoid robot designs (open question: how many) replace the
common infected models. They are the project's own: designed, voted on
and recorded the same way the gear gallery does (a design, its source,
its rating), never taken from another game or the Workshop. Each is
rigged to the common infected's skeleton so the game's own animations
play on it (walking, attacking, stumbling, dying), and compiled to
Source's model format with the game's model compiler.

A robot that falls should look like a machine stopping, not a body
falling: sparks or a dimming eye light where the game's animations
allow, in the first version only through materials, not new animations.

## Suggested Implementation Steps

1. Read the common infected's skeleton (bone names and rest pose) from
   the game's files with the Authoring Tools, into a reference file.
2. Model one robot in glTF to that skeleton; a converter
   (`scripts/convert-gltf-to-source`) writes the compiler's input (an
   SMD or DMX file and a `.qc` script) and runs the compiler.
3. Pack it into the add-on, replacing the common infected model, and
   check in game that every animation plays without stretched limbs.
4. More designs through the gallery's design-and-vote loop.

## Open Questions

- How many robot designs: one recognisable kind, or a mixed crowd?
- Blender is the usual route to Source models; the project has none of
  its own. Write the glTF-to-SMD converter in Lua (house language) or
  use Blender's exporter by script?
