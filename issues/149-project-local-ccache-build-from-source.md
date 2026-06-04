# 149 - Project-Local ccache, Built From Source

## Status
- Created: 2026-06-03
- Phase: 1 (Foundation — build pipeline)
- Priority: High (every install/compile currently re-runs a partial build that takes ~30 minutes and stresses the system; this is the operator's main day-to-day friction)

## Problem

A repeat run of `scripts/install` or `scripts/compile` triggers a
partial rebuild even when no source content has changed. On this
operator's machine that's ~30 minutes of compiler work and noticeable
thermal load. The rebuild is per-design, not a regression — it falls
naturally out of how the project's patching pipeline interacts with
GNU make's mtime check.

### The mtime walk

`scripts/compile` runs three steps that mutate file modification
times on `source-beta/`:

1. **`reset_source_trees`** — `git reset --hard` on `source-beta`. Any
   file that differs from HEAD (i.e. files a previous build's
   patches modified) gets its mtime stamped to the reset moment.
2. **`apply_patches_begin`** — the project's B-patches use `sed -i`
   to splice modifications into source files (e.g. B022 patches
   `src/common/Configuration/Config.cpp`). `sed -i` rewrites the
   file in place, bumping mtime even when the post-patch content
   is identical to a prior post-patch state.
3. **`unapply_patches_begin`** — runs after the build finishes. Reverts
   each patch via the same `sed -i` mechanism. The reverted file's
   mtime is now strictly later than the `.o` make produced from
   the patched content.

After step 3, every patched source file has an mtime later than
its corresponding object file. The next `make` invocation sees
"source newer than object → rebuild required" and walks the
dependency cascade — typically a handful of common-dir .o files
plus everything that includes their headers, then the slow link
of `worldserver`.

### Why each rejected alternative was rejected

- **Persistent patches** (don't unapply after build). Would solve
  the mtime problem outright. Rejected because this project's patch
  contract requires `source-beta/` to be at clean HEAD whenever a
  build isn't actively running. A perpetually-patched source tree
  breaks `git status`, complicates upstream pulls, and changes the
  patching mechanism's mental model.
- **Marker file tracking which patches are currently applied**.
  Rejected on two grounds: it adds a state file that has to be
  kept in sync, and it doesn't actually solve the underlying
  mtime problem on operator-initiated `compile --force` runs or
  in any case where the marker disagrees with reality.
- **System ccache install** (`pacman -S ccache`). Rejected because
  the project is supposed to be self-contained. Build deps live in
  `libs/` (see `libs/boost/`); ccache should follow the same model.

## Intended Behavior

- `libs/ccache/` holds a project-local ccache build, identical
  pattern to `libs/boost/` (downloaded tarball, built into a
  project-owned prefix, no system install).
- `build-cache/` (project root, visible, not dotfile-hidden) holds
  the ccache content cache. Lifecycle ties to the project: removing
  the project dir removes the cache; `rm -rf build-cache/` is the
  explicit "force fully fresh build" lever.
- `scripts/compile`'s cmake invocation includes
  `-DCMAKE_C_COMPILER_LAUNCHER` and `-DCMAKE_CXX_COMPILER_LAUNCHER`
  pointing at the project's ccache binary. `CCACHE_DIR` exports
  to `${DIR}/build-cache` so ccache writes to the project location
  instead of the per-user default.
- First build on an empty cache runs at the usual speed (cache
  miss for every translation unit). Every subsequent build whose
  patched-source content is byte-identical to a prior cached
  build returns object files instantly — the patched and
  re-patched files in particular always hash the same as their
  prior cached form, so the mtime churn becomes invisible to the
  final build cost. The slow `worldserver` link still runs
  unaffected; that's not in ccache's scope.

### How ccache handles failure

ccache is a transparent wrapper, not a replacement compiler. For
every translation unit cmake schedules:

1. ccache preprocesses the source (running the real compiler's
   preprocessor only — not the full compile) to produce the exact
   text the compiler would see after `#include` expansion.
2. ccache hashes that text + compiler flags + compiler identity.
3. **Cache hit**: ccache copies the cached `.o` into the build
   directory, prints the standard "Building CXX object ..." line,
   exits 0. The real compiler is never invoked.
4. **Cache miss**: ccache invokes the real compiler, captures its
   `.o`, exits with the compiler's exit code. If the compiler
   succeeded, the new `.o` is also added to the cache. If the
   compiler failed, nothing is cached; ccache's exit code and
   stderr match the compiler's exactly. The build halts as it
   would have without ccache.

Cache corruption never produces wrong binaries — at worst,
`ccache -C` wipes the cache and the next build is full-speed
uncached. Compiler upgrades invalidate all entries automatically
(the compiler binary's identity is part of the hash). Header
changes invalidate the entries that depend on them automatically
(the preprocessor expansion changes, so the hash changes).

## Cache Location Decision

`${DIR}/build-cache/`, not `~/.ccache/`.

Project-local because:
- The cache's lifecycle should follow the project, not the user.
- The operator's home dir stays clean of project-specific data
  (per the operator's stated preference).
- Multiple wow-chat checkouts on the same machine don't share
  state through a system-wide cache.
- `rm -rf build-cache/` is the operator's explicit reset lever,
  independent of any other ccache user on the system.

Not hidden (no leading dot) because:
- The operator wants visibility into project state, not hidden
  dot-clutter.
- `ls` should reveal what's eating disk in the project tree.

## Files To Update

### `scripts/ccache` (new)
Patterned on `scripts/boost`. Downloads the ccache release tarball
from `github.com/ccache/ccache/releases`, builds with the project's
existing cmake + clang, installs into `libs/ccache/`. Skips if
`libs/ccache/bin/ccache` already exists. Same idempotency contract
as `scripts/boost`.

ccache's own build dependencies:
- cmake (already needed for AC)
- C++17 compiler (already have clang)
- libzstd (header + library; ccache mandates this since 4.x)

If libzstd is missing, ccache's cmake configure fails with a clear
error. The script surfaces that error rather than papering over it.

### `scripts/compile` (the single bootstrap chokepoint)
- Resolve `CCACHE_BIN="${DIR}/libs/ccache/bin/ccache"` and
  `CCACHE_CACHE_DIR="${DIR}/build-cache"` in `get_profile_paths`.
- Before invoking cmake: if `CCACHE_BIN` doesn't exist, invoke
  `scripts/ccache` to build it (idempotent — no-ops if already
  present). This makes compile a single self-contained entry point;
  callers don't need to know ccache is part of the toolchain.
- `mkdir -p "${CCACHE_CACHE_DIR}"`; `export CCACHE_DIR="${CCACHE_CACHE_DIR}"`.
- Add to the cmake invocation:
  ```
  -DCMAKE_C_COMPILER_LAUNCHER="${CCACHE_BIN}"
  -DCMAKE_CXX_COMPILER_LAUNCHER="${CCACHE_BIN}"
  ```
- Full path used rather than relying on PATH so the build doesn't
  silently fall back to system ccache (or no-ccache) if PATH
  changes between sessions.

### Not modified: `scripts/install` and `scripts/update`
Both end by exec'ing `scripts/compile`. Because compile self-
bootstraps ccache, neither install nor update needs to know
ccache exists. Single-chokepoint design — adding a third caller
later inherits the same behavior for free.

## Implementation Steps

1. Write `scripts/ccache`. Use ccache 4.10.2 (latest stable as of
   ticket creation). Download from
   `https://github.com/ccache/ccache/releases/download/v4.10.2/ccache-4.10.2.tar.xz`.
   Build with `cmake -S . -B build -DCMAKE_BUILD_TYPE=Release` then
   `cmake --build build` then `cmake --install build --prefix libs/ccache`.
   Pattern-match `scripts/boost` for download/extract/check-existing logic.
2. Verify ccache binary at `${DIR}/libs/ccache/bin/ccache` and runs
   with `--version`.
3. Update `scripts/compile`: resolve the ccache paths in
   `get_profile_paths`, self-bootstrap via `scripts/ccache` if the
   binary's missing, export `CCACHE_DIR`, mkdir the cache dir, add
   the two `-DCMAKE_*_COMPILER_LAUNCHER` flags. Force a cmake
   reconfigure on first run after this change so the launcher gets
   picked up (operator invokes with `--force` once, or the script
   can detect a stale CMakeCache and reconfigure).
4. Validate: `time ./scripts/install` (full from-scratch) records
   baseline. Wipe `build-shadow/`, run again — must be at least
   as fast (cache cold = same speed). Run a third time — must
   complete the compile phase in well under a minute (cache warm,
   only the link runs at real speed).
5. Validate failure path: deliberately break a source file (introduce
   a syntax error), run compile, confirm the error surfaces normally
   and the build halts. Restore the file, confirm next build cache-hits.
6. Document the cache lever in `docs/installation.md` or wherever
   build operations are described: "to force a fully fresh build,
   `rm -rf build-cache/ build-shadow/`".

## Validation Criteria

- Time-to-compile after no real source change: under 60 seconds
  (cache hits + link).
- Time-to-compile from cold cache: matches pre-ccache baseline (no
  regression).
- Compiler errors surface unchanged in both cache states.
- `./scripts/install --force` and `./scripts/compile --force`
  continue to work as expected (ccache is transparent to forced
  reconfigure).
- `git status` on the project root shows `build-cache/` as
  ignored — add to `.gitignore`.

## Related Issues

- **109 (completed)** — Incremental rebuild detection. Gates rebuilds
  on "did upstream change?" Complementary to this ticket: 109 prevents
  needless `update` runs, 149 makes the needed runs fast.
- **122** — Atomic shadow builds. Adjacent build-system concern.
- **127** — Patch system improvements (already implemented). Documents
  that source-beta accumulates patches between builds and the
  intent to keep source clean — that intent is what blocks the
  "persistent patches" alternative and motivates this ticket's
  content-hash approach instead.
- **131** — Incremental patch integration. Adjacent, about which
  patches apply in what order.

## Notes

ccache's design property "hash content, not mtimes" is what makes
this the right tool for the job. The project's patch-and-unpatch
flow guarantees content stability (same patches → same content)
but not mtime stability. ccache's invariant matches the project's
invariant exactly: identical inputs produce identical outputs,
regardless of when the file was last written. That alignment is
why this fits without changing the patching mechanism.
