# 126 - Upstream Warning Fixes

## Status
- Created: 2026-04-09
- Phase: 3
- Priority: Low
- **IN PROGRESS**

## Current Behavior

Build produces ~1137 compiler warnings:
- 500: NextAction deprecated copy assignment (mod-playerbots)
- 442: boost unary_function deprecated (boost 1.74)
- 119: MovementActions.h signed/unsigned comparison (mod-playerbots)
- 40: HunterActions.h unused parameter (mod-playerbots)
- 13: ItemCountValue.h unused parameter (mod-playerbots)
- 12: PositionInfo deprecated copy assignment (mod-playerbots)
- 3: CraftData deprecated copy assignment (mod-playerbots)
- 3: UnitPosition deprecated copy assignment (mod-playerbots)
- 3: Arrow.h initializer order (mod-playerbots)
- 2: PlayerMethods.h signed/unsigned comparison (mod-ale)

All warnings are in upstream code (mod-playerbots, boost) or mod-ale.
No warnings in our custom Lua scripts or patches.

## Boost Version

Current: **1.74** (2020)
Required for unary_function fix: **1.81+** (2022)

Options:
1. Upgrade to boost 1.86+ (latest) - eliminates 442 warnings
2. Suppress via compiler flag `-Wno-deprecated-declarations`
3. Patch boost header directly (not recommended)

## Intended Behavior

Clean build with minimal warnings:
- All patchable warnings fixed (~695)
- Boost warnings suppressed via compiler flag (~442)
- Remaining scattered warnings optional cleanup later

## Implementation

See `docs/patches/upstream-warning-fixes.md` for:
- Detailed fix descriptions for each warning category
- Sed script for automated application
- CMake flag for boost warning suppression

## Categories

### High Impact (Single Fix, Many Warnings)

1. **NextAction copy assignment** (500 warnings)
   - File: `Action.h:20`
   - Fix: Add `operator=(const&) = default`

2. **MovementActions loop** (119 warnings)
   - File: `MovementActions.h:279`
   - Fix: Change `int i` to `uint32 i`

3. **Boost unary_function** (442 warnings)
   - File: `libs/boost/...`
   - Fix: CMake flag `-Wno-deprecated-declarations`

### Medium Impact

4. **HunterActions unused event** (40 warnings)
5. **ItemCountValue unused event** (13 warnings)
6. **PositionInfo copy assignment** (12 warnings)

### Low Impact

7. **CraftData copy assignment** (3)
8. **UnitPosition copy assignment** (3)
9. **Arrow.h initializer order** (3)
10. **PlayerMethods enum comparison** (2)

## Integration

Add to `scripts/azerothcore` as a new patch phase or integrate into existing phases.
Patch should be applied during PHASE_BEGIN before compilation.

## Verification

```bash
# Before
make -j$(nproc) 2>&1 | grep -c "warning:"
# Expected: ~1137

# After (no boost fix)
# Expected: ~442

# After (with boost CMake flag)
# Expected: 0
```

## Related Files

- `docs/patches/upstream-warning-fixes.md` - Complete patch documentation
- `docs/patches/patch-registry.md` - Patch index
- `tmp/build-beta.log` - Build log with warnings
- `issues/127-patch-system-improvements.md` - Patch system redesign (was 334)

## Notes

- These are cosmetic fixes - no runtime behavior changes
- Upstream modules may receive updates that override our fixes
- Consider submitting fixes upstream to mod-playerbots repository
- Currently relies on idempotent checks (grep before sed)
- See issue 334 for planned "clean source after build" workflow
