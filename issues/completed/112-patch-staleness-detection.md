# 112 - Patch Staleness Detection

**Phase:** 1 (Foundation & Tooling)
**Effect:** Build system detects when patches need applying, prevents silent patch skipping
**Status:** Completed (2026-04-11)

---

## The Effect

When running `./scripts/azerothcore update`, the script now checks whether patches have been applied to source files. If a new patch was added to the orchestrator but hasn't been applied yet, the build proceeds even when upstream is unchanged.

No more "Everything up-to-date" when patches are pending.

---

## What This Solved

### Before (Patches Skipped Silently)

**The problem:**
```bash
$ ./scripts/azerothcore update

Checking for upstream changes...
No changes detected.
Everything up-to-date, no rebuild needed.  # EXIT

# But wait - we just added patch B003!
# Source was never modified.
# Feature doesn't work.
```

**Why it happened:**

The update script checked:
1. Has upstream (Core + modules) changed?
2. Does worldserver binary exist?

If both answered "no changes" and "yes exists", it exited early. The `apply_patches_begin` function was only called AFTER this check - meaning it was unreachable when upstream was unchanged.

**Impact:**
- Added new patch → ran update → nothing happened
- Source remained unpatched
- Features depending on patches didn't work
- User confused: "I added the patch, why isn't it working?"

### After (Staleness Detection)

**Three checks before early exit:**
1. Has upstream changed? (existing)
2. Would any patch modify source? (NEW)
3. Is patched source newer than binary? (NEW)

```bash
$ ./scripts/azerothcore update

Checking for upstream changes...
No changes detected.
Checking patch status...
Patches pending - rebuild required

Applying patches...
[B003] ale-gameobject-wildcard - Applying patch
Building...
```

**Result:**
- New patches always detected
- Rebuild triggered when patches pending
- Source timestamp vs binary timestamp catches edge cases
- "Everything up-to-date" only when truly up-to-date

---

## Implementation

### The `patches_need_applying` Function

Each patch has an idempotent check - a grep pattern that detects whether the patch has been applied:

```bash
# -- {{{ patches_need_applying
# Check if any PHASE_BEGIN patches would modify source
# Returns 0 (true) if patches need applying, 1 (false) if all applied
patches_need_applying() {
    local FILE

    # B001: aoe-loot item namespace
    FILE="${AC_CODE_DIR}/modules/mod-aoe-loot/src/aoe_loot.cpp"
    if [[ -f "${FILE}" ]] && grep -q "^[[:space:]]*Item\* pItem = player->GetItemByGuid" "${FILE}"; then
        return 0  # Old pattern found, B001 needs applying
    fi

    # B002: playerbots ALE login hook
    FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp"
    if [[ -f "${FILE}" ]] && ! grep -q "sALE->OnLogin(bot)" "${FILE}"; then
        return 0  # Hook call missing, B002 needs applying
    fi

    # B003: ALE gameobject wildcard
    FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/LuaEngine.cpp"
    if [[ -f "${FILE}" ]] && ! grep -q "entry != 0 && !eObjectMgr->GetGameObjectTemplate" "${FILE}"; then
        return 0  # Wildcard check missing, B003 needs applying
    fi

    # ... similar checks for B004-B008 ...

    return 1  # All patches already applied
}
# -- }}}
```

**Detection logic per patch:**

| Patch | What It Looks For | If Found |
|-------|-------------------|----------|
| B001 | Old `Item* pItem = player->GetItemByGuid` pattern | Needs applying |
| B002 | Missing `sALE->OnLogin(bot)` call | Needs applying |
| B003 | Missing gameobject wildcard check | Needs applying |
| B004 | Missing warning fix in BudgetValues.cpp | Needs applying |
| B005 | Missing `#define ACCURACY_LEVEL_CAP 3` | Needs applying |
| B006 | Missing `PLAYER_EVENT_ON_SELL_ITEM` hook | Needs applying |
| B007 | Missing `int SetWalk` in UnitMethods.h | Needs applying |
| B008 | mod-talent-bonus module not linked | Needs applying |

### Integration in `cmd_update`

```bash
# After upstream checks, before early exit:

# Check if patches need applying
if patches_need_applying; then
    echo "Patches pending - rebuild required"
    needs_rebuild=true
fi

# Check if source newer than binary (edge case)
if [[ "${needs_rebuild}" == false && -f "${INSTALL_DIR}/bin/worldserver" ]]; then
    local BINARY_TIME=$(stat -c %Y "${INSTALL_DIR}/bin/worldserver")
    # Compare each patched source file timestamp...
fi

# THEN do early exit check
if [[ "${needs_rebuild}" == false && -f "${INSTALL_DIR}/bin/worldserver" ]]; then
    echo "Everything up-to-date, no rebuild needed."
    return 0
fi
```

---

## Why This Matters

**Patch System Reliability**

The patch system is central to how we customize AzerothCore. Without staleness detection:
- Adding patches was error-prone
- Users had to remember to run `--force`
- Silent failures led to "it doesn't work" debugging sessions
- Trust in the build system eroded

With staleness detection:
- Patches are applied automatically
- No manual intervention required
- Build system is self-correcting
- Users can trust `update` does the right thing

**Idempotent Design**

Each patch check is idempotent - running it multiple times produces the same result. The grep patterns detect the *state* of the source, not the *history* of operations. This means:
- Works regardless of how source got that way
- Detects manual edits that conflict with patches
- Self-healing if patch was partially applied
- No state file to get out of sync

**Maintainability**

Adding a new patch (B009, B010, etc.) requires:
1. Add patch function to `patches/patches.sh`
2. Add detection check to `patches_need_applying()`

The check documents what the patch does - if you can't write a detection check, you don't understand the patch well enough.

---

## Related Phase 1 Issues

- 108 - adaptive-build-parallelism (build optimization)
- 109 - incremental-rebuild-detection (rebuild triggering)
- 119 - config-value-orchestrator (config-time patches)

---

## Lessons Learned

### Early Exit Is Dangerous

The original code had a reasonable optimization: don't rebuild if nothing changed. But the definition of "nothing changed" was too narrow - it only checked upstream, not local patches.

**Lesson:** Before adding early exits, enumerate ALL conditions that should prevent exit.

### Grep Patterns as Documentation

Each detection grep pattern effectively documents what the patch does:
- B001 changes `Item*` to `::Item*`
- B002 adds `sALE->OnLogin(bot)` call
- B003 adds gameobject entry validation

Reading `patches_need_applying()` tells you what all patches do without reading the patches themselves.

**Lesson:** Detection checks can serve as documentation.

### Dual Detection

Two mechanisms catch staleness:
1. Semantic detection (grep for expected patterns)
2. Timestamp comparison (source newer than binary)

Either alone could miss cases. Together they're robust.

**Lesson:** When correctness matters, use multiple detection methods.

---

## Testing

```bash
# Verify function detects pending patches
$ source scripts/azerothcore && get_profile_paths && patches_need_applying
$ echo $?
0  # 0 = patches need applying (bash true)

# After all patches applied:
$ patches_need_applying
$ echo $?
1  # 1 = all patches applied (bash false)
```

---

## Files Modified

- `scripts/azerothcore` - lines 575-632 (patches_need_applying), line 1492 (integration)
- `patches/patches.sh` - All patch functions (B001-B008)

---

## Phase 1 Contribution

This issue enables **Phase 1: Foundation & Tooling** by ensuring:
> "The build system is reliable and self-correcting"

Developers need to trust their tools. When you add a patch and run update, it should apply. When you run update twice, it should be idempotent. When upstream changes conflict with patches, the build should detect it.

Patch staleness detection makes the build system trustworthy. Without trust, every "it doesn't work" bug starts with "did the patch apply?" Instead, we can assume patches applied and debug actual problems.
