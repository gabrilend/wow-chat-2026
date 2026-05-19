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

# Source all B### patch files (PHASE_BEGIN - source code modifications)
for patch_file in "${PATCHES_DIR}"/B[0-9][0-9][0-9]-*.sh; do
    [[ -f "${patch_file}" ]] && source "${patch_file}"
done

# Source E patches (PHASE_END - config files, symlinks, database)
if [[ -f "${PATCHES_DIR}/E-patches.sh" ]]; then
    source "${PATCHES_DIR}/E-patches.sh"
fi

# {{{ Profile-specific patch lists
# PHASE_BEGIN patches (pre-compile source modifications)
declare -A PHASE_BEGIN_PATCHES=(
    ["release"]="B004 B009 B010 B011 B012 B013 B014 B015 B016 B017 B018 B019 B020"  # warning fixes + mod-playerbots + mod-ale compat + ALE registry lock fix
    ["beta"]="B001 B002 B003 B004 B005 B006 B007 B008 B009 B010 B011 B012 B013 B014 B015 B016 B017 B018 B019 B020"  # All patches
    ["alpha"]="B001 B004"                                         # Minimal compatibility patches
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

# {{{ patch_needs_applying_XXXX
# Individual patch condition checks - return 0 if patch needs applying
patch_needs_applying_B001() {
    local FILE="${AC_CODE_DIR}/modules/mod-aoe-loot/src/aoe_loot.cpp"
    [[ -f "${FILE}" ]] && grep -q "^[[:space:]]*Item\* pItem = player->GetItemByGuid" "${FILE}"
}

patch_needs_applying_B002() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp"
    local CMAKE_FILE="${AC_CODE_DIR}/modules/mod-playerbots/mod-playerbots.cmake"
    if [[ -f "${FILE}" ]] && ! grep -q "sALE->OnLogin(bot)" "${FILE}"; then
        return 0
    fi
    if [[ -f "${FILE}" ]] && { [[ ! -f "${CMAKE_FILE}" ]] || ! grep -q "MOD_ALE_PATH" "${CMAKE_FILE}"; }; then
        return 0
    fi
    return 1
}

patch_needs_applying_B003() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/LuaEngine.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "entry != 0 && !eObjectMgr->GetGameObjectTemplate" "${FILE}"
}

patch_needs_applying_B004() {
    # Add condition for B004 if it exists
    return 1
}

patch_needs_applying_B005() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Unit/Unit.h"
    [[ -f "${FILE}" ]] && ! grep -q "ACCURACY_LEVEL_CAP" "${FILE}"
}

patch_needs_applying_B006() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/Hooks.h"
    [[ -f "${FILE}" ]] && ! grep -q "PLAYER_EVENT_ON_SELL_ITEM" "${FILE}"
}

patch_needs_applying_B007() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/methods/UnitMethods.h"
    [[ -f "${FILE}" ]] && ! grep -q "int SetWalk" "${FILE}"
}

patch_needs_applying_B008() {
    [[ -d "${DIR}/modules/mod-talent-bonus" ]] && [[ ! -d "${AC_CODE_DIR}/modules/mod-talent-bonus" ]]
}

patch_needs_applying_B009() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Player/Player.h"
    [[ -f "${FILE}" ]] && ! grep -q "enum EquipmentSlots : uint32" "${FILE}"
}

patch_needs_applying_B010() {
    local FILE="${AC_CODE_DIR}/src/server/game/Battlegrounds/Battleground.h"
    [[ -f "${FILE}" ]] && ! grep -q "ARENA_TYPE_NONE" "${FILE}"
}

patch_needs_applying_B011() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/ALE_SC.cpp"
    [[ -f "${FILE}" ]] && grep -q "OnPlayerResurrect.*bool&" "${FILE}"
}

patch_needs_applying_B012() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Player/Player.cpp"
    [[ -f "${FILE}" ]] && grep -q "for (int slot = EQUIPMENT_SLOT_START\|for (int i = EQUIPMENT_SLOT_START" "${FILE}"
}

patch_needs_applying_B013() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Actions/ChooseRpgTargetAction.cpp"
    [[ -f "${FILE}" ]] && grep -q "groupLeader && !groupLeader->isMoving() ||" "${FILE}"
}

patch_needs_applying_B014() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Actions/BattleGroundTactics.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "default:" "${FILE}"
}

patch_needs_applying_B015() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Raid/Magtheridon/Action/RaidMagtheridonActions.cpp"
    [[ -f "${FILE}" ]] && grep -q "/ RAND_MAX" "${FILE}" && ! grep -q "static_cast<float>(RAND_MAX)" "${FILE}"
}

patch_needs_applying_B016() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Actions/GenericSpellActions.cpp"
    [[ -f "${FILE}" ]] && grep -q 'range(botAI->GetRange("spell")), spell(spell)' "${FILE}"
}

patch_needs_applying_B017() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Actions/ChooseRpgTargetAction.cpp"
    [[ -f "${FILE}" ]] && grep -q "Player\* player = botAI->GetBot();" "${FILE}" && ! grep -q "(void)player;" "${FILE}"
}

patch_needs_applying_B018() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/PlayerbotAIConfig.cpp"
    [[ -f "${FILE}" ]] && grep -q "for (int tab = 0; tab < 3; tab++)" "${FILE}"
}

patch_needs_applying_B019() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Strategy/NonCombatStrategy.cpp"
    [[ -f "${FILE}" ]] && grep -q "std::vector<TriggerNode\*>& triggers)" "${FILE}"
}

patch_needs_applying_B020() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/ALEEventMgr.cpp"
    if [[ ! -f "${FILE}" ]]; then
        return 1
    fi
    # Patch needed if RemoveEvent body does NOT already contain LOCK_ALE
    ! awk '/^void ALEEventProcessor::RemoveEvent/,/^}/' "${FILE}" | grep -q "LOCK_ALE"
}
# }}}

# {{{ patches_need_applying
# Check if any PHASE_BEGIN patches for current profile would modify source
# Returns 0 (true) if patches need applying, 1 (false) if all applied
# Profile-aware: only checks patches in PHASE_BEGIN_PATCHES[$PROFILE]
patches_need_applying() {
    local patches="${PHASE_BEGIN_PATCHES[$PROFILE]:-}"

    # No patches for this profile = nothing to check
    if [[ -z "${patches}" ]]; then
        return 1
    fi

    # Check each patch in the profile's list
    for patch_id in ${patches}; do
        local check_func="patch_needs_applying_${patch_id}"
        if declare -F "${check_func}" > /dev/null 2>&1; then
            if ${check_func}; then
                return 0  # This patch needs applying
            fi
        fi
    done

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
