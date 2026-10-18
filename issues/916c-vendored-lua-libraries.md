# 916c - Vendored Lua Library Installation

## Status
- Created: 2026-06-03
- Parent: Issue 916 (mod-soren-chat)
- Phase: 3
- Priority: High (blocks 916d, 916e — anything that touches HTTP/JSON/threads)
- Depends on: 916a (skeleton must exist)

## Overview

Install the three Lua libraries mod-soren-chat needs (luasocket, dkjson,
effil-jit) by copying them from the user's existing local library
directory at install time. No package manager involvement. Establishes
the pattern for any future Lua library mod-soren-chat needs. Also builds
the one C library it needs, llama.cpp (step 6), from a pinned upstream tag.

## Current Behavior

The user maintains a local Lua library collection at
`/home/ritz/programming/ai-stuff/libs/lua/`. The required libraries
exist there:

- `luasocket/` — TCP/HTTP, lib + share subdirs
- `dkjson.lua` — single-file JSON parser
- `effil-jit/` — OS-thread library with build/, src/, libs/ subdirs
- `effil/` — non-JIT variant (we don't use it directly)

No installation pipeline exists yet for getting them into worldserver's
Lua load path.

## Intended Behavior

After this sub-issue lands:

- The mod-soren-chat install step copies the three libraries into
  `installed-files-vanilla/bin/lua_scripts/libs/`
- Lua scripts loaded via ALE can `require()` them with stable paths:
  ```lua
  local socket = require("libs.luasocket.socket")
  local json   = require("libs.dkjson")
  local effil  = require("libs.effil-jit.effil")
  ```
- The install pipeline is idempotent (re-running install doesn't
  duplicate or break anything)
- Updating libraries is mechanical: drop the new version into
  `/home/ritz/programming/ai-stuff/libs/lua/` and re-install

## Implementation Steps

1. Decide layout in the install dir: `lua_scripts/libs/<libname>/`. Each
   library gets its own subdirectory. Easier to reason about than
   flattening.
2. Add a step to mod-soren-chat's `CMakeLists.txt` (or a separate
   install script called from CMake) that:
   - Copies `/home/ritz/programming/ai-stuff/libs/lua/luasocket/lib/*`
     and `/share/*` into the right place
   - Copies `/home/ritz/programming/ai-stuff/libs/lua/dkjson.lua` to
     `lua_scripts/libs/dkjson.lua`
   - Copies effil-jit (built binary + lua loader) into
     `lua_scripts/libs/effil-jit/`
3. Configure `package.path` and `package.cpath` for ALE's Lua state to
   include the new `libs/` paths. Likely done via a small Lua bootstrap
   script (`00-libs-bootstrap.lua`) that runs before any other ALE
   script.
4. Write a smoke test script that requires all three and prints version
   info:
   ```lua
   local socket = require("libs.luasocket.socket")
   local json = require("libs.dkjson")
   local effil = require("libs.effil-jit.effil")
   print("luasocket: " .. socket._VERSION)
   print("dkjson: ok")
   print("effil-jit: ok")
   ```
5. Run the smoke test, confirm all three load
6. **llama.cpp** (added 2026-10-17, when it replaced Ollama; see 916d).
   It is a C library, not a Lua one, and it is not in `libs/lua/`, so it
   is built rather than copied:
   - A bash script with the house `${DIR}` header clones
     <https://github.com/ggml-org/llama.cpp> at a **pinned tag** into the
     RAM-backed `tmp/`, configures it with CMake (`-DGGML_CUDA=ON` and the
     GPU's compute capability when building for a GPU; CPU-only for the
     mini-PCs), and installs only `bin/`, `lib/`, `include/` into
     `libs/llama.cpp/` with an RPATH of `$ORIGIN/../lib` so the binaries
     find their libraries without `LD_LIBRARY_PATH`.
   - The sibling project neocities-modernization already does exactly
     this in its `scripts/build-deps.sh` (its issue 10-049), including the
     CUDA 12.9 pin the 1080 Ti (Pascal) needs. Copy its shape; do not
     depend on its directory.
   - The install step copies `libs/llama.cpp/lib/libllama.so` (and the
     `ggml` libraries beside it) to where in-server ALE's `ffi.load`
     finds it, and `bin/llama-server` to what gets copied to each
     "beside" machine.
   - The model file (`.gguf`) lives in `assets/models/`, downloaded by the
     same script, not checked in.
   - The owner runs this build (the project's rule for long compiles).
7. Smoke test for llama.cpp: `luajit` loads `libllama.so` through `ffi`,
   loads the model, prints its parameter count; `llama-server` started on
   a spare port answers `GET /health` with 200.

## Files to Create

- `source-beta/modules/mod-soren-chat/lua/00-libs-bootstrap.lua` — sets
  package.path and cpath so subsequent scripts can require the libs
- `scripts/build-llama-cpp` — the pinned clone, CMake build and install
  of llama.cpp into `libs/llama.cpp/`, and the model download (step 6)
- (Possibly) a CMake helper script for the file copies, e.g.
  `source-beta/modules/mod-soren-chat/cmake/install-lua-libs.cmake`

## Files to Update

- `source-beta/modules/mod-soren-chat/CMakeLists.txt` — invoke the copy
  step at install time

## Open Questions

- effil-jit needs a compiled `.so` (the C extension). The libs dir
  contains a `build/` subdir — investigate whether it ships a prebuilt
  binary for the host architecture or needs a build step on install.
  If the latter, this sub-issue grows a "build effil-jit" step.
- Versioning policy: do we track which version of each library is
  installed? Lean toward "whatever's in the user's libs dir at install
  time" with a stamp file recording the timestamp.
- Cross-machine sync: if the worldserver moves to a different host
  later, the `/home/ritz/programming/ai-stuff/libs/lua/` path won't
  exist there. The install should fail loudly in that case rather than
  silently skip the libs. Probably a path check at the top of the
  install step.

## Related

- Parent: [916 - mod-soren-chat](916-mod-soren-chat.md)
- [916a - Skeleton](916a-mod-soren-chat-skeleton.md) — blocks this
- [916d - The model runner](916d-llama-cpp-model-runner.md) — consumes
  luasocket, dkjson and the built llama.cpp
- [916e - effil worker pool](916e-effil-worker-pool.md) — consumes
  effil-jit
- CLAUDE.md note: "you can find all needed libraries at
  /home/ritz/programming/ai-stuff/libs/" — this sub-issue is the
  install mechanism that honours that.
