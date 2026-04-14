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

# {{{ Profile-specific patch lists
# PHASE_BEGIN patches (pre-compile source modifications)
declare -A PHASE_BEGIN_PATCHES=(
    ["release"]=""                                      # Vanilla, no patches
    ["beta"]="B001 B002 B003 B004 B005 B006 B007 B008"  # All experimental patches
    ["alpha"]="B001 B004"                               # Minimal compatibility patches
)

# PHASE_END patches (post-compile setup: configs, symlinks, database)
declare -A PHASE_END_PATCHES=(
    ["release"]="E004 E006"              # Logs + configs (minimal)
    ["beta"]="E001 E004 E005 E006"       # Lua symlinks + DK stats + logs + configs
    ["alpha"]="E004 E006"                # Logs + configs (same as release)
)
# }}}

# {{{ apply_patches_begin
# PHASE_BEGIN: Pre-compile source fixes
# Run after clone/update, before cmake
apply_patches_begin() {
    local patches="${PHASE_BEGIN_PATCHES[$PROFILE]:-}"

    if [[ -z "${patches}" ]]; then
        echo ""
        echo "PHASE_BEGIN: No patches for profile '${PROFILE}'"
        return 0
    fi

    echo ""
    echo "Applying PHASE_BEGIN patches for profile '${PROFILE}'..."
    for patch_id in ${patches}; do
        # Find the patch function (e.g., patch_B001_aoe_loot_item_namespace)
        local patch_func=$(declare -F | grep "^declare -f patch_${patch_id}_" | sed 's/declare -f //')
        if [[ -n "${patch_func}" ]]; then
            ${patch_func}
            echo "  [${patch_id}] Applied: ${patch_func}"
        else
            echo "  [${patch_id}] WARNING: No function found for patch ${patch_id}"
        fi
    done
}
# }}}

# {{{ unapply_patches_begin
# Reverse all PHASE_BEGIN patches
# Called after build completes (success or failure) to keep source clean
unapply_patches_begin() {
    local patches="${PHASE_BEGIN_PATCHES[$PROFILE]:-}"

    if [[ -z "${patches}" ]]; then
        return 0
    fi

    echo ""
    echo "Reverting PHASE_BEGIN patches for profile '${PROFILE}'..."
    for patch_id in ${patches}; do
        local unpatch_func=$(declare -F | grep "^declare -f unpatch_${patch_id}_" | sed 's/declare -f //')
        if [[ -n "${unpatch_func}" ]]; then
            ${unpatch_func}
            echo "  [${patch_id}] Reverted"
        fi
    done
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

# {{{ apply_patches_end
# PHASE_END: Post-compile setup (config files, symlinks, database)
# Run after successful build and atomic swap
apply_patches_end() {
    local patches="${PHASE_END_PATCHES[$PROFILE]:-}"

    if [[ -z "${patches}" ]]; then
        echo ""
        echo "PHASE_END: No patches for profile '${PROFILE}'"
        return 0
    fi

    echo ""
    echo "Applying PHASE_END patches for profile '${PROFILE}'..."
    for patch_id in ${patches}; do
        # Find the patch function (e.g., patch_E001_lua_script_symlinks)
        local patch_func=$(declare -F | grep "^declare -f patch_${patch_id}_" | sed 's/declare -f //')
        if [[ -n "${patch_func}" ]]; then
            ${patch_func}
        else
            echo "  [${patch_id}] WARNING: No function found for patch ${patch_id}"
        fi
    done
    echo "  PHASE_END complete"
}
# }}}

# {{{ unapply_patches_end
# Reverse all PHASE_END patches (remove configs, symlinks, database entries)
# Used by apply-patches --revert
unapply_patches_end() {
    local patches="${PHASE_END_PATCHES[$PROFILE]:-}"

    if [[ -z "${patches}" ]]; then
        echo ""
        echo "PHASE_END: No patches to revert for profile '${PROFILE}'"
        return 0
    fi

    echo ""
    echo "Reverting PHASE_END patches for profile '${PROFILE}'..."
    for patch_id in ${patches}; do
        local unpatch_func=$(declare -F | grep "^declare -f unpatch_${patch_id}_" | sed 's/declare -f //')
        if [[ -n "${unpatch_func}" ]]; then
            ${unpatch_func}
        else
            echo "  [${patch_id}] No unpatch function (skipping)"
        fi
    done
    echo "  PHASE_END revert complete"
}
# }}}
