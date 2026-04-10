# 401 - Shadow Build Setup

## Status
- Created: 2026-04-09
- Parent: 400-release-to-beta-transition
- Phase: Foundation
- Priority: High

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
