# 136 - Canonical Profile Definitions

## Status
- Created: 2026-04-28
- Phase: 1 (Foundation)
- Priority: High (blocks correct release builds)

## User-facing reference

For an end-user view of each profile (what it gives you, how to
switch, what to expect at each level), see the user-facing pages
under [`docs/profiles/`](../docs/profiles/index.md):

- [`docs/profiles/index.md`](../docs/profiles/index.md) — overview + how to switch
- [`docs/profiles/vanilla.md`](../docs/profiles/vanilla.md)
- [`docs/profiles/release.md`](../docs/profiles/release.md)
- [`docs/profiles/beta.md`](../docs/profiles/beta.md)
- [`docs/profiles/alpha.md`](../docs/profiles/alpha.md)

This issue (136) remains the canonical source of truth for the
promotion-pipeline rules, schema-level decisions, and historical
context. The docs/ pages summarise the user-relevant slice.

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

- **`vanilla`** — added 2026-06-02 per issue 148. A separate baseline
  alongside the promotion pipeline: default WotLK feel with playerbots
  and a small QoL module set, no Lua engine, no custom scripting.
  Sits outside the alpha → beta → release pipeline because it's a
  parallel ruleset, not an iteration of the wow-chat design.
- **`alpha`** — is wow-chat-1. The whole old project as a frozen snapshot.
- **`release`** — the minimum featureset that is *guaranteed working*. Features
  enter release only after they're proven on beta. **Current focus:** getting ALE
  into the guaranteed-working set, so release can ship with the modern Lua engine.
- **`beta`** — future work. Extra stuff that is playable but not yet proven. We
  shift features from beta into release **one at a time** once they're proven
  working on beta.

The four-tier model has two independent axes. One axis is the
**promotion pipeline** (alpha → beta → release): a feature is
developed in beta, hardened against bugs, and only crosses the line
into release after it has demonstrably worked. Release is therefore
always a strict subset of what beta can do, with each subset
element having earned its place. The other axis is the
**vanilla branch**: a separate ruleset that doesn't participate in
the pipeline — it's the "what does playerbots feel like without the
wow-chat design layer" reference. The two axes share infrastructure
(source-beta, MySQL on port 3307) but maintain isolated rulesets
(vanilla has its own database namespace, level cap, starting zones,
etc.).

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

### `vanilla` — Default WotLK + Playerbots Baseline

A parallel ruleset, not part of the alpha → beta → release pipeline.
Default WotLK 3.3.5a feel with AI companions: what does
mod-playerbots deliver before the wow-chat design layer is added?
Useful as an a/b comparison baseline, as a landing-pad for visitors
who want a stock experience, and as the floor everything else
builds on. See issue 148 for the full design.

- **AzerothCore source:** current AzerothCore (liyunfan1223 fork,
  `Playerbot` branch — same as release/beta, **tracks upstream HEAD**.
  Originally pinned 2026-06-02 for reproducibility; un-pinned later
  that day per user direction so vanilla stays current alongside
  beta and release.
- **Lua engine:** `mod-ale` (added 2026-06-02 per 148k for the
  starter-equipment auto-equip hook). Per-profile Lua dir is
  `src/lua-vanilla/`; the wow-chat design corpus in `src/lua-beta/`
  is NOT loaded.
- **Playerbots:** mod-playerbots (modern fork)
- **Custom behavior:** none of the wow-chat design layer (no ambush
  spawns, no custom classes, no talent reshaping). A small set of
  ruleset tunings define vanilla's identity: level cap 40, starting
  level 20, starting zones Duskwood (Alliance) and Hillsbrad
  (Horde), Death Knight class disabled, no flight paths, full
  level-20 starting kit per class, all level-≤20 trainer abilities
  pre-learned at creation. Movement 80%, fall damage 10×.
- **Modules:** mod-playerbots, mod-solo-lfg, mod-aoe-loot,
  mod-fireworks-on-level, mod-ale. Five modules, all tracking
  upstream HEAD (no pins). Same drift policy as beta/release.
- **Infrastructure:** shares source-beta with release/beta (same
  compile, same schema), shares the MySQL instance on port 3307,
  but lives in suffixed databases (`acore_world_vanilla`,
  `acore_characters_vanilla`, etc.) so coexistence with a running
  release server works without standing up a second MySQL. Network
  ports 4364 (auth) / 4464 (worldserver). See 148's Database
  Isolation Policy for the rationale.

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
**Resolved 2026-05-19:**

The modules directory at the project root **shares its name with the
source directory it backs**. Since release and beta both compile from
`source-beta/`, both profiles use `modules-beta/`. There is no
`modules-release/` — that directory was a vestige from when release
was wow-chat-1 with different modules from beta. **Deleted 2026-05-19**
in the same commit that updated `scripts/install` to point release at
`modules-beta`.

- alpha   → uses `source-alpha/modules/` directly (no project-root
            modules dir; alpha's era predates the symlink mechanism)
- release → `modules-beta/`  (same as beta — same source, same modules)
- beta    → `modules-beta/`  (canonical)

**Why not `modules-shared/`?** The shared-with-which-source link is
the load-bearing fact. Naming the directory after the source it backs
keeps the relationship visible — `modules-beta/` says "this is the
modules tree that compiles against `source-beta/`." A name like
`modules-shared/` hides what it's shared *with*.

**Why not symlink `modules-release/` → `modules-beta/`?** Symlinks
preserve the misleading name. Better to delete the misleading name
outright. Done.

### Implementation note (landed 2026-05-19)

The cleanup happened in one commit during the B020 rebuild prep,
not deferred to after the rebuild. Audit before deletion found that
`modules-release/mod-playerbots/` had a corrupted working-tree state
(massive accidental deletion in `RandomPlayerbotMgr.cpp`, almost
certainly from a botched `unapply_patches_begin` in a prior session).
The corrupted file was reverted to its committed state, equivalence
with `modules-beta/mod-playerbots/` confirmed, and only then was
`modules-release/` deleted. The `modules-release/` tree was also
missing `mod-ale/` entirely, which release profile needs per the
PROFILE_MODULES declaration — so the cleanup also fixed an
unrecognized brokenness that would have made release builds fail.

## Source Tree Is A Build Artifact — The Fourth-Path Design

**Codified 2026-05-19** following observation that both `source-beta/`
and `modules-beta/` had been accumulating drift, residue, and divergent
module versions. The root cause: both trees were doing the same job
(vendoring module source code), so neither had clear authority.

### The principle

> Any commit that modifies the source-code of the server or its
> modules should be written as a **patch**, not as raw edits to the
> source tree, which is treated like a build artifact.

Concretely:

- **`source-beta/`, `source-alpha/`** — entire source trees. Cloned
  from upstream by `scripts/redownload-source`. **Build artifacts.**
  Already `.gitignored` (line 17, pattern `source*/`). Never tracked,
  never committed. Always reconstructable from clone + patches.

- **`libs/`, `build*/`, `installed-files-*/bin,lib,include,share/`**
  — all build artifacts. Already `.gitignored`. Never tracked.

- **`modules-beta/`** — **THE RECIPE DIRECTORY**, tracked. Under the
  fourth-path design, this is *not* where vendored module source
  lives. It contains the *instructions* for downloading and configuring
  the modules:
  - Per-module clone scripts (`get-mod-ale.sh` etc., or one unified
    `clone-modules.sh`) that fetch each module from upstream at a
    pinned commit
  - Overlay files / patches specific to each module's setup
  - Possibly a manifest declaring exactly which commits to pin

- **`patches/B###-*.sh`** — source-code patches applied during
  PHASE_BEGIN, reverted post-build. The canonical place for "we want
  this change to the source." Already tracked, working as intended.

### Why this design works

- **Drift becomes impossible.** Source trees are regenerated; there's
  nothing to drift. Module versions are pinned in one place (the
  recipe). Customizations are one-way (patches modify regenerable
  source; reverts restore baseline).
- **Reproducibility is automatic.** `scripts/redownload-source` +
  `scripts/compile` produces an identical build for the same
  recipe + patch state.
- **Authority is clear.** The recipe directory says what *should* be
  there. The build artifact is what *is* there transiently. No
  question of "which tree is canonical" — only one tree has authority.

### What the refactor would touch

To convert from the current muddled state to the fourth-path design:

**Phase A — Strip vendored source from `modules-beta/`:**
- Remove the actual cloned module source dirs (`modules-beta/mod-ale/`,
  `modules-beta/mod-aoe-loot/`, `modules-beta/mod-grownup/`,
  `modules-beta/mod-playerbots/`).
- These are vendored copies that drift from upstream and from
  `source-beta/modules/`. Under the new design they shouldn't be here.
- The currently-tracked top-level files (`CMakeLists.txt`,
  `ModulesLoader.cpp.in.cmake`, etc.) are AzerothCore's module-loader
  template files; check whether they're really our customization or
  just upstream copies. Keep or replace accordingly.

**Phase B — Reuse the existing manifest arrays:**

The "manifest" doesn't need to be a new file format — `scripts/install`
already declares it via three Bash associative arrays:

- `MODULE_REPOS[mod-name]` → upstream URL (the recipe)
- `PROFILE_MODULES[profile]` → which modules belong to which profile
- `PROFILE_MODULE_COMMITS[profile:mod-name]` → optional commit pin

This IS the manifest. No duplication needed. The fourth-path design
just makes explicit what these arrays were always supposed to do.

**Pinning policy:**
- `release` and `beta` → leave `PROFILE_MODULE_COMMITS` empty for each
  module. Both tracks track upstream HEAD. The convention is "latest
  working code", consistent with release being "the most up-to-date"
  per the 136 canonical model.
- `alpha` → fill `PROFILE_MODULE_COMMITS[alpha:mod-X]` with a specific
  commit hash for any module that needs era-pinning. Alpha is the
  holiday relic, and its module commits should be frozen at a date
  that matches the alpha-era AzerothCore source.

**Phase C — Update `scripts/redownload-source`:**
- Reads the manifest in `modules-beta/`.
- Clones AzerothCore into `source-beta/` (already does this).
- For each module in the profile's set, clones it into
  `source-beta/modules/<module-name>/` at the pinned commit.
- Idempotent: if the right commit is already checked out, skip the
  clone.

**Phase D — Remove `scripts/install:update_modules_symlink`:**
- No more symlink swap. Modules go directly into
  `source-beta/modules/` via the clone recipe. The function
  disappears entirely.
- The case-switch we currently maintain (`release|beta` → `modules-beta`,
  `alpha` → return) becomes obsolete.

**Phase E — Patch system unchanged but better-grounded:**
- B-patches still apply to `source-beta/modules/<mod>/` at build time.
- Unapply still happens post-build. If unapply fails, the next
  `redownload-source` will clean things up by re-cloning at the
  pinned commit.
- The residue-from-failed-unapply problem becomes self-healing
  (every redownload restores baseline).

**Phase F — Documentation:**
- Update `docs/patches/patch-registry.md` to explicitly state that
  source trees are build artifacts and patches operate on
  regenerable source.
- Update CLAUDE.md's "Current Development State" section to describe
  the build/recipe/patch separation.

### Status

The principle is committed-to. The refactor itself is **not scheduled**
— it's substantial work and the current setup compiles. Recording the
design here so future work has a target.

When the refactor lands, this issue 136 gets the implementation note
and the pre-fourth-path remarks above become historical context.

### Fourth-Path Implementation Note (landed 2026-05-19)

The refactor went in shortly after the design was codified. The pieces
were smaller than expected because most of the recipe machinery
already existed in `scripts/install` — only two things needed
removing:

- **`update_modules_symlink` function and its call site in
  `scripts/install`** — gone. Modules are cloned directly into
  `source-beta/modules/` from upstream via the existing module-clone
  loop (lines 238-260 of `scripts/install`, which iterates
  `PROFILE_MODULES[$PROFILE]` and looks up each in `MODULE_REPOS`).
  No symlink swap is needed because the destination is the build
  artifact, not a tracked dir.

- **`modules-beta/` directory** — deleted (`git rm`). It had been
  vendoring module source as gitlinks (`mod-ale`, `mod-aoe-loot`,
  `mod-grownup`, `mod-playerbots`) plus AzerothCore's module-loader
  template files. All four module checkouts were verified clean (no
  local customizations beyond the patch-system's domain) before
  deletion. The module-loader template files arrive with the
  AzerothCore clone so they don't need their own home.

The manifest now lives entirely in `scripts/install`:

- `MODULE_REPOS` (URL per module)
- `PROFILE_MODULES` (which modules each profile uses)
- `PROFILE_MODULE_COMMITS` (commit pinning — currently only used for
  `release:mod-eluna`, will be the home for alpha's era-pinning when
  alpha modules need it)

The patch system (`patches/B###-*.sh` plus the `PHASE_BEGIN_PATCHES`
array) continues to be the canonical place for source-code
customizations. Combined, the install script + patch system are the
complete recipe — nothing else is needed.

`source-beta/` and `source-alpha/` remain gitignored build artifacts.
Drift in them is no longer a concern because they're regenerable from
a single command (`scripts/redownload-source` + `scripts/install`).

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
