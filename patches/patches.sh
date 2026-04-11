#!/usr/bin/env bash
# patches.sh - Load all patch files and provide apply/unapply functions
# Sourced by scripts/azerothcore
#
# Each patch file defines:
#   patch_B00X_name()   - Apply the patch
#   unpatch_B00X_name() - Reverse the patch
#
# Both functions must be idempotent (safe to run multiple times)

# Get directory containing this script
PATCHES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all B### patch files
for patch_file in "${PATCHES_DIR}"/B[0-9][0-9][0-9]-*.sh; do
    [[ -f "${patch_file}" ]] && source "${patch_file}"
done

# {{{ apply_patches_begin
# PHASE_BEGIN: Pre-compile source fixes
# Run after clone/update, before cmake
# DISABLED: Building vanilla baseline first
apply_patches_begin() {
    echo ""
    echo "PHASE_BEGIN patches DISABLED (vanilla baseline mode)"
}
# }}}

# {{{ unapply_patches_begin
# Reverse all PHASE_BEGIN patches
# Called after build completes (success or failure) to keep source clean
# DISABLED: No patches to revert in vanilla mode
unapply_patches_begin() {
    echo ""
    echo "PHASE_BEGIN patches DISABLED (nothing to revert)"
}
# }}}

# {{{ patches_need_applying
# Check if any PHASE_BEGIN patches would modify source
# Returns 0 (true) if patches need applying, 1 (false) if all applied
patches_need_applying() {
    local FILE

    # B001: aoe-loot item namespace
    FILE="${AC_CODE_DIR}/modules/mod-aoe-loot/src/aoe_loot.cpp"
    if [[ -f "${FILE}" ]] && grep -q "^[[:space:]]*Item\* pItem = player->GetItemByGuid" "${FILE}"; then
        return 0
    fi

    # B002: playerbots ALE login hook
    FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp"
    local CMAKE_FILE="${AC_CODE_DIR}/modules/mod-playerbots/mod-playerbots.cmake"
    if [[ -f "${FILE}" ]] && ! grep -q "sALE->OnLogin(bot)" "${FILE}"; then
        return 0
    fi
    if [[ -f "${FILE}" ]] && { [[ ! -f "${CMAKE_FILE}" ]] || ! grep -q "MOD_ALE_PATH" "${CMAKE_FILE}"; }; then
        return 0
    fi

    # B003: ALE gameobject wildcard
    FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/LuaEngine.cpp"
    if [[ -f "${FILE}" ]] && ! grep -q "entry != 0 && !eObjectMgr->GetGameObjectTemplate" "${FILE}"; then
        return 0
    fi

    # B005: Accuracy level cap
    FILE="${AC_CODE_DIR}/src/server/game/Entities/Unit/Unit.h"
    if [[ -f "${FILE}" ]] && ! grep -q "ACCURACY_LEVEL_CAP" "${FILE}"; then
        return 0
    fi

    # B006: ALE sell item hook
    FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/Hooks.h"
    if [[ -f "${FILE}" ]] && ! grep -q "PLAYER_EVENT_ON_SELL_ITEM" "${FILE}"; then
        return 0
    fi

    # B007: ALE unit methods
    FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/methods/UnitMethods.h"
    if [[ -f "${FILE}" ]] && ! grep -q "int SetWalk" "${FILE}"; then
        return 0
    fi

    # B008: mod-talent-bonus
    if [[ -d "${DIR}/modules/mod-talent-bonus" ]] && [[ ! -d "${AC_CODE_DIR}/modules/mod-talent-bonus" ]]; then
        return 0
    fi

    return 1  # All patches already applied
}
# }}}
