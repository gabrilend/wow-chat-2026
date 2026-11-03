#!/usr/bin/env bash

B059_BEGIN='// >>> B059-ale-taxi-nodes-named BEGIN'
B059_END='// <<< B059-ale-taxi-nodes-named END'

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

unpatch_B059_ale_taxi_nodes_named() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/methods/GlobalMethods.h"
    [[ -f "${FILE}" ]] || return 0
    sed -i "\|${B059_BEGIN}|,\|${B059_END}|d" "${FILE}"
    echo "  [B059] Reverted"
}
