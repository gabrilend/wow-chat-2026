# 1201a - The Roaming Pattern in Squirrel

## Status
- Created: 2026-10-17
- Phase: 12
- Parent: 1201 (robot search party)
- Blocked by: nothing
- Priority: Medium

## Current Behavior

`docs/roaming-pattern.md` has two implementations: Lua
(`src/lua-basic/lib/buddy-roam.lua`) and JavaScript
(`docs/HTML/buddy-roaming/roam-pattern.js`). `scripts/test-roam-pattern`
runs both on the same seeded situations and checks they agree. Neither
runs in Left 4 Dead 2, whose scripting language is Squirrel (VScript).
No Squirrel interpreter is installed on this machine.

## Intended Behavior

A third implementation, `src/l4d2/roam-pattern.nut`, written the way
Squirrel wants (classes and tables), saying exactly what the pattern
document says: the ground grid, paint, walls' paint, sectors, the
waypoint rule. It knows nothing of the game: areas, positions and a
random source come in, the next spot to walk to comes out.

`scripts/test-roam-pattern` gains it as a third column: the same seeded
situations run through a plain Squirrel interpreter outside the game,
and all three must agree. A disagreement is a fault in one of them, or
in the document.

## Suggested Implementation Steps

1. Build Squirrel 3 (the language Left 4 Dead 2 embeds; a small C++
   program, `sq`) into `libs/` with a pinned version, by a bash script
   with the house `${DIR}` header. Record which version the game's
   VScript matches (open question).
2. Write `roam-pattern.nut` from the document, not from the Lua (the
   point of the pattern is that it can be built from its description).
3. A seeded random source with the same sequence as the other two (the
   document's "a random number is uniform on [0, 1)", with the seed
   generator the test already uses).
4. Add the third column to `scripts/test-roam-pattern`.

## Open Questions

- Which Squirrel version does Left 4 Dead 2's VScript run (it is 2.x in
  some Source games and 3.x in others)? The interpreter in step 1 must
  match it, or the offline check proves nothing.
