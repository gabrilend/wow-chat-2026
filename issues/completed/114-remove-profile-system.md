# 114 - Remove Profile System (Will Not Implement)

**Phase:** 1 (Foundation & Tooling)
**Effect:** N/A - Proposal declined, profile system retained
**Status:** Will Not Implement (2026-04-11)

---

## The Proposal

Replace the three-profile system (alpha, beta, release) with git branches. Instead of separate source directories per profile, use a single source directory and switch versions via `git checkout`.

**Proposed structure:**
```
wow-chat-2026/
├── source/              # Single clone, branch switching
├── build/               # Single build directory
├── installed-files/     # Single install directory
└── config/              # No profile subdirs
```

**Proposed workflow:**
```bash
# Switch to release
cd source/ && git checkout release
./scripts/azerothcore update --force

# Switch to beta
cd source/ && git checkout beta
./scripts/azerothcore update --force
```

---

## Why It Was Proposed

**Perceived problems with profiles:**
1. Complexity - Three sets of directories
2. Disk space - Multiple source clones (~2GB each)
3. Confusion - Profile vs git branch semantics overlap
4. Alpha unused - All alpha directories empty
5. Script complexity - Profile-aware code paths everywhere

**The appeal of simplification:**
- One source, one build, one install
- Git handles versioning (that's what git is for)
- Fewer directories to track
- Simpler `scripts/azerothcore`

---

## Why It Was Declined

### Profiles Solve a Different Problem

Git branches track *code history*. Profiles track *feature sets*.

**Git branches:** "What version of the code am I on?"
**Profiles:** "What features should be enabled in this build?"

These overlap but aren't identical. You can have:
- Same code version, different profiles (beta vs release both on playerbots branch)
- Different code versions, same profile concept (alpha on old Eluna, beta on new ALE)

### The Three Profiles Have Distinct Purposes

**Alpha (regression baseline):**
- Uses original wow-chat-1 codebase (Eluna, not ALE)
- Known-good fallback when beta breaks
- Proves features worked before changes
- Different source entirely (`source-alpha/`)

**Release (production-ready):**
- Bare playerbots, no experimental features
- Stable enough for actual play
- Minimal patches, maximum compatibility
- Uses `source-beta/` but different modules

**Beta (development):**
- All experimental features enabled
- Patches applied liberally
- Can break without consequence
- Primary development target

### Profile System Enables Isolation

With profiles, you can:
- Build beta while release serves players
- Compare behavior between profiles without rebuilding
- Roll back to alpha instantly (no recompile)
- Test the same Lua scripts against different binaries

With git branches only:
- Must rebuild on every switch
- Can't compare simultaneously
- Rollback requires compile time
- Risk breaking production while developing

### What We Built Instead

Issues 405/406 refined the profile system:
- Two source directories: `source-alpha/`, `source-beta/`
- Three profiles: alpha, release, beta
- File-based distinction: `*.alpha.lua`, `*.beta.lua`
- Module symlinks: `modules-beta/`, `modules-release/`

The profile system adds value, it's not legacy cruft.

---

## Lessons Learned

### Complexity Isn't Always Bad

The profile system looked complex. But it encoded real distinctions:
- Alpha = old codebase (regression safety)
- Release = production (user-facing stability)
- Beta = experimental (development freedom)

Removing profiles would collapse these into one, losing the ability to maintain multiple stable states.

**Lesson:** Before removing "complexity," understand what it enables.

### Git Branches ≠ Feature Flags

Branch switching requires rebuild. Profile switching doesn't (for release vs beta on same source).

Conflating version control with feature management creates unnecessary rebuild cycles.

**Lesson:** Use the right tool for each job.

### Unused ≠ Useless

Alpha directories were empty, but alpha's purpose (regression baseline) remained valid. Once we needed to debug "did this work before?", alpha became useful.

**Lesson:** Unused infrastructure isn't automatically removable.

---

## The Decision

**Keep profiles. Refine implementation.**

The profile system was refined (issues 405/406) rather than removed:
- Clearer separation between alpha and beta sources
- File-based feature selection (`.alpha.lua` vs `.beta.lua`)
- Module directories per profile
- Documented purpose for each profile

---

## Related Phase 1 Issues

- 108 - adaptive-build-parallelism (build system)
- 109 - incremental-rebuild-detection (profile-aware rebuilds)
- 115 - shadow-build-setup (also declined, similar reasoning)

---

## Preserved Information

For reference, the release profile tracks:
- Repository: `https://github.com/azerothcore/azerothcore-wotlk.git`
- Branch: `master`
- Commit: `a779cca9e3a3d673761d6bbe6d1c5d1f51c2f6f3` (June 27, 2023)
- Module: mod-eluna @ commit `1abf244`

This information preserved here in case the release profile is ever needed for comparison.

---

## Phase 1 Contribution

This issue contributes to **Phase 1: Foundation & Tooling** by documenting:
> "Why the profile system exists and why it was kept"

Understanding *why not* is as valuable as understanding *why*. Future developers seeing the profile system might ask "why is this so complicated?" This issue explains:
1. What simplification was proposed
2. Why it seemed appealing
3. Why it was declined
4. What problem profiles actually solve

Documentation of declined proposals prevents re-proposing the same idea and re-learning the same lessons.
