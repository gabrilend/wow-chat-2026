# 157f - World Machine

## Status
- Created: 2026-09-23
- Parent: Issue 157 (three-machine-deployment)
- Phase: 1
- **Blocked by:** 157b, 157c

## Overview

The worldserver runs on its own machine, with everything it reads at
startup: binaries, configs, extracted map data, and the Lua scripts.

## Current Behavior

- The worldserver reads its maps, vmaps, mmaps and DBC files from this
  machine's data directory (set by `config/patches/C002-directory-paths.sh`).
- Its Lua scripts arrive through a symlink into this machine's checkout
  (`installed-files-<profile>/bin/lua_scripts/custom` →
  `/home/ritz/.../src/lua-<profile>`), created by E001.

## Intended Behavior

- `scripts/deploy ship world` copies the binaries, configs, map data (only
  when it has changed; it runs to gigabytes) and the profile's Lua directory
  as real files. The world machine gets no symlinks back into the
  development checkout.
- Lua edits reach the running server with `ship` followed by
  `.reload ale`.
- The worldserver's thread settings (`MapUpdate.Threads`) are set for the
  world machine's core count, not the development machine's.

## Implementation Steps

1. List every path the worldserver reads at startup, from its configs and
   C002.
2. Teach `ship` to copy the Lua directory instead of relying on the symlink.
3. A config patch that sets the thread count from the roles file's world
   entry.
4. Start the worldserver with `scripts/deploy start world`, and play a
   session.

## Open Questions

1. Does the chat-bot work (916, 917) call a language model on the
   development machine? If so, the world machine needs that address.

## Related
- `config/patches/C002-directory-paths.sh`
- `patches/E-patches.sh` (E001, the Lua symlink)
