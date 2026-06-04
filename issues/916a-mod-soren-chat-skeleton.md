# 916a - mod-soren-chat C++ Shim Skeleton

## Status
- Created: 2026-06-03
- Parent: Issue 916 (mod-soren-chat)
- Phase: 3
- Priority: High (foundation — blocks every other 916 sub-issue)

## Overview

Stand up the bare AzerothCore module skeleton for mod-soren-chat. Make
it compile, load on worldserver start, and produce one log line proving
it loaded. No functionality beyond that. Verifies the build pipeline
works for a new module on the vanilla profile before any actual logic
lands.

## Current Behavior

No mod-soren-chat directory exists in `source-beta/modules/`. The vanilla
profile's `PROFILE_MODULES` does not list it. No corresponding lua-side
files exist in `src/lua-vanilla/`.

## Intended Behavior

After this sub-issue lands:

- `source-beta/modules/mod-soren-chat/` directory exists with a valid
  `CMakeLists.txt`, a single `.cpp` registering the module's loader
  function, and a stub `mod_soren_chat.conf.dist`
- `scripts/install`, `scripts/compile`, `scripts/update` all list
  `mod-soren-chat` in vanilla's `PROFILE_MODULES` entry
- `mod-soren-chat` clones into `source-beta/modules/mod-soren-chat/`
  during install (`MODULE_REPOS` entry — though for v0 this points at a
  local path or empty repo since the module hasn't been pushed anywhere
  yet)
- A clean vanilla build compiles mod-soren-chat into worldserver
- On worldserver startup, the log shows one line: `[soren-chat] module
  loaded (build skeleton — no behavior yet)`

## Implementation Steps

1. Create the `source-beta/modules/mod-soren-chat/` directory structure:
   ```
   mod-soren-chat/
   ├── CMakeLists.txt
   ├── conf/mod_soren_chat.conf.dist
   └── src/
       └── SorenChatLoader.cpp
   ```
2. Write `CMakeLists.txt` following the AzerothCore module skeleton
   pattern (reference: any existing module's CMakeLists, e.g.
   `mod-ale/CMakeLists.txt` or `mod-aoe-loot/CMakeLists.txt`)
3. Write `SorenChatLoader.cpp` with a single `AddSC_mod_soren_chat()`
   function that registers nothing yet, just calls `LOG_INFO("soren-
   chat", "module loaded (build skeleton — no behavior yet)")`
4. Write the stub `mod_soren_chat.conf.dist` with the config keys from
   the parent ticket (`SorenChat.Enable`, etc.) all defaulted off
5. Add `mod-soren-chat` to `PROFILE_MODULES["vanilla"]` in
   `scripts/install`, `scripts/compile`, `scripts/update`
6. Add a `MODULE_REPOS["mod-soren-chat"]` entry — for v0 a placeholder
   pointing at a local path or a fresh empty repo on the user's machine.
   Real upstream URL comes later when the module is published.
7. Run `./scripts/update --profile=vanilla --threads=8` and verify a
   clean build with the new module included
8. Start worldserver, confirm the log line appears

## Files to Create

- `source-beta/modules/mod-soren-chat/CMakeLists.txt`
- `source-beta/modules/mod-soren-chat/conf/mod_soren_chat.conf.dist`
- `source-beta/modules/mod-soren-chat/src/SorenChatLoader.cpp`

## Files to Update

- `scripts/install` — add to `PROFILE_MODULES["vanilla"]` and to
  `MODULE_REPOS`
- `scripts/compile` — add to `PROFILE_MODULES["vanilla"]`
- `scripts/update` — add to `PROFILE_MODULES["vanilla"]` and to
  `MODULE_REPOS`
- `issues/148-vanilla-profile-default-wotlk-playerbots.md` — add
  mod-soren-chat to the canonical module list (handled in main 916
  ticket follow-up, not strictly part of this sub-issue)

## Open Questions

- Where does mod-soren-chat live as a git repo? On the user's local
  filesystem during development, presumably; pushed to a remote (github
  or self-hosted) when stable. The placeholder URL in `MODULE_REPOS`
  should make the path-vs-URL choice visible.
- Should the placeholder `MODULE_REPOS` entry point at the in-place
  module directory (i.e. don't clone, just symlink), to avoid the
  install script attempting to git clone something that isn't published
  yet? Decide during implementation.

## Related

- Parent: [916 - mod-soren-chat](916-mod-soren-chat.md)
- [148 - Vanilla profile](148-vanilla-profile-default-wotlk-playerbots.md) —
  needs module list update once this lands
- AzerothCore skeleton-module repo: <https://github.com/azerothcore/skeleton-module>
  (reference pattern for new modules)
