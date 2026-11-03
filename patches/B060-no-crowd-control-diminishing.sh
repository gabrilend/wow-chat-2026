#!/usr/bin/env bash

B060_BEGIN='// >>> B060-no-crowd-control-diminishing BEGIN'
B060_END='// <<< B060-no-crowd-control-diminishing END'

patch_B060_no_crowd_control_diminishing() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Unit/Unit.cpp"
    local ANCHOR='if (duration == -1 || group == DIMINISHING_NONE)'
    [[ -f "${FILE}" ]] || { echo "  [B060] ERROR: ${FILE} is missing"; return 1; }
    if grep -qF "${B060_BEGIN}" "${FILE}"; then
        return 0                                   # already patched
    fi
    local found
    found="$(grep -cF "${ANCHOR}" "${FILE}")"
    if [[ "${found}" != "1" ]]; then
        echo "  [B060] ERROR: expected '${ANCHOR}' once in ${FILE}, found it ${found} times"
        echo "         to debug: has upstream changed Unit::ApplyDiminishingToDuration's first check?"
        return 1
    fi
    ANCHOR="${ANCHOR}" BEGIN_M="${B060_BEGIN}" END_M="${B060_END}" awk '
        { print }
        index($0, ENVIRON["ANCHOR"]) { armed = 1; next }
        armed && index($0, "return 1.0f;") {
            armed = 0
            print ""
            print "    " ENVIRON["BEGIN_M"]
            print "    // basic: no stun protection (issue 155z14). Every kind of crowd"
            print "    // control lasts its full length, however often it lands, and a"
            print "    // player'"'"'s on a player is not capped at 10 seconds; taunts keep"
            print "    // their own diminishing (only creatures marked for it have it)"
            print "    if (group != DIMINISHING_TAUNT)"
            print "        return 1.0f;"
            print "    " ENVIRON["END_M"]
        }' "${FILE}" > "${FILE}.b060" && mv "${FILE}.b060" "${FILE}"
    grep -qF "${B060_BEGIN}" "${FILE}" || { echo "  [B060] ERROR: the insertion did not land in ${FILE}"; return 1; }
    echo "  [B060] Applied: crowd control without diminishing returns"
}

unpatch_B060_no_crowd_control_diminishing() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Unit/Unit.cpp"
    [[ -f "${FILE}" ]] || return 0
    grep -qF "${B060_BEGIN}" "${FILE}" || return 0
    B="${B060_BEGIN}" E="${B060_END}" awk '
        { line[NR] = $0 }
        END {
            for (i = 1; i <= NR; i++) {
                if (index(line[i], ENVIRON["B"])) { skip = 1; continue }
                if (skip) { if (index(line[i], ENVIRON["E"])) skip = 0; continue }
                if (line[i] == "" && index(line[i + 1], ENVIRON["B"])) continue
                print line[i]
            }
        }' "${FILE}" > "${FILE}.b060" && mv "${FILE}.b060" "${FILE}"
    echo "  [B060] Reverted"
}
