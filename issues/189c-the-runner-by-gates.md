# 189c - The Runner by Gates

## Status
- Created: 2026-10-20
- Phase: 1 (Foundation & Tooling)
- Parent: 189
- Blocked by: 189b
- Blocks: 189d, 189e, 192
- State: planned

## Current Behavior

`patches/patches.sh` runs each profile's lists in their written order, in
two stages around the compile; the undo goes last first (fixed
2026-10-20, `scripts/test-patch-undo-order`).

## Intended Behavior

The runner reads the headers of every patch a profile takes (by name or
through a group), sorts them by priority and runs them through the gates
(`patches/gates`): at each gate it finishes every patch below it, then
does the gate's action (compile and install; databases to upstream's
state; the server may start). Patches of one priority may run at once.
Undo is the exact reverse. Two patches that touch the same file may not
share a priority (an error naming both). A broken header stops the run;
skipped files are listed. The lists in `patches/patches.sh` and the
settings patches' `CONFIG_PROFILES` lines are removed.

## Suggested Implementation Steps

1. `patches/gates`, with its header.
2. The runner, reading headers through `scripts/lib/patch-header.lua`.
3. Tests with pretend patches: order by priority across kinds, gates
   holding later patches back, same-priority patches in any order, exact
   reverse undo, the layering check, a group expanding.
4. The owner compiles each profile once; the build's report lists every
   patch as before.
