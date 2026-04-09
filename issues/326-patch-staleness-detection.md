# 326 - Patch Staleness Detection

## Status
- Created: 2026-04-08
- Phase: 2
- Priority: High

## Current Behavior

When running `./scripts/azerothcore update`:

1. Script checks if upstream (Core + modules) has changed
2. If no upstream changes AND worldserver exists, exits early with "Everything up-to-date"
3. `apply_patches_begin` is only called AFTER this check

This means:
- New patches added to the orchestrator (B002, B003, etc.) are never applied
- User adds patch, runs update, nothing happens
- Source code remains unpatched, features don't work

```bash
# Lines 1410-1420 in scripts/azerothcore
if [[ "${needs_rebuild}" == false && -f worldserver ]]; then
    echo "Everything up-to-date, no rebuild needed."
    return 0   # EXIT - patches never applied
fi

apply_patches_begin  # UNREACHABLE when upstream unchanged
```

## Intended Behavior

The update command should:
1. Check upstream changes (existing)
2. Check if any patches would modify source (NEW)
3. Check if patched source files are newer than binary (NEW)
4. If ANY of the above, proceed with patch + rebuild
5. Exit early only if upstream unchanged AND patches applied AND binary up-to-date

## Suggested Implementation

### Add `patches_need_applying` function

Run each patch's idempotent check to determine if it would make changes:

```bash
# -- {{{ patches_need_applying
# Check if any PHASE_BEGIN patches would modify source
# Returns 0 (true) if patches need applying, 1 (false) if all applied
patches_need_applying() {
    local FILE

    # B001: aoe-loot item namespace
    FILE="${AC_CODE_DIR}/modules/mod-aoe-loot/src/aoe_loot.cpp"
    if [[ -f "${FILE}" ]] && grep -q "^[[:space:]]*Item\* pItem = player->GetItemByGuid" "${FILE}"; then
        return 0  # B001 needs applying
    fi

    # B002: playerbots ALE login hook
    FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp"
    if [[ -f "${FILE}" ]] && ! grep -q "sALE->OnLogin(bot)" "${FILE}"; then
        return 0  # B002 needs applying
    fi

    # B003: ALE gameobject wildcard
    FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/LuaEngine.cpp"
    if [[ -f "${FILE}" ]] && ! grep -q "entry != 0 && !eObjectMgr->GetGameObjectTemplate" "${FILE}"; then
        return 0  # B003 needs applying
    fi

    return 1  # All patches already applied
}
# -- }}}
```

### Update `cmd_update` flow

```bash
# After upstream checks, before early exit:

# Check if patches need applying
if patches_need_applying; then
    echo "Patches pending - rebuild required"
    needs_rebuild=true
fi

# THEN do the early exit check
if [[ "${needs_rebuild}" == false && -f "${INSTALL_DIR}/bin/worldserver" ]]; then
    echo "Everything up-to-date, no rebuild needed."
    return 0
fi
```

### Add source-newer-than-binary check

Catches the case where patches were applied but binary wasn't rebuilt:

```bash
# Check if patched source files are newer than binary
if [[ "${needs_rebuild}" == false && -f "${INSTALL_DIR}/bin/worldserver" ]]; then
    local BINARY_TIME=$(stat -c %Y "${INSTALL_DIR}/bin/worldserver")

    # Check each patched source file
    local B002_FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp"
    if [[ -f "${B002_FILE}" ]]; then
        local B002_TIME=$(stat -c %Y "${B002_FILE}")
        if [[ "${B002_TIME}" -gt "${BINARY_TIME}" ]]; then
            echo "Source newer than binary - rebuild required"
            needs_rebuild=true
        fi
    fi
    # ... similar for B003
fi
```

## Affected Files

- `scripts/azerothcore` - cmd_update function, new patches_need_applying function

## Maintenance Note

When adding new patches (B004, etc.), also add their idempotent check to `patches_need_applying`.
This ensures the staleness detection stays current with the patch registry.

## Related

- B001: aoe-loot-item-namespace
- B002: playerbots-ale-login-hook (issue 324)
- B003: ale-gameobject-wildcard (issue 325)
- docs/patches/patch-registry.md
