# 189b - Headers on Every Patch

## Status
- Created: 2026-10-20
- Phase: 1 (Foundation & Tooling)
- Parent: 189
- Blocked by: 189a
- Blocks: 189c, 189f
- State: planned

## Current Behavior

What a patch is, which profiles take it and its place in the order are in
`patches/patches.sh`'s lists and in each settings patch's
`CONFIG_PROFILES` line; the compile's quick tests are a list in
`scripts/compile`.

## Intended Behavior

Every source patch, settings patch, install step and quick test carries a
whole header (189a) saying what the lists say today, written by a tool,
not by hand. Priorities keep today's order exactly: source patches below
gate 1000, settings and install steps between 1000 and 2000 (in the
order the build runs them today: E006 first with the settings inside it),
leaving gaps (steps of 10) so a patch fits between two. A groups file
(`patches/groups`) names sets several profiles take (the buddy patches
basic and cc-test share, and econ's when 192 registers it). While the
lists still drive the build (until 189c), a test checks that every header
says exactly what the lists say, so the two can't part.

## Suggested Implementation Steps

1. `scripts/write-patch-headers`: from the lists, the settings patches'
   profile lines and the compile's test list, writes each header and
   footer; idempotent (a whole header is rewritten, not doubled).
2. `patches/groups`, with its own header.
3. `scripts/test-patch-headers-match-lists`, in the quick tests.
4. `scripts/check-patch-headers` finds every patch whole.
