#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         B060
# profiles:   basic
# priority:   700
# kind:       source
# about:      crowd control lasts its full length however often it lands: no diminishing returns, no 10-second PvP cap (taunts kept)
# ==== end of header ====
# B060 - crowd control lasts its full length, however often it is cast (issue 155z14)
#
# For a general audience: in the stock game, stunning (or fearing,
# rooting, silencing...) the same target again and again works less each
# time: the second lasts half as long, the third a quarter, then the target
# is immune for a while ("diminishing returns"), and a player's crowd
# control on another player never lasts more than 10 seconds. The owner,
# 2026-10-26: "we should disable the stunlock protection rules. If players
# want to throw out that much CC, well, the other side deserves it." This
# makes the server's one function that shortens crowd control say "full
# length" for everything but taunts (whose diminishing only some creatures
# have, a tank's rule, kept).
#
# Mechanics: one insertion in Unit.cpp, inside
# Unit::ApplyDiminishingToDuration, right after its opening check
# ("if (duration == -1 || group == DIMINISHING_NONE)" and its
# "return 1.0f;"), between ">>> B060 ... BEGIN" / "<<< B060 ... END" marker
# comments; the unpatch deletes the marked range.
#   the opening check found once: patched after its return line
#   not found once: upstream changed the function; stops, naming it
#   markers already there: nothing to do

B060_BEGIN='// >>> B060-no-crowd-control-diminishing BEGIN'
B060_END='// <<< B060-no-crowd-control-diminishing END'

# {{{ patch_B060_no_crowd_control_diminishing
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
    # after the anchor, the next line holding "return 1.0f;" ends the check;
    # the insertion goes right after it
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
# }}}

# {{{ unpatch_B060_no_crowd_control_diminishing
# The marked range and the blank line written before it.
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
# }}}
# ==== footer of B060 ====
# lines:      92
# ==== end of footer ====
