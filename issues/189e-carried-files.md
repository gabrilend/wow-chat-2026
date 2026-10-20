# 189e - Patches That Carry Their Own Files

## Status
- Created: 2026-10-20
- Phase: 1 (Foundation & Tooling)
- Parent: 189
- Blocked by: 189c
- Blocks: 192
- State: planned

## Origin

wow-chat-2026-ae, for issue 192, 2026-10-20 (the owner's decision that
day): Sargobras's Lua moves out of `src/lua-basic/` into a home owned by
one patch, which copies it into `installed-files-<profile>/bin/lua_scripts/custom/`
for each profile that takes it and removes it on undo; the same for the
buddy SQL cc-test reads from basic (`_buddy_sql_src`) and the buddy module
B036 copies in.

## Current Behavior

Files a patch needs are found where another profile keeps them (basic's
`src/lua-basic/`, basic's SQL folders), so a profile taking the patch
depends on basic's tree.

## Intended Behavior

A header's `carries:` names files kept beside the patch in git and where
each goes in a profile's install; the runner places them when the patch is
applied and removes them when it is undone. The templates stay in git; the
placed copies never are.

## Suggested Implementation Steps

1. The `carries:` field and its destinations (189a's reader).
2. The runner places and removes carried files.
3. Sargobras's Lua, the buddy SQL and the buddy module moved to be carried.
4. Tests: placed on apply, removed on undo, nothing left behind.
