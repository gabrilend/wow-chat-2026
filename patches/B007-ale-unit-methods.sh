#!/usr/bin/env bash
# B007 - Add SetWalk, IsWalking, IsHostileTo, IsFriendlyTo to ALE Unit methods
# Issue 332: ALE unit methods patch
# Parallelizable: Yes (unique files)

# {{{ patch_B007_ale_unit_methods
patch_B007_ale_unit_methods() {
    local UNIT_METHODS="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/methods/UnitMethods.h"
    local LUA_FUNCS="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/LuaFunctions.cpp"
    local APPLIED=0

    # 1. Add methods to UnitMethods.h after SetSpeedRate
    if [[ -f "${UNIT_METHODS}" ]] && ! grep -q "int SetWalk" "${UNIT_METHODS}"; then
        sed -i '/int SetSpeedRate/,/^    }$/{
            /^    }$/a\
\
    /**\
     * Sets whether the [Unit] is currently walking or running.\
     * Works for all Unit types including Player. (Issue 332)\
     *\
     * @param bool enable = true : true to enable walking, false for running\
     */\
    int SetWalk(lua_State* L, Unit* unit)\
    {\
        bool enable = ALE::CHECKVAL<bool>(L, 2, true);\
        unit->SetWalk(enable);\
        return 0;\
    }\
\
    /**\
     * Returns whether the [Unit] is currently walking. (Issue 332)\
     *\
     * @return bool isWalking\
     */\
    int IsWalking(lua_State* L, Unit* unit)\
    {\
        ALE::Push(L, unit->IsWalking());\
        return 1;\
    }\
\
    /**\
     * Returns true if the [Unit] is hostile to the specified [Unit]. (Issue 332)\
     * Uses faction relationship data to determine hostility.\
     *\
     * @param [Unit] target : the unit to check hostility against\
     * @return bool isHostile\
     */\
    int IsHostileTo(lua_State* L, Unit* unit)\
    {\
        Unit* target = ALE::CHECKOBJ<Unit>(L, 2);\
        ALE::Push(L, unit->IsHostileTo(target));\
        return 1;\
    }\
\
    /**\
     * Returns true if the [Unit] is friendly to the specified [Unit]. (Issue 332)\
     * Uses faction relationship data to determine friendship.\
     *\
     * @param [Unit] target : the unit to check friendship against\
     * @return bool isFriendly\
     */\
    int IsFriendlyTo(lua_State* L, Unit* unit)\
    {\
        Unit* target = ALE::CHECKOBJ<Unit>(L, 2);\
        ALE::Push(L, unit->IsFriendlyTo(target));\
        return 1;\
    }
        }' "${UNIT_METHODS}"
        APPLIED=1
    fi

    # 2. Add method registrations to LuaFunctions.cpp
    if [[ -f "${LUA_FUNCS}" ]] && ! grep -q '"SetWalk"' "${LUA_FUNCS}"; then
        sed -i '/{ "SetSpeedRate", &LuaUnit::SetSpeedRate },/a \    { "SetWalk", \&LuaUnit::SetWalk },\
    { "IsWalking", \&LuaUnit::IsWalking },\
    { "IsHostileTo", \&LuaUnit::IsHostileTo },\
    { "IsFriendlyTo", \&LuaUnit::IsFriendlyTo },' "${LUA_FUNCS}"
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

    # 1. Remove methods from UnitMethods.h
    if [[ -f "${UNIT_METHODS}" ]]; then
        sed -i '/\* Sets whether the \[Unit\] is currently walking.*Issue 332/,/^    }$/d' "${UNIT_METHODS}"
        sed -i '/\* Returns whether the \[Unit\] is currently walking.*Issue 332/,/^    }$/d' "${UNIT_METHODS}"
        sed -i '/\* Returns true if the \[Unit\] is hostile.*Issue 332/,/^    }$/d' "${UNIT_METHODS}"
        sed -i '/\* Returns true if the \[Unit\] is friendly.*Issue 332/,/^    }$/d' "${UNIT_METHODS}"
    fi

    # 2. Remove method registrations from LuaFunctions.cpp
    if [[ -f "${LUA_FUNCS}" ]]; then
        sed -i '/{ "SetWalk", &LuaUnit::SetWalk },/d' "${LUA_FUNCS}"
        sed -i '/{ "IsWalking", &LuaUnit::IsWalking },/d' "${LUA_FUNCS}"
        sed -i '/{ "IsHostileTo", &LuaUnit::IsHostileTo },/d' "${LUA_FUNCS}"
        sed -i '/{ "IsFriendlyTo", &LuaUnit::IsFriendlyTo },/d' "${LUA_FUNCS}"
    fi
}
# }}}
