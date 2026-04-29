# 115 - Shadow Build Setup (Will Not Implement)

**Phase:** 1 (Foundation & Tooling)
**Effect:** N/A - Proposal declined, existing atomic builds sufficient
**Status:** Will Not Implement (2026-04-11)

---

## The Proposal

Create a git worktree "shadow" copy of the repository to test clean builds in isolation. Beta had accumulated patches interacting in complex ways; a fresh worktree would allow rebuilding from scratch without affecting the main working tree.

**Proposed structure:**
```
../wow-chat-2026-shadow/       # Git worktree from release branch
├── source/                    # Fresh clone
├── build/                     # Clean build
└── ...
```

**Proposed workflow:**
```bash
# Create shadow worktree
git worktree add ../wow-chat-2026-shadow release

# Test clean build
cd ../wow-chat-2026-shadow
./scripts/azerothcore update

# Apply patches one by one, testing each
# Once working, can replace main beta
```

---

## Why It Was Proposed

**The problem being solved:**

Beta branch had accumulated many patches. When builds failed, it was unclear which patch caused the failure. A fresh worktree would allow:
- Clean baseline from known-good release
- Patches applied incrementally
- Each step tested before proceeding
- Clear documentation of what works

**The appeal:**
- Isolation from main working tree
- Can diff between shadow and beta
- Doesn't risk current development state
- Git-native solution (worktrees)

---

## Why It Was Declined

### Atomic Shadow Builds Already Exist

Issue 327 implemented a simpler solution using shadow *directories* (not worktrees):

```
wow-chat-2026/
├── build-beta/              # Normal build
├── build-shadow/            # Compilation happens here
├── installed-files-beta/    # Normal install
└── installed-files-shadow/  # Install during build
```

**How it works:**
1. Compile to `build-shadow/`
2. Install to `installed-files-shadow/`
3. If successful, atomic swap to main directories
4. If failed, shadow preserved for debugging
5. Old binaries remain working during compilation

### Worktree Adds Unnecessary Complexity

**Git worktree overhead:**
- Parallel git state to maintain
- Another full source clone (disk space)
- Cognitive load of two working trees
- Branch state can diverge unexpectedly

**Shadow directories overhead:**
- Just extra build/install directories
- No git complexity
- Same source, different output paths
- Already implemented and working

### Profile System Handles Isolation

If we need truly isolated testing:
```bash
# Use release profile for clean test
echo "release" > .current-profile
./scripts/azerothcore update  # Builds release, no experimental patches
```

No worktree needed. Profiles already provide the isolation.

### The Real Problem Was Patch Tracking

The original complaint was "patches interact in complex ways." The solution isn't more build isolation - it's better patch documentation:
- Issue 334: Patch system improvements
- Issue 326: Patch staleness detection
- `docs/patches/patch-registry.md`: Tracks all patches

With proper patch documentation, we know what's applied and can debug systematically.

---

## What Works Instead

**For safe compilation:**
- Shadow directories (issue 327)
- Atomic swap on success
- Failed builds don't break running server

**For testing different configurations:**
- Profile system (alpha/beta/release)
- Each profile has own build artifacts
- Switch without worktree complexity

**For debugging patch interactions:**
- Patch registry documentation
- Staleness detection (issue 326)
- Apply patches incrementally with `--force`

---

## Lessons Learned

### Solve the Actual Problem

The proposal addressed symptoms (messy builds) rather than cause (patch tracking). Better documentation and detection solved the real problem without new infrastructure.

**Lesson:** Ask "what's the root cause?" before adding complexity.

### Git Isn't Always the Answer

Git worktrees are powerful, but they add cognitive overhead. For build isolation, simpler solutions (shadow directories) suffice.

**Lesson:** Use the simplest solution that works.

### Multiple Solutions to Same Problem

Three approaches all address "safe experimentation":
1. Git worktrees (proposed here, rejected)
2. Shadow directories (issue 327, implemented)
3. Profile system (existing, refined)

Shadow directories won because they're lightest weight and integrate with existing build system.

**Lesson:** Compare multiple solutions before implementing.

---

## The Decision

**Don't add git worktree complexity. Use existing shadow build system.**

Issue 327's atomic shadow builds solve the safety problem without git worktree overhead. If we need isolation beyond that, the profile system provides it.

---

## Related Phase 1 Issues

- 108 - adaptive-build-parallelism (build system)
- 109 - incremental-rebuild-detection (smart rebuilding)
- 114 - remove-profile-system (also declined, profile value)
- 112 - patch-staleness-detection (solves patch tracking)

---

## Phase 1 Contribution

This issue contributes to **Phase 1: Foundation & Tooling** by documenting:
> "Why git worktrees aren't used for build isolation"

Future developers might think "git worktrees would solve this!" This issue explains:
1. The problem that prompted the proposal
2. Why worktrees seemed appealing
3. Why simpler solutions were preferred
4. What actually solves the problem

The best infrastructure is often the infrastructure you don't add.
