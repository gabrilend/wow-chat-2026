#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         B059
# profiles:   basic
# priority:   690
# kind:       source
# about:      flight points made from Lua get an empty name in every language, so reading one cannot stop the server
# ==== end of header ====
# B059 - flight points made from Lua get a name (an empty one) in every language
# Found 2026-10-26 from a Debug build's backtrace.
#
# For a general audience: basic builds Outland's flight paths at start-up
# from Lua (src/lua-basic/outland-flights.lua), through the Lua engine's
# AddTaxiPath. For each point of a path it makes a flight point, numbered
# from 500 up, and leaves its name unset in all sixteen of the game's
# languages: not an empty name, no name at all. Any server code that reads a
# flight point's name then reads nothing. The game master's ".lookup
# taxinode" does, and on 2026-10-26 ".lookup taxinode eastern" stopped the
# server (it turned flight point 500's missing name into text: "basic_string:
# construction from null is not valid"). Every flight point read from the
# game's own data has a name, at least an empty one. This gives the made
# ones the same: an empty name in each language, before the point is
# stored, so every reader of names, not only that command, finds text.
#
# Mechanics: one insertion in mod-ale's GlobalMethods.h, right after the
# line that makes each flight point (`new TaxiNodesEntry()`), between
# ">>> B059 ... BEGIN" / "<<< B059 ... END" marker comments; the unpatch
# deletes the marked range, so the file returns to upstream exactly.
#   the line is there once: patched
#   not there: upstream changed AddTaxiPath; the patch stops, naming the file
#   already patched (markers present): nothing to do

B059_BEGIN='// >>> B059-ale-taxi-nodes-named BEGIN'
B059_END='// <<< B059-ale-taxi-nodes-named END'

# {{{ patch_B059_ale_taxi_nodes_named
patch_B059_ale_taxi_nodes_named() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/methods/GlobalMethods.h"
    local ANCHOR='TaxiNodesEntry* nodeEntry = new TaxiNodesEntry();'
    [[ -f "${FILE}" ]] || { echo "  [B059] ERROR: ${FILE} is missing (is mod-ale cloned?)"; return 1; }
    if grep -qF "${B059_BEGIN}" "${FILE}"; then
        return 0                                   # already patched
    fi
    local found
    found="$(grep -cF "${ANCHOR}" "${FILE}")"
    if [[ "${found}" != "1" ]]; then
        echo "  [B059] ERROR: expected the line '${ANCHOR}' once in ${FILE}, found it ${found} times"
        echo "         to debug: has upstream changed Global:AddTaxiPath? Find where it makes each TaxiNodesEntry."
        return 1
    fi
    ANCHOR="${ANCHOR}" BEGIN_M="${B059_BEGIN}" END_M="${B059_END}" awk '
        { print }
        index($0, ENVIRON["ANCHOR"]) {
            print "            " ENVIRON["BEGIN_M"]
            print "            // a name in each language, empty: a flight point read from the"
            print "            // game'"'"'s data always has one, and readers of names (.lookup"
            print "            // taxinode) turn it into text; unset, they stopped the server"
            print "            for (char const*& name : nodeEntry->name)"
            print "                name = \"\";"
            print "            " ENVIRON["END_M"]
        }' "${FILE}" > "${FILE}.b059" && mv "${FILE}.b059" "${FILE}"
    grep -qF "${B059_BEGIN}" "${FILE}" || { echo "  [B059] ERROR: the insertion did not land in ${FILE}"; return 1; }
    echo "  [B059] Applied: Lua-made flight points named"
}
# }}}

# {{{ unpatch_B059_ale_taxi_nodes_named
unpatch_B059_ale_taxi_nodes_named() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/methods/GlobalMethods.h"
    [[ -f "${FILE}" ]] || return 0
    sed -i "\|${B059_BEGIN}|,\|${B059_END}|d" "${FILE}"
    echo "  [B059] Reverted"
}
# }}}
# ==== footer of B059 ====
# lines:      77
# ==== end of footer ====
