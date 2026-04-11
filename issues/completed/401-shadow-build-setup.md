# 401 - Shadow Build Setup

## Status: Will Not Implement
- Created: 2026-04-09
- Closed: 2026-04-11
- Parent: 400-release-to-beta-transition
- Phase: Foundation
- Priority: N/A
- **Superseded by:** 327-atomic-shadow-builds (implemented)

## Current Behavior

Beta branch has accumulated patches that interact in complex ways.
Build failures are difficult to diagnose due to layered changes.

## Intended Behavior

Create isolated "shadow" worktree from release branch to rebuild cleanly:
- Fresh source clone
- Patches applied one-by-one
- Each step tested before proceeding
- Clear documentation of what works

## Implementation Steps

1. [ ] Create git worktree from release branch
   ```bash
   git worktree add ../wow-chat-2026-shadow release
   ```

2. [ ] Copy necessary files not in git
   - mysql/ directory (if not rebuilding MySQL)
   - config/ profiles
   - Any local secrets

3. [ ] Verify clean build from release
   ```bash
   cd ../wow-chat-2026-shadow
   ./scripts/azerothcore update
   ```

4. [ ] Document any issues with release build

## Success Criteria

- Shadow worktree exists at ../wow-chat-2026-shadow
- Clean build completes without patches
- Server starts from shadow build
- Ready to apply patches incrementally

## Notes

- Shadow build preserves original beta for reference
- Can diff between shadow and beta to find differences
- Once shadow is complete, can replace beta

## Closure Rationale (2026-04-11)

This proposal for git worktree shadow builds is unnecessary given the existing shadow build directory system.

**What already exists (issue 327, implemented):**
- `build-shadow/` and `installed-files-shadow/` directories
- Atomic swap on successful build
- Failed builds preserved for debugging
- Old binaries remain working during compilation

**What this issue proposed:**
- Git worktree at `../wow-chat-2026-shadow`
- Separate working directory for clean rebuild testing
- Isolation from main working tree

**Why we don't need both:**
1. **Complexity** - Two different "shadow" concepts would be confusing
2. **Atomic builds already work** - Issue 327's shadow directories provide safe compilation
3. **Profile system handles isolation** - Can test different configs via profiles
4. **Worktree overhead** - Maintaining parallel git state adds cognitive load
5. **Disk space** - Another full source clone when atomic swap already prevents breakage

**If we need clean rebuild testing:**
Just use the existing profile system:
```bash
# Clean test in release profile
echo "release" > .current-profile
./scripts/azerothcore update  # Fresh build, no experimental patches
```

**Status:** Will not implement. Issue 327's atomic shadow builds solve the safety problem without git worktree complexity.
