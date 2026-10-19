#!/usr/bin/env bash
# B055 - a Lua call that tells where a player joined a battleground or arena
# Issue 211a (2026-10-18).
#
# For a general audience: when a player joins a battleground or an arena,
# the game remembers where they stood, so it can send them back there when
# the match ends (Player::SetEntryPoint; the dungeon finder uses the same
# record). Lua scripts could not read it. On beta a druid's Teleport:
# Moonglade, cast in a battleground or arena, should come back to "the spot
# where they entered" (the owner, 2026-10-18), and the owner asked that it
# be a patch ("sure. Make it a patch, remember!"). This adds one call:
#   player:GetEntryPoint()
#       a table { mapId, x, y, z, o } (numbers), or nil when the game keeps
#       no entry point for the player (none recorded: its map is
#       MAPID_INVALID, the value SetEntryPoint starts from)
# Read by src/lua-beta/druid-moonglade.lua (Moonglade.wayBack).
#
# Mechanics, two files, each insertion inside ">>> B055 ... BEGIN" /
# "<<< B055 ... END" marker comments: PlayerMethods.h gains the method
# before the namespace's closing "};" (its last one), LuaFunctions.cpp
# registers it after GetHomebind. Anchors must occur exactly once (the
# closing "};" is taken as the file's last) or the patch stops with an
# error. Modelled on B051.
# Parallelizable: Yes

B055_BEGIN='// >>> B055-ale-player-entry-point BEGIN'
B055_END='// <<< B055-ale-player-entry-point END'
B055_REGISTER='    { "GetHomebind", &LuaPlayer::GetHomebind },'

# {{{ patch_B055_ale_player_entry_point
patch_B055_ale_player_entry_point() {
    local ALE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine"
    local METHODS="${ALE}/methods/PlayerMethods.h"
    local FUNCS="${ALE}/LuaFunctions.cpp"
    [[ -f "${METHODS}" && -f "${FUNCS}" ]] || { echo "  [B055] ERROR: mod-ale's PlayerMethods.h or LuaFunctions.cpp missing"; return 1; }
    grep -qF "B055-ale-player-entry-point" "${METHODS}" && return 0   # witness guard

    local b
    b=$(grep -cxF -- "${B055_REGISTER}" "${FUNCS}")
    if [[ "${b}" != "1" ]]; then
        echo "  [B055] ERROR: anchor found ${b} times (want 1): the GetHomebind registration in ${FUNCS}"
        return 1
    fi
    local last
    last=$(grep -nx '};' "${METHODS}" | tail -1 | cut -d: -f1)
    [[ -n "${last}" ]] || { echo "  [B055] ERROR: no closing '};' in ${METHODS}"; return 1; }

    LAST="${last}" BEGIN_M="${B055_BEGIN}" END_M="${B055_END}" awk '
        NR == ENVIRON["LAST"] {
            print "    " ENVIRON["BEGIN_M"]
            print "    /**"
            print "     * Where the [Player] joined the battleground, arena or dungeon-finder"
            print "     * group they are in: the spot the game sends them back to when it"
            print "     * ends (Player::GetEntryPoint). Nil when the game keeps none"
            print "     * (B055, issue 211a)."
            print "     *"
            print "     * @return table entryPoint : { mapId, x, y, z, o } or nil"
            print "     */"
            print "    int GetEntryPoint(lua_State* L, Player* player)"
            print "    {"
            print "        WorldLocation const& at = player->GetEntryPoint();"
            print "        if (at.GetMapId() == MAPID_INVALID)"
            print "        {"
            print "            ALE::Push(L);"
            print "            return 1;"
            print "        }"
            print "        lua_newtable(L);"
            print "        lua_pushinteger(L, at.GetMapId());"
            print "        lua_setfield(L, -2, \"mapId\");"
            print "        lua_pushnumber(L, at.GetPositionX());"
            print "        lua_setfield(L, -2, \"x\");"
            print "        lua_pushnumber(L, at.GetPositionY());"
            print "        lua_setfield(L, -2, \"y\");"
            print "        lua_pushnumber(L, at.GetPositionZ());"
            print "        lua_setfield(L, -2, \"z\");"
            print "        lua_pushnumber(L, at.GetOrientation());"
            print "        lua_setfield(L, -2, \"o\");"
            print "        return 1;"
            print "    }"
            print "    " ENVIRON["END_M"]
        }
        { print }
    ' "${METHODS}" > "${METHODS}.b055" && mv "${METHODS}.b055" "${METHODS}"

    REG="${B055_REGISTER}" BEGIN_M="${B055_BEGIN}" END_M="${B055_END}" awk '
        { print }
        $0 == ENVIRON["REG"] {
            print "    " ENVIRON["BEGIN_M"]
            print "    { \"GetEntryPoint\", &LuaPlayer::GetEntryPoint },"
            print "    " ENVIRON["END_M"]
        }
    ' "${FUNCS}" > "${FUNCS}.b055" && mv "${FUNCS}.b055" "${FUNCS}"

    echo "  [B055] Lua: player:GetEntryPoint()"
}
# }}}

# {{{ unpatch_B055_ale_player_entry_point
unpatch_B055_ale_player_entry_point() {
    local ALE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine"
    local f
    for f in "${ALE}/methods/PlayerMethods.h" "${ALE}/LuaFunctions.cpp"; do
        [[ -f "${f}" ]] || continue
        grep -qF "B055-ale-player-entry-point" "${f}" || continue   # nothing of ours
        awk '
            /\/\/ >>> B055-ale-player-entry-point BEGIN/ { inblock = 1; next }
            inblock && /\/\/ <<< B055-ale-player-entry-point END/ { inblock = 0; next }
            inblock { next }
            { print }' "${f}" > "${f}.b055" && mv "${f}.b055" "${f}"
    done
    return 0
}
# }}}
