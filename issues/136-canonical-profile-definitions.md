# 136 - Canonical Profile Definitions

## Status
- Created: 2026-04-28
- Phase: 1 (Foundation)
- Priority: High (blocks correct release builds)

## Problem

Multiple project files describe the three profiles (alpha / release / beta)
inconsistently. Each disagrees with the others, and none reflects the
current intended model. Documentation drift has produced ambiguity about
what each profile *is*, which has cascaded into a `scripts/profiles`
configuration that builds the wrong thing.

This issue establishes the canonical definitions and lists every place
that must be updated to match.

## Canonical Definitions

### One-Line Summary

- **`alpha`** — is wow-chat-1. The whole old project as a frozen snapshot.
- **`release`** — the minimum featureset that is *guaranteed working*. Features
  enter release only after they're proven on beta. **Current focus:** getting ALE
  into the guaranteed-working set, so release can ship with the modern Lua engine.
- **`beta`** — future work. Extra stuff that is playable but not yet proven. We
  shift features from beta into release **one at a time** once they're proven
  working on beta.

The whole point of the three-tier model is the **promotion pipeline**: a feature
is developed in beta, hardened against bugs, and only crosses the line into
release after it has demonstrably worked. Release is therefore always a strict
subset of what beta can do, with each subset element having earned its place.

### `alpha` — Holiday Relic

A pinned, frozen snapshot of the early project state. Playable for
nostalgia (intended cadence: ~1 week per year as a holiday special).

- **AzerothCore source:** pinned to an old commit (date TBD; before the
  playerbots/ALE migration)
- **Lua engine:** mod-eluna (pre-ALE)
- **Playerbots:** absent
- **Custom behavior:** wow-chat-1 scripts (the original Lua corpus)
- **Modules:** mod-eluna, plus whatever wow-chat-1 originally shipped

### `release` — Public Release Target

The production server intended for ongoing public play. Modern AzerothCore
with playerbots and ALE, but only the **confirmed-working features** that
have been promoted from beta.

- **AzerothCore source:** current AzerothCore (HEAD or tracked release)
- **Lua engine:** mod-ale
- **Playerbots:** mod-playerbots (modern fork)
- **Custom behavior:** only features promoted from beta after validation
- **Modules:** mod-ale, mod-playerbots, mod-aoe-loot, mod-grownup
  (subject to add-on as features promote)

### `beta` — Active Development

Where new custom features are written, tested, and validated before
promotion to release. Same engine baseline as release plus everything
in flight.

- **AzerothCore source:** current AzerothCore (matches release)
- **Lua engine:** mod-ale (same as release)
- **Playerbots:** mod-playerbots (same as release)
- **Custom behavior:** all in-development custom Lua features
- **Modules:** release modules + any beta-only experimental modules

## Files to Update

### `scripts/profiles`
Currently:
- `alpha`: same repo+branch as release, modules=`mod-eluna mod-transmog`
- `release`: same repo+branch, modules=`(empty)`
- `beta`: same repo+branch, modules=`mod-ale mod-aoe-loot mod-grownup mod-playerbots`

Required:
- `alpha`: pinned commit on old AC fork (or eluna-compatible branch),
  modules include mod-eluna and wow-chat-1 customs
- `release`: current AC playerbots fork @ HEAD, modules=
  `mod-ale mod-playerbots mod-aoe-loot mod-grownup`
- `beta`: same source as release, modules=release + custom-feature modules

### Issues to mark superseded (point at this issue as canonical)
- `issues/TONIGHT.md` (says release=wow-chat-1 vanilla)
- `issues/129-release-to-beta-transition.md` (was 400; says release=wow-chat-1)
- `issues/133-profile-transition-system.md` (was 405; says release=vanilla)
- `issues/140-branch-based-azerothcore-versioning.md` (was 201; alpha modules wrong)

### Source-dir mapping (`scripts/authserver`, `scripts/worldserver`, `scripts/compile`)
Currently all three profiles map to `source-beta` for release and beta,
`source-alpha` for alpha. **Resolved 2026-05-19:** release and beta
*share* `source-beta`. The two profiles are the same compile against
the same source; what differs is the patch selection (release applies
a subset; beta applies all) and the runtime C-patch tuning. There is
no `source-release/` and no need for one.

- alpha   → `source-alpha` (pinned old AC, mod-eluna, isolated)
- release → `source-beta`  (current AC, shared with beta)
- beta    → `source-beta`  (current AC, shared with release)

### Modules-dir mapping (`scripts/install:update_modules_symlink`)
**Resolved 2026-05-19** (decision moved here from the now-superseded
issue 148):

The modules directory at the project root **shares its name with the
source directory it backs**. Since release and beta both compile from
`source-beta/`, both profiles use `modules-beta/`. There is no
`modules-release/` — that directory was a vestige from when release
was wow-chat-1 with different modules from beta, and should be removed.

- alpha   → `modules-alpha/` (if any; alpha's modules come via
            `source-alpha/modules/` directly or a parallel
            `modules-alpha/` if the symlink mechanism extends to alpha)
- release → `modules-beta/`  (same as beta — same source, same modules)
- beta    → `modules-beta/`  (canonical)

**Why not `modules-shared/`?** The shared-with-which-source link is
the load-bearing fact. Naming the directory after the source it backs
keeps the relationship visible — `modules-beta/` says "this is the
modules tree that compiles against `source-beta/`." A name like
`modules-shared/` hides what it's shared *with*.

**Why not symlink `modules-release/` → `modules-beta/`?** Symlinks
preserve the misleading name. Better to delete the misleading name
outright.

Implementation steps (deferred — do AFTER the current B020 rebuild
lands, so this cleanup doesn't surprise the build):

1. Move any contents of `modules-release/` that don't already exist in
   `modules-beta/` (audit first; should be empty or identical).
2. Delete `modules-release/`.
3. Update `scripts/install:update_modules_symlink` so the case-switch
   has `release|beta) target_dir="../modules-beta" ;;`.
4. Update the table-of-contents and any docs that reference
   `modules-release/`.

## Implementation Steps

1. Decide source-dir layout (shared vs separate for release/beta)
2. Update `scripts/profiles` PROFILE_REPO, PROFILE_BRANCH, PROFILE_COMMIT,
   PROFILE_MODULES per the canonical definitions
3. Add header comment to `scripts/profiles` pointing at this issue as
   the spec
4. Update or supersede the four conflicting issue docs above
5. Update `CLAUDE.md` "Current Development State" section to summarize
   profiles correctly (one paragraph max, link here for detail)
6. Run a clean build per profile to validate the modules produce a
   working server

## Open Questions

- Which exact AzerothCore commit should `alpha` be pinned to? (last
  commit before mod-ale was introduced? before playerbots merge?)
- Are wow-chat-1 customs maintained as a module or applied as patches?
- Do alpha and release/beta need separate `installed-files-${profile}`
  directories or can promote handle profile switches in one tree?
