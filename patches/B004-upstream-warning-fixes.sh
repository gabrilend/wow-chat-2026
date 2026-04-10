#!/usr/bin/env bash
# B004 - Fix ~695 compiler warnings in upstream modules
# Issue 333: Clean build improves code quality
# Parallelizable: Yes (no conflicts with B001-B003)

# {{{ patch_B004_upstream_warning_fixes
patch_B004_upstream_warning_fixes() {
    local PLAYERBOTS_DIR="${AC_CODE_DIR}/modules/mod-playerbots/src"
    local ALE_DIR="${AC_CODE_DIR}/modules/mod-ale/src"
    local APPLIED=0

    # 1. NextAction copy assignment (500 warnings)
    local FILE="${PLAYERBOTS_DIR}/Bot/Engine/Action/Action.h"
    if [[ -f "${FILE}" ]] && ! grep -q "NextAction& operator=" "${FILE}"; then
        sed -i '/NextAction(NextAction const& o).*/{
            a\    NextAction\& operator=(NextAction const\&) = default;
        }' "${FILE}"
        APPLIED=1
    fi

    # 2. MovementActions loop variable (119 warnings)
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/MovementActions.h"
    if [[ -f "${FILE}" ]] && grep -q "for (int i = 0; i < intervals; i++)" "${FILE}"; then
        sed -i 's/for (int i = 0; i < intervals; i++)/for (uint32 i = 0; i < intervals; i++)/' "${FILE}"
        APPLIED=1
    fi

    # 3. PositionInfo copy assignment (12 warnings)
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Value/PositionValue.h"
    if [[ -f "${FILE}" ]] && ! grep -q "PositionInfo& operator=" "${FILE}"; then
        sed -i '/PositionInfo(PositionInfo const\& other)/,/^    }/{
            /^    }$/a\    PositionInfo\& operator=(PositionInfo const\&) = default;
        }' "${FILE}"
        APPLIED=1
    fi

    # 4. CraftData copy assignment (3 warnings)
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Value/CraftValue.h"
    if [[ -f "${FILE}" ]] && ! grep -q "CraftData& operator=" "${FILE}"; then
        sed -i '/CraftData(CraftData const\& other)/,/^    }/{
            /^    }$/a\    CraftData\& operator=(CraftData const\&) = default;
        }' "${FILE}"
        APPLIED=1
    fi

    # 5. UnitPosition copy assignment (3 warnings)
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Value/Arrow.h"
    if [[ -f "${FILE}" ]] && ! grep -q "UnitPosition& operator=" "${FILE}"; then
        sed -i '/UnitPosition(UnitPosition const\& other)/,/^    }/{
            /^    }$/a\    UnitPosition\& operator=(UnitPosition const\&) = default;
        }' "${FILE}"
        APPLIED=1
    fi

    # 6. ItemCountValue unused event (13 warnings)
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Value/ItemCountValue.h"
    if [[ -f "${FILE}" ]] && grep -q "bool Execute(Event event) override { return false; }" "${FILE}"; then
        sed -i 's/bool Execute(Event event) override { return false; }/bool Execute(Event event) override { (void)event; return false; }/' "${FILE}"
        APPLIED=1
    fi

    # 7. PlayerMethods signed/unsigned (2 warnings)
    FILE="${ALE_DIR}/LuaEngine/methods/PlayerMethods.h"
    if [[ -f "${FILE}" ]] && grep -q "slot >= EQUIPMENT_SLOT_START && slot < EQUIPMENT_SLOT_END" "${FILE}"; then
        sed -i 's/slot >= EQUIPMENT_SLOT_START && slot < EQUIPMENT_SLOT_END/slot >= static_cast<int32>(EQUIPMENT_SLOT_START) \&\& slot < static_cast<int32>(EQUIPMENT_SLOT_END)/' "${FILE}"
        APPLIED=1
    fi

    if [[ "${APPLIED}" -eq 1 ]]; then
        echo "  [B004] Upstream warning fixes applied"
    fi
}
# }}}

# {{{ unpatch_B004_upstream_warning_fixes
unpatch_B004_upstream_warning_fixes() {
    local PLAYERBOTS_DIR="${AC_CODE_DIR}/modules/mod-playerbots/src"
    local ALE_DIR="${AC_CODE_DIR}/modules/mod-ale/src"

    # 1. Remove NextAction operator= default
    local FILE="${PLAYERBOTS_DIR}/Bot/Engine/Action/Action.h"
    if [[ -f "${FILE}" ]]; then
        sed -i '/NextAction\& operator=(NextAction const\&) = default;/d' "${FILE}"
    fi

    # 2. Revert MovementActions loop variable
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/MovementActions.h"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/for (uint32 i = 0; i < intervals; i++)/for (int i = 0; i < intervals; i++)/' "${FILE}"
    fi

    # 3. Remove PositionInfo operator= default
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Value/PositionValue.h"
    if [[ -f "${FILE}" ]]; then
        sed -i '/PositionInfo\& operator=(PositionInfo const\&) = default;/d' "${FILE}"
    fi

    # 4. Remove CraftData operator= default
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Value/CraftValue.h"
    if [[ -f "${FILE}" ]]; then
        sed -i '/CraftData\& operator=(CraftData const\&) = default;/d' "${FILE}"
    fi

    # 5. Remove UnitPosition operator= default
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Value/Arrow.h"
    if [[ -f "${FILE}" ]]; then
        sed -i '/UnitPosition\& operator=(UnitPosition const\&) = default;/d' "${FILE}"
    fi

    # 6. Revert ItemCountValue unused event fix
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Value/ItemCountValue.h"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/bool Execute(Event event) override { (void)event; return false; }/bool Execute(Event event) override { return false; }/' "${FILE}"
    fi

    # 7. Revert PlayerMethods signed/unsigned cast
    FILE="${ALE_DIR}/LuaEngine/methods/PlayerMethods.h"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/slot >= static_cast<int32>(EQUIPMENT_SLOT_START) \&\& slot < static_cast<int32>(EQUIPMENT_SLOT_END)/slot >= EQUIPMENT_SLOT_START \&\& slot < EQUIPMENT_SLOT_END/' "${FILE}"
    fi
}
# }}}
