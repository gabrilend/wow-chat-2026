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
- `issues/400-release-to-beta-transition.md` (says release=wow-chat-1)
- `issues/405-profile-transition-system.md` (says release=vanilla)
- `issues/201-branch-based-azerothcore-versioning` (alpha modules wrong)

### Source-dir mapping (`scripts/authserver`, `scripts/worldserver`, `scripts/compile`)
Currently all three profiles map to `source-beta` for release and beta,
`source-alpha` for alpha. Verify this still matches the canonical model:
- alpha → `source-alpha` (pinned old AC) ✓
- release → `source-release` or `source-beta` (current AC) — **decide
  whether release and beta share a source dir or each get their own**
- beta → `source-beta` (current AC + dev) ✓

If release and beta share source, patches must be consistent between
both; if they diverge, separate dirs are clearer.

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
