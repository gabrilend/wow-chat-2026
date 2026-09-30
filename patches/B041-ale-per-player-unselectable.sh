#!/usr/bin/env bash
# B041 - Lua calls for creatures one player cannot select
# Issue 164 (2026-09-29). Needs B040, which makes PerPlayerCreatures.h.
#
# For a general audience: B040 lets the server hide the "you can click
# this" bit of chosen creatures from one player. This patch hands that to
# the Lua scripts, as two calls on a player:
#   player:SetUnselectableCreatures({ entry, ... }, allExcept)
#       allExcept false (the default): the listed creatures can't be
#       selected by this player; true: none can, except the listed ones
#   player:ClearUnselectableCreatures()
#       back to normal
# The rule lasts until cleared or until the player logs out.
#
# Mechanics, two files, each insertion inside ">>> B041 ... BEGIN" /
# "<<< B041 ... END" marker comments: PlayerMethods.h gains the include and
# the two methods (before the namespace's closing "};", its last one);
# LuaFunctions.cpp registers them after GetAccountId. Anchors must occur
# exactly once (the closing "};" is taken as the file's last) or the patch
# stops with an error.
# Parallelizable: No (needs B040's header)

B041_BEGIN='// >>> B041-ale-per-player-unselectable BEGIN'
B041_END='// <<< B041-ale-per-player-unselectable END'
B041_INCLUDE='#include "GossipDef.h"'
B041_REGISTER='    { "GetAccountId", &LuaPlayer::GetAccountId },'

# {{{ patch_B041_ale_per_player_unselectable
patch_B041_ale_per_player_unselectable() {
    local ALE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine"
    local METHODS="${ALE}/methods/PlayerMethods.h"
    local FUNCS="${ALE}/LuaFunctions.cpp"
    [[ -f "${METHODS}" && -f "${FUNCS}" ]] || { echo "  [B041] ERROR: mod-ale's PlayerMethods.h or LuaFunctions.cpp missing"; return 1; }
    grep -qF "B041-ale-per-player-unselectable" "${METHODS}" && return 0   # witness guard

    local a b
    a=$(grep -cxF -- "${B041_INCLUDE}" "${METHODS}")
    b=$(grep -cxF -- "${B041_REGISTER}" "${FUNCS}")
    if [[ "${a}${b}" != "11" ]]; then
        echo "  [B041] ERROR: anchors found (want 1 each): GossipDef.h include ${a}, GetAccountId registration ${b}"
        return 1
    fi
    local last
    last=$(grep -nx '};' "${METHODS}" | tail -1 | cut -d: -f1)
    [[ -n "${last}" ]] || { echo "  [B041] ERROR: no closing '};' in ${METHODS}"; return 1; }

    INC="${B041_INCLUDE}" LAST="${last}" BEGIN_M="${B041_BEGIN}" END_M="${B041_END}" awk '
        NR == ENVIRON["LAST"] {
            print "    " ENVIRON["BEGIN_M"]
            print "    /**"
            print "     * Makes creatures unselectable to this [Player] alone (issue 164). With"
            print "     * `allExcept` false the listed creature entries can'"'"'t be selected by them;"
            print "     * with it true, no creature can except the listed ones. Their own pets"
            print "     * and guardians always can, and so can a game master in GM mode. Lasts"
            print "     * until cleared or until they log out."
            print "     *"
            print "     * @param table entries : creature entry numbers"
            print "     * @param bool allExcept = false"
            print "     */"
            print "    int SetUnselectableCreatures(lua_State* L, Player* player)"
            print "    {"
            print "        luaL_checktype(L, 2, LUA_TTABLE);"
            print "        bool allExcept = ALE::CHECKVAL<bool>(L, 3, false);"
            print "        std::vector<uint32> entries;"
            print "        lua_pushnil(L);"
            print "        while (lua_next(L, 2) != 0)"
            print "        {"
            print "            entries.push_back(uint32(luaL_checkinteger(L, -1)));"
            print "            lua_pop(L, 1);"
            print "        }"
            print "        PerPlayerCreatures::Set(player, entries, allExcept);"
            print "        return 0;"
            print "    }"
            print ""
            print "    /**"
            print "     * Every creature selectable to this [Player] again (issue 164)."
            print "     */"
            print "    int ClearUnselectableCreatures(lua_State* /*L*/, Player* player)"
            print "    {"
            print "        PerPlayerCreatures::Clear(player);"
            print "        return 0;"
            print "    }"
            print ""
            print "    /**"
            print "     * Hides one creature spawn from this [Player] alone, or shows it again"
            print "     * (issue 164). Everyone else still sees it. By spawn number (the"
            print "     * creature table'"'"'s guid), so it can be set before the creature loads."
            print "     * A game master in GM mode still sees it. Lasts until shown again or"
            print "     * until they log out."
            print "     *"
            print "     * @param uint32 spawnId"
            print "     * @param bool hidden = true"
            print "     */"
            print "    int SetCreatureSpawnHidden(lua_State* L, Player* player)"
            print "    {"
            print "        uint32 spawnId = ALE::CHECKVAL<uint32>(L, 2);"
            print "        bool hidden = ALE::CHECKVAL<bool>(L, 3, true);"
            print "        PerPlayerCreatures::SetHidden(player, spawnId, hidden);"
            print "        return 0;"
            print "    }"
            print "    " ENVIRON["END_M"]
        }
        { print }
        $0 == ENVIRON["INC"] && !inc {
            print ENVIRON["BEGIN_M"]
            print "#include \"PerPlayerCreatures.h\""
            print "#include <vector>"
            print ENVIRON["END_M"]
            inc = 1
        }
    ' "${METHODS}" > "${METHODS}.b041" && mv "${METHODS}.b041" "${METHODS}"

    REG="${B041_REGISTER}" BEGIN_M="${B041_BEGIN}" END_M="${B041_END}" awk '
        { print }
        $0 == ENVIRON["REG"] {
            print "    " ENVIRON["BEGIN_M"]
            print "    { \"SetUnselectableCreatures\", &LuaPlayer::SetUnselectableCreatures },"
            print "    { \"ClearUnselectableCreatures\", &LuaPlayer::ClearUnselectableCreatures },"
            print "    { \"SetCreatureSpawnHidden\", &LuaPlayer::SetCreatureSpawnHidden },"
            print "    " ENVIRON["END_M"]
        }
    ' "${FUNCS}" > "${FUNCS}.b041" && mv "${FUNCS}.b041" "${FUNCS}"

    echo "  [B041] Lua: player:SetUnselectableCreatures / ClearUnselectableCreatures"
}
# }}}

# {{{ unpatch_B041_ale_per_player_unselectable
unpatch_B041_ale_per_player_unselectable() {
    local ALE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine"
    local f
    for f in "${ALE}/methods/PlayerMethods.h" "${ALE}/LuaFunctions.cpp"; do
        [[ -f "${f}" ]] || continue
        grep -qF "B041-ale-per-player-unselectable" "${f}" || continue   # nothing of ours
        awk '
            /\/\/ >>> B041-ale-per-player-unselectable BEGIN/ { inblock = 1; next }
            inblock && /\/\/ <<< B041-ale-per-player-unselectable END/ { inblock = 0; next }
            inblock { next }
            { print }' "${f}" > "${f}.b041" && mv "${f}.b041" "${f}"
    done
    return 0
}
# }}}
