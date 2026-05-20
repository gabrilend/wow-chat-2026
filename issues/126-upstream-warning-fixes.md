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

## -Werror Design Goal (2026-05-19)

The release build is now aiming for `-Werror` — warnings promoted to
errors in the compile flags. This is the design goal that governs all
warning work going forward.

**Rationale.** The user explicitly chose this over the alternative of
global `-Wno-...` suppression flags. The reasoning:

> "Yeah let's make that a design goal. It's okay if the patches drift —
> that's fine. We just have to update them every couple whenevers."

A clean compile under strict policy beats a relaxed policy that hides
drift between mod-ale / mod-playerbots and core AzerothCore. The
maintenance cost of per-warning B-patches is accepted as the price of
the signal `-Werror` provides.

**No category-wide suppression.** Don't add `-Wno-sign-compare`,
`-Wno-unused-parameter`, etc. — each warning needs an individual
B-patch that resolves it at the source (cast, parens, `(void)var;`,
default copy-assignment, etc.).

**Boost is the exception.** The 442 boost `unary_function` deprecation
warnings are in `libs/boost/...` — outside our patch surface. A
targeted `-Wno-deprecated-declarations` scoped to the boost include
path is acceptable. Upgrading the bundled boost to 1.81+ is the
preferred fix but blocked on packaging work.

### Current Warning B-Patch Inventory

| Patch | Warning category                | Status              |
|-------|---------------------------------|---------------------|
| B013  | logical-op-parentheses          | applied             |
| B014  | switch-enum-default             | applied             |
| B015  | implicit-float-conversion       | applied             |
| B016  | constructor-reorder             | applied (5th-fixed) |
| B017  | unused-variables                | applied (5th-fixed) |
| B018  | sign-compare                    | applied             |
| B019  | unused-parameter                | applied (3rd-fixed) |

Each patch entry has been validated against actual upstream by the
five rebuild attempts logged in `issues/208-ale-registry-corruption.md`.
Patches that broke (B011) or had over-broad selectors (B019, B017)
were either retired or narrowed.

### Order of Operations Toward -Werror

The flag itself can ONLY be enabled once warnings reach zero in the
release build. Otherwise the first warning fails compilation and no
further warnings can be observed. Sequence:

1. Compile to completion (or as far as it gets).
2. Inventory all warnings from `tmp/build-release.log`.
3. Group by category, write or extend a B-patch per category.
4. Recompile. Repeat from 2 until warnings = 0.
5. Add `-Werror` to the release CMake configuration (likely via a new
   B-patch or a CMake injection in `scripts/install`).
6. Lock in: any new warning that appears after upstream pulls now
   fails the build, forcing a patch update.

### Sustainable Drift Cadence

When upstream updates introduce new warnings or invalidate existing
sed targets, the workflow is:

1. Build fails with a new warning category, or sed mismatch.
2. Log the failure as a new attempt entry in 208 (or whatever issue
   is tracking the rebuild round).
3. Update the relevant B-patch with a defensive pattern (anchor on
   more context, skip `//` lines, etc.).
4. Reapply, recompile.

This is the "every couple whenevers" the user accepted as the price
of -Werror discipline.
