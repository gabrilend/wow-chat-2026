# 189b - Headers on Every Patch

## Status
- Created: 2026-10-20
- Phase: 1 (Foundation & Tooling)
- Parent: 189
- Blocked by: 189a
- Blocks: 189c, 189f
- State: completed 2026-10-20

## Current Behavior

Built 2026-10-20. `scripts/write-patch-headers` read the lists and wrote a
whole header and footer into 189 files: 41 source patches, 55 install
steps, 41 settings patches and the 52 quick tests (shell ones with `#`,
Lua ones with `--`, after each `#!` line). Run again it changes nothing
(idempotent); a broken header stops it. The priorities keep today's order
exactly (every profile's lists were already in ascending id order):

| what | priority |
|---|---:|
| quick tests | 10 |
| source patches | 100 + 10 x number (B056: 660) |
| E001, E004, E006 (links, logs, config files) | 1010, 1040, 1060 |
| settings patches, in today's file order | 1100 + 5 apart |
| the other install steps | 1300 + 10 x number (E065: 1950) |

`patches/groups` names `buddy-set` (basic and cc-test); a patch taken by
exactly those profiles says `buddy-set`. A patch on no list says `none`;
a settings patch for every profile says `all`.
`scripts/test-patch-headers-match-lists` (15 checks, a quick test) checks
that for every profile the source patches and install steps the headers
name, sorted by priority, are exactly its lists in order; that every
settings patch's header names its `CONFIG_PROFILES`; that the tests marked
quick are the compile's list; and that every one has a whole header.
After the headers, all 49 quick tests then in the list, and the source
patches' round trips on basic, beta and vanilla, passed.

The lists still drive the build until 189c. Every edit to a patch changes
its line count: `scripts/check-patch-headers --fix-lines` mends it (noted
in CLAUDE.md).

Before this, what each patch is, which profiles take it and its place in
the order were only in `patches/patches.sh`'s lists, the settings
patches' `CONFIG_PROFILES` lines and the compile's quick-test list.

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
