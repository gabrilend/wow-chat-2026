# Build Ledger: Toward the Next Compile

The owner, 2026-10-30: "the next time we compile, we will have all of the
profile's issue files built. Can you start working on that? Building the
issue files that have no opened questions, or where they have a few
possible answers, can you build both and let me choose afterwards? Make
sure you keep careful accounting so we know what to prune."

This is that accounting, kept by hand by the agent as each piece is
built (the status board, `docs/next-compile-status.md`, written by
`scripts/issue-status-board`, says where every issue stands; this says
what this push added, how to switch it, and what to choose).

**How to read it.** Every row is one piece of work. *Switch* is how it is
turned on (everything new starts off). *Choice* is where both answers to
an open question were built: pick one, and the other can be pruned.
*Prune* says what to remove if the piece isn't wanted. *Waits* means the
server side is written, compiler-checked with borrowed flags, and
uncommitted until the owner's compile builds it.

## Before the push: what was already waiting

- The compiler check (`scripts/test-patched-syntax`) now reaches the buddy
  module even when the last build was another profile's: all of its
  files pass, the painted-map switch (617o7, 617o8), the army of 64
  (617e17) and the stand-in changes (617t) included.
- The board counts issues whose Current Behavior opens "syntax-checked" or
  "not yet built" as waiting (38 waiting, not 24).

## Built in this push

| Issue | What | Switch | Choice | Committed | Prune |
|-------|------|--------|--------|-----------|-------|
| 625a | which abilities each talent improves, from the game's own data: `scripts/generate-talent-touches`, `src/lua-basic/data/buddy-talent-touches.lua`, `docs/talent-touches.md`, the module's `buddies_talent_touches_data.h`; `scripts/test-talent-touches` | (data) | none | yes | the generator, its outputs and test |
| 625 | the talent weights and the weighted draw among a concern's answers: `buddies_talent_draw.h`, `tests/buddy-talent-draw/`, `scripts/test-buddy-talent-draw` (committed); `buddies_talents.cpp/.h` and their registration in `buddies_roam_strategy.cpp`, `buddies_loader.cpp` (waits) | `Buddies.TalentWeights` 0 off, 1 or 2 | **1** a fixed raise per talent point, or **2** the talent's own percent; and `Buddies.TalentWeights.Broad` **100** or **50** (a broad talent's share) | core yes, server waits | `buddies_talents.*`, the two registration lines, the draw header and its test |

## Choices waiting for the owner

1. **Talent weights** (625, question 1): `Buddies.TalentWeights = 1` (each
   talent point raises an ability 6%) or `= 2` (as much as the talent's
   own stated percent, the per-point raise where it states a flat
   amount).
2. **Broad talents** (625a, question 1): `Buddies.TalentWeights.Broad =
   100` (a talent for "all your Shadow spells" counts on each in full) or
   `= 50` (half).

## Not built, and why

Kept as each candidate is looked at.

| Issue | Why not (yet) |
|-------|---------------|
