# 403 - Incremental Patch Integration

## Status
- Created: 2026-04-09
- Parent: 400-release-to-beta-transition
- Phase: Foundation
- Priority: High

## Purpose

Apply patches one at a time, testing each before proceeding.
Document any issues and fixes for each patch.

## Patch Integration Order

Patches applied in dependency order. Each must pass before next.

### Group 1: Build Fixes (No Dependencies)

| Patch | Issue | Test | Status |
|-------|-------|------|--------|
| B001 | - | Compile succeeds | [ ] |
| B004 | 333 | Warnings reduced | [ ] |

### Group 2: ALE Extensions

| Patch | Issue | Test | Status |
|-------|-------|------|--------|
| B003 | 325 | Gameobject wildcard works | [ ] |
| B006 | 150 | Sell item hook fires | [ ] |
| B007 | 332 | Unit methods available | [ ] |

### Group 3: Cross-Module Integration

| Patch | Issue | Test | Status |
|-------|-------|------|--------|
| B002 | 324 | Bot login triggers Lua | [ ] |
| B005 | 156 | Hit/miss capped at ±3 | [ ] |
| B008 | 120 | Talent bonus validates | [ ] |

## Process for Each Patch

1. **Read patch documentation**
   - `docs/patches/{patch-name}.md`
   - Related issue file

2. **Apply patch**
   ```bash
   source patches/patches.sh
   patch_B00X_name
   ```

3. **Rebuild**
   ```bash
   ./scripts/azerothcore compile
   ```

4. **Test**
   - Start server
   - Verify feature works
   - Check for regressions

5. **Document**
   - Update this issue with results
   - Note any fixes needed
   - Commit if successful

6. **Proceed or rollback**
   - If works: continue to next patch
   - If fails: fix or rollback, document issue

## Integration Log

### B001 - AOE Loot Item Namespace
- Date:
- Result:
- Notes:

### B002 - Playerbots ALE Login Hook
- Date:
- Result:
- Notes:

### B003 - ALE Gameobject Wildcard
- Date:
- Result:
- Notes:

### B004 - Upstream Warning Fixes
- Date:
- Result:
- Notes:

### B005 - Accuracy Level Cap
- Date:
- Result:
- Notes:

### B006 - ALE Sell Item Hook
- Date:
- Result:
- Notes:

### B007 - ALE Unit Methods
- Date:
- Result:
- Notes:

### B008 - Mod Talent Bonus
- Date:
- Result:
- Notes:

## Success Criteria

- All 8 patches applied
- Server compiles with all patches
- Server runs with all patches
- Each feature tested and working
- Process documented for repeatability
