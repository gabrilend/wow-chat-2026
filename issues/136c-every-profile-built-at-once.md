# 136c - Every Profile Built at Once

## Status
- Created: 2026-10-26
- Phase: 1 (Foundation — profile model; see 136 parent)
- Parent: 136 (canonical-profile-definitions)
- Builds on: 136b (every profile running at once)
- **Blocks:** 157h (a promote that ships one profile while another builds)

## Origin

The owner, 2026-10-26: "I want to be able to run every single realm at
once, so we should design all of our issue plans as if each realm profile
is built in parallel."

This is a project-wide rule (written into `docs/roadmap.md`, Project-wide
decisions): every issue's plan assumes two profiles may be compiling,
validating, promoting or shipping at the same moment, and says which of
its files are per profile and which are shared, and how the shared ones
are guarded.

## Current Behavior

A build of one profile uses folders every other profile uses too, so two
builds at once would overwrite each other:

| Shared today | Used for | Where it is named |
|---|---|---|
| `source-beta/` (one tree for release, beta, vanilla, basic, cc-test) | the B-patches are applied to it before compiling and taken off after | `scripts/compile`, the profile → source table |
| `build-shadow/` (one CMake build folder for every profile) | the compiler's object files and its cache | `scripts/compile`, `BUILD_DIR_SHADOW` |
| `installed-files-shadow/` (one) | where a build installs before validation | `scripts/compile`, `scripts/validate`, `scripts/promote` |
| `.profile` (one file naming the active profile) | the default when a script is not given `--profile` | most scripts |
| `tmp/shadow-gate-2000-<profile>.log` | already per profile | `scripts/validate` |

Two profiles that share `source-beta/` but take different B-patches are
the hardest case: one build's patches would be inside the other's
compile.

The compile already guards one shared thing: the quick tests take
`tmp/shared-memory/test-runs.lock`.

## Intended Behavior

Every profile builds in its own folders, so any number of profiles can
compile, validate, promote and ship at the same time:

| Per profile | Replaces |
|---|---|
| `source-<profile>/`, a git worktree of the upstream checkout at the same commit, B-patches applied for this profile only | the shared `source-beta/` |
| `build-shadow-<profile>/` | `build-shadow/` |
| `installed-files-shadow-<profile>/` | `installed-files-shadow/` |
| `tmp/shared-memory/compile-<profile>.lock` | (none): one build per profile at a time |

Worktrees share one git object store, so each extra source tree costs
only its checked-out files, and the upstream commit is the same for all
(the update step moves them together).

Scripts that run for one profile take `--profile` and never fall back on
`.profile` when run by another script (the caller always passes it).
`.profile` remains the person's default at the keyboard.

What stays shared, and how it is guarded:

- **MySQL** — one server; each profile writes only its own databases
  (136b). The shared `acore_auth` gets only this profile's realm row.
- **The processor** — builds at once share the cores. Issue 108's
  adaptive parallelism divides the cores between the builds running (each
  build reads how many other compile locks are held).
- **The quick tests** — their lock, as today.

## Suggested Implementation Steps

1. List every path `scripts/compile`, `scripts/validate`,
   `scripts/promote`, `scripts/update` and `patches/patches.sh` write,
   and mark each per profile or shared (a table in this issue's Current
   Behavior when done).
2. Per-profile worktrees: `scripts/update` creates or moves
   `source-<profile>/` worktrees from the one upstream checkout.
3. Per-profile build and shadow-install folders in the four scripts.
   These are shared files (CLAUDE.md, "When more than one agent works
   here"): claimed by one agent at a time, built by the owner.
4. The per-profile compile lock; the adaptive parallelism shares cores.
5. Test: `scripts/test-two-profiles-build-apart` — runs the build's path
   planning (no compiler) for two profiles and fails if any written path
   is the same for both, other than the listed shared ones.

## Open Questions

1. ~~Disk~~. /mnt/kaun, taken from the owner's answer for the parts
   cache (2026-10-27, "kaun is fine"): each build folder is several
   gigabytes (`du -sh build-shadow`), six profiles is six of them.
2. ~~Builds at once on this machine~~. Answered 2026-10-28: "they should
   be built iteratively, not at once. Let me know and I will compile
   them." The folders are kept apart so the order never matters and one
   profile's build cannot spoil another's; one build runs at a time, and
   the owner runs it. The per-profile lock stays, as the guard that says
   so when a second build is started by mistake.

## Related
- `issues/136b-every-profile-running-at-once.md`
- `issues/157h-promotion-ships-to-the-host.md`
- `issues/completed/108-adaptive-build-parallelism.md`
- `issues/137-shadow-conf-path-baked-into-binary.md`: the shadow install
  path baked into the binary must become per profile too
- `issues/completed/115-shadow-build-setup.md`
