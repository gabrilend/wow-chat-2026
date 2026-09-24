#!/usr/bin/env bash
# B007 - Add SetWalk, IsWalking, IsHostileTo, IsFriendlyTo to ALE Unit methods
# Issue 332: ALE unit methods patch
# Parallelizable: Yes (unique files)
#
# Every inserted block is bracketed by ">>> B007 ... BEGIN" / "<<< B007 ... END"
# marker comments, and the revert deletes exactly the bracketed ranges.
# (Until 2026-09-23 the revert tried to re-match the inserted methods by their
# comment text, one method at a time. The first method's comment has its
# "Issue 332" tag on the following line, so its pattern never matched, and
# the other three deletions started one line late, leaving "/**" fragments
# and the whole SetWalk method behind: the tree never returned to upstream.)

# {{{ patch_B007_ale_unit_methods
patch_B007_ale_unit_methods() {
    local UNIT_METHODS="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/methods/UnitMethods.h"
    local LUA_FUNCS="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/LuaFunctions.cpp"
    local APPLIED=0

    # 1. Add methods to UnitMethods.h after SetSpeedRate's closing brace
    if [[ -f "${UNIT_METHODS}" ]] && ! grep -q "B007-ale-unit-methods BEGIN" "${UNIT_METHODS}"; then
        # Anchor: the first four-space closing brace after "int SetSpeedRate".
        local start close
        start=$(grep -n "int SetSpeedRate" "${UNIT_METHODS}" | head -1 | cut -d: -f1)
        if [[ -z "${start}" ]]; then
            echo "  [B007] ERROR: 'int SetSpeedRate' not found in ${UNIT_METHODS}"
            return 1
        fi
        close=$(awk -v s="${start}" 'NR > s && /^    }$/ { print NR; exit }' "${UNIT_METHODS}")
        if [[ -z "${close}" ]]; then
            echo "  [B007] ERROR: no closing brace after SetSpeedRate in ${UNIT_METHODS}"
            return 1
        fi

        local BLOCK
        BLOCK="$(mktemp)"
        cat > "${BLOCK}" << 'CPP_B007_METHODS'
    // >>> B007-ale-unit-methods BEGIN (Issue 332)

    /**
     * Sets whether the [Unit] is currently walking or running.
     * Works for all Unit types including Player. (Issue 332)
     *
     * @param bool enable = true : true to enable walking, false for running
     */
    int SetWalk(lua_State* L, Unit* unit)
    {
        bool enable = ALE::CHECKVAL<bool>(L, 2, true);
        unit->SetWalk(enable);
        return 0;
    }

    /**
     * Returns whether the [Unit] is currently walking. (Issue 332)
     *
     * @return bool isWalking
     */
    int IsWalking(lua_State* L, Unit* unit)
    {
        ALE::Push(L, unit->IsWalking());
        return 1;
    }

    /**
     * Returns true if the [Unit] is hostile to the specified [Unit]. (Issue 332)
     * Uses faction relationship data to determine hostility.
     *
     * @param [Unit] target : the unit to check hostility against
     * @return bool isHostile
     */
    int IsHostileTo(lua_State* L, Unit* unit)
    {
        Unit* target = ALE::CHECKOBJ<Unit>(L, 2);
        ALE::Push(L, unit->IsHostileTo(target));
        return 1;
    }

    /**
     * Returns true if the [Unit] is friendly to the specified [Unit]. (Issue 332)
     * Uses faction relationship data to determine friendship.
     *
     * @param [Unit] target : the unit to check friendship against
     * @return bool isFriendly
     */
    int IsFriendlyTo(lua_State* L, Unit* unit)
    {
        Unit* target = ALE::CHECKOBJ<Unit>(L, 2);
        ALE::Push(L, unit->IsFriendlyTo(target));
        return 1;
    }
    // <<< B007-ale-unit-methods END
CPP_B007_METHODS
        sed -i "${close}r ${BLOCK}" "${UNIT_METHODS}"
        rm -f "${BLOCK}"
        APPLIED=1
    fi

    # 2. Add method registrations to LuaFunctions.cpp (four single lines,
    #    each tagged, so the revert can delete them by tag)
    if [[ -f "${LUA_FUNCS}" ]] && ! grep -q '"SetWalk"' "${LUA_FUNCS}"; then
        if ! grep -q '{ "SetSpeedRate", &LuaUnit::SetSpeedRate },' "${LUA_FUNCS}"; then
            echo "  [B007] ERROR: SetSpeedRate registration not found in ${LUA_FUNCS}"
            return 1
        fi
        sed -i '/{ "SetSpeedRate", &LuaUnit::SetSpeedRate },/a \    { "SetWalk", \&LuaUnit::SetWalk },           // B007\
    { "IsWalking", \&LuaUnit::IsWalking },       // B007\
    { "IsHostileTo", \&LuaUnit::IsHostileTo },   // B007\
    { "IsFriendlyTo", \&LuaUnit::IsFriendlyTo }, // B007' "${LUA_FUNCS}"
        APPLIED=1
    fi

    if [[ "${APPLIED}" -eq 1 ]]; then
        echo "  [B007] ALE unit methods (SetWalk, IsWalking, IsHostileTo, IsFriendlyTo)"
    fi
}
# }}}

# {{{ unpatch_B007_ale_unit_methods
unpatch_B007_ale_unit_methods() {
    local UNIT_METHODS="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/methods/UnitMethods.h"
    local LUA_FUNCS="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/LuaFunctions.cpp"

    # 1. Remove the bracketed methods block from UnitMethods.h
    if [[ -f "${UNIT_METHODS}" ]]; then
        sed -i '/>>> B007-ale-unit-methods BEGIN/,/<<< B007-ale-unit-methods END/d' "${UNIT_METHODS}"
    fi

    # 2. Remove the tagged registrations from LuaFunctions.cpp
    if [[ -f "${LUA_FUNCS}" ]]; then
        sed -i '/&LuaUnit::\(SetWalk\|IsWalking\|IsHostileTo\|IsFriendlyTo\) }, *\/\/ B007$/d' "${LUA_FUNCS}"
    fi
}
# }}}
