# 157i1 - Each Part Built on Its Own, and Cached

## Status
- Created: 2026-10-26
- Parent: Issue 157i (a-linux-of-only-what-runs)
- Phase: 1
- **Blocks:** 157i

## Origin

The owner, 2026-10-26:

> for the custom linux, each component should have it's own compile
> script. We should create utilities that are able to be cached, and only
> recompiled when something part of them changes. And then, only that
> part, not the unchanged whole.

## Overview

The machines' system (157i) is assembled from parts: the kernel, the C
library, the C++ runtime, OpenSSL, the compression libraries, MySQL,
runit, LuaJIT, rmail, the servers. Each part is compiled from source, by
its own script, into its own output folder. A part is rebuilt only when
something it is made from changed, and then only the pieces of it that
changed.

## Current Behavior

Nothing builds parts. 157i's first draft took the libraries from the
development machine's own system (whatever `ldd` found); this replaces
that with parts compiled here.

## Intended Behavior

### A part

`config/machine-images/parts/<part>/`:

| File | Holds |
|---|---|
| `part.lua` | the source (address and fingerprint of the archive, or a git commit), the parts it is built against (by name), the files it installs |
| `build` | the script that compiles it: reads its inputs, writes only into its own output folder; runnable alone (`config/machine-images/parts/openssl/build [DIR]`) |

One script per part, so a part is read, changed and rebuilt by itself.

### Two levels of caching

1. **The whole part is skipped when nothing about it changed.** A part's
   key is a fingerprint (BLAKE2b) over: its `part.lua` and `build`, its
   source's fingerprint, the keys of the parts it is built against, and
   the compiler's identity. The output is kept in
   `cache/parts/<part>/<key>/`. If that folder exists, the part is not
   built at all. Since a part's key includes the keys of what it is built
   against, a change to OpenSSL rebuilds OpenSSL and then exactly the
   parts that use OpenSSL, and no others.
2. **Inside a part, only what changed is recompiled.** A rebuilt part
   keeps its build folder (`cache/parts/<part>/build/`) between builds,
   so its own build system (make, ninja) recompiles only the source
   files that changed and the ones that include them, not the whole
   part. A compiler cache (ccache) beneath catches the same file
   compiled the same way twice, even across folders.

The game servers are parts too (`worldserver-<profile>`), built against
the parts here rather than the development machine's libraries.

### The builder

`scripts/build-parts [DIR] <part>...` works out the order from the
"built against" lists, checks each part's key, and builds what is
missing, several at once where the order allows (each part's build is
independent once its inputs exist). It prints, per part: kept (key
found) or built (and why: which input changed), and the seconds taken,
and ends with a goodbye receipt.

The image (157i) is assembled from part outputs only, by copying, never
by compiling, so an image whose parts are all cached is made in
seconds.

## Suggested Implementation Steps

1. The key: a tool that computes a part's key from its files and its
   inputs' keys. Test: changing one byte of a part's `build` changes its
   key and the keys of everything built against it, and nothing else's.
2. `scripts/build-parts`: order, keys, cache lookup, parallel builds.
3. The first parts, smallest first: runit, zlib, LuaJIT; then OpenSSL,
   the C library, MySQL, the kernel; then the servers.
4. Test: building twice in a row builds nothing the second time; a
   changed source file in one part rebuilds that part (recompiling only
   that file) and the parts built against it.

## Open Questions

1. ~~Where the cache lives~~. Answered 2026-10-27: "kaun is fine", so
   `cache/` is in the project on /mnt/kaun. The folders are three, all made by this issue's builder, none existing yet:
   - `cache/parts/<part>/<key>/`: each part's finished output (the
     installed files of one build of one part), kept so an unchanged part
     is never built again;
   - `cache/parts/<part>/build/`: each part's build folder, kept so a
     changed part recompiles only its changed files;
   - the compiler cache (ccache's folder).
   For scale: today's one game-server build folder, `build-shadow/`, is
   5.4 GB (`du -sh build-shadow`); there would be one like it per part
   that is large (the kernel, MySQL, GCC, each server), and twice over for
   the two C libraries. `/mnt/kaun` was 40% used when this was decided.
2. ~~The compiler itself~~. Answered 2026-10-26: "yeah". The compiler
   (GCC with its C++ runtime, and binutils) is a part too, built first,
   from the development machine's compiler once and then from itself; its
   key, not the development machine's compiler, is in every other part's
   key. Built once per C library (157i).

## Related
- `issues/157i-a-linux-of-only-what-runs.md` (parent)
- `issues/136c-every-profile-built-at-once.md`: per-profile build folders,
  the same idea for today's builds
- `issues/completed/108-adaptive-build-parallelism.md`
