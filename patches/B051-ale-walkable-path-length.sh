#!/usr/bin/env bash

B051_BEGIN='// >>> B051-ale-walkable-path-length BEGIN'
B051_END='// <<< B051-ale-walkable-path-length END'
B051_REGISTER='    { "MoveTo", &LuaUnit::MoveTo },'

patch_B051_ale_walkable_path_length() {
    local ALE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine"
    local METHODS="${ALE}/methods/UnitMethods.h"
    local FUNCS="${ALE}/LuaFunctions.cpp"
    [[ -f "${METHODS}" && -f "${FUNCS}" ]] || { echo "  [B051] ERROR: mod-ale's UnitMethods.h or LuaFunctions.cpp missing"; return 1; }
    grep -qF "B051-ale-walkable-path-length" "${METHODS}" && return 0   # witness guard

    local b
    b=$(grep -cxF -- "${B051_REGISTER}" "${FUNCS}")
    if [[ "${b}" != "1" ]]; then
        echo "  [B051] ERROR: anchor found ${b} times (want 1): the MoveTo registration in ${FUNCS}"
        return 1
    fi
    local last
    last=$(grep -nx '};' "${METHODS}" | tail -1 | cut -d: -f1)
    [[ -n "${last}" ]] || { echo "  [B051] ERROR: no closing '};' in ${METHODS}"; return 1; }

    LAST="${last}" BEGIN_M="${B051_BEGIN}" END_M="${B051_END}" awk '
        NR == 1 {
            print ENVIRON["BEGIN_M"]
            print "#include \"PathGenerator.h\""
            print ENVIRON["END_M"]
        }
        NR == ENVIRON["LAST"] {
            print "    " ENVIRON["BEGIN_M"]
            print "    /**"
            print "     * The length in yards of the walking path from this [Unit] to the"
            print "     * point along the navigation mesh, or nil when the mesh has no"
            print "     * complete walking path there: no path, part of one, a straight"
            print "     * line through obstacles, or a map without a mesh (B051, 617b)."
            print "     *"
            print "     * @param float x"
            print "     * @param float y"
            print "     * @param float z"
            print "     * @return float length or nil"
            print "     */"
            print "    int GetWalkablePathLength(lua_State* L, Unit* unit)"
            print "    {"
            print "        float x = ALE::CHECKVAL<float>(L, 2);"
            print "        float y = ALE::CHECKVAL<float>(L, 3);"
            print "        float z = ALE::CHECKVAL<float>(L, 4);"
            print "        PathGenerator path(unit);"
            print "        bool built = path.CalculatePath(x, y, z, false);"
            print "        uint32 type = uint32(path.GetPathType());"
            print "        uint32 refused = PATHFIND_SHORTCUT | PATHFIND_INCOMPLETE | PATHFIND_NOPATH | PATHFIND_NOT_USING_PATH;"
            print "        if (!built || !(type & PATHFIND_NORMAL) || (type & refused))"
            print "            ALE::Push(L);"
            print "        else"
            print "            ALE::Push(L, path.getPathLength());"
            print "        return 1;"
            print "    }"
            print "    " ENVIRON["END_M"]
        }
        { print }
    ' "${METHODS}" > "${METHODS}.b051" && mv "${METHODS}.b051" "${METHODS}"

    REG="${B051_REGISTER}" BEGIN_M="${B051_BEGIN}" END_M="${B051_END}" awk '
        { print }
        $0 == ENVIRON["REG"] {
            print "    " ENVIRON["BEGIN_M"]
            print "    { \"GetWalkablePathLength\", &LuaUnit::GetWalkablePathLength },"
            print "    " ENVIRON["END_M"]
        }
    ' "${FUNCS}" > "${FUNCS}.b051" && mv "${FUNCS}.b051" "${FUNCS}"

    echo "  [B051] Lua: unit:GetWalkablePathLength(x, y, z)"
}

unpatch_B051_ale_walkable_path_length() {
    local ALE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine"
    local f
    for f in "${ALE}/methods/UnitMethods.h" "${ALE}/LuaFunctions.cpp"; do
        [[ -f "${f}" ]] || continue
        grep -qF "B051-ale-walkable-path-length" "${f}" || continue   # nothing of ours
        awk '
            /\/\/ >>> B051-ale-walkable-path-length BEGIN/ { inblock = 1; next }
            inblock && /\/\/ <<< B051-ale-walkable-path-length END/ { inblock = 0; next }
            inblock { next }
            { print }' "${f}" > "${f}.b051" && mv "${f}.b051" "${f}"
    done
    return 0
}
