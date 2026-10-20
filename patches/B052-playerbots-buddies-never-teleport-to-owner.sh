#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         B052
# profiles:   buddy-set
# priority:   620
# kind:       source
# about:      Playerbots: a buddy's long walk never ends in a teleport
# ==== end of header ====
# B052 - Playerbots: a buddy's long walk never ends in a teleport
# Issue 617e4 (basic, 2026-10-12).
#
# For a general audience: the bot module walks a bot far across the world
# with one routine ("move far to"), and when that routine sees no real
# progress for a while (90 seconds, five tries) it gives up and puts the
# bot straight onto its destination. For a buddy the destination is its
# owner, so every buddy that couldn't find the way appeared on the owner's
# very spot (the owner, 2026-10-12, after flying two zones away in game-
# master flight onto a mountaintop: "They walked toward me for a while but
# eventually they couldn't continue I guess and they just... appeared
# there. [...] they all spawned exactly in the same spot"; and: "They
# shouldn't do that, they should keep trying to walk to me").
# The buddy module already resets that routine's stuck clock before each
# step, but the routine zeroes the clock itself whenever the destination
# changes, which is every time the owner moves, so the reset was undone.
# This patch resets the clock inside the routine, right before its stuck
# check, for bots on a companion account (B044's list, filled by
# mod-buddies); other bots are unchanged. A buddy that is truly stuck still
# gets the buddy module's own nudge to a random walkable spot within 30
# yards (buddies_town.cpp, Unstick), and walks on.
#
# Mechanics: pure insertions between ">>> B052-buddies-never-teleport
# BEGIN" / "<<< ... END" marker comments, after anchors that must each occur
# exactly once (else the patch stops); the revert deletes the blocks.
# Needs: B044 (its CompanionAccounts.h)
# Parallelizable: No (needs B044 applied first)

B052_TAG='B052-buddies-never-teleport'
B052_INCLUDE='#include "TravelMgr.h"'
B052_CHECK='    // stuck check'

# {{{ patch_B052_playerbots_buddies_never_teleport_to_owner
patch_B052_playerbots_buddies_never_teleport_to_owner() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/World/Rpg/Action/NewRpgBaseAction.cpp"
    local HEADER="${AC_CODE_DIR}/src/server/game/Cache/CompanionAccounts.h"
    [[ -f "${FILE}" ]] || { echo "  [B052] ERROR: ${FILE} missing"; return 1; }
    [[ -f "${HEADER}" ]] || { echo "  [B052] ERROR: ${HEADER} missing (B044 must be applied first)"; return 1; }
    grep -qF "${B052_TAG}" "${FILE}" && return 0                  # witness guard

    local a b
    a=$(grep -cxF -- "${B052_INCLUDE}" "${FILE}")
    b=$(grep -cxF -- "${B052_CHECK}" "${FILE}")
    if [[ "${a}${b}" != "11" ]]; then
        echo "  [B052] ERROR: anchors found (want 1 each): TravelMgr.h include ${a}, '// stuck check' ${b}"
        return 1
    fi

    INC="${B052_INCLUDE}" CHK="${B052_CHECK}" TAG="${B052_TAG}" awk '
        $0 == ENVIRON["CHK"] {
            print "    // >>> " ENVIRON["TAG"] " BEGIN"
            print "    // Everland Ghostsong (617e4): a buddy (a bot on a companion account) is"
            print "    // never put onto its destination (its owner) by the stuck recovery"
            print "    // below; the buddy module nudges a stuck buddy instead. The clock is"
            print "    // reset here because SetMoveFarTo zeroes it whenever the owner moves."
            print "    if (CompanionAccounts::Is(bot->GetSession()->GetAccountId()))"
            print "    {"
            print "        botAI->rpgInfo.stuckTs = getMSTime();"
            print "        botAI->rpgInfo.stuckAttempts = 0;"
            print "    }"
            print "    // <<< " ENVIRON["TAG"] " END"
        }
        { print }
        $0 == ENVIRON["INC"] && !inc {
            print "// >>> " ENVIRON["TAG"] " BEGIN"
            print "#include \"CompanionAccounts.h\""
            print "// <<< " ENVIRON["TAG"] " END"
            inc = 1
        }
    ' "${FILE}" > "${FILE}.b052" && mv "${FILE}.b052" "${FILE}"

    local n
    n=$(grep -c "// >>> ${B052_TAG} BEGIN" "${FILE}")
    if [[ "${n}" -ne 2 ]]; then
        echo "  [B052] ERROR: expected 2 inserted blocks (include + stuck check), found ${n}"
        return 1
    fi
    echo "  [B052] Playerbots: buddies' long walks never end in a teleport onto the owner"
}
# }}}

# {{{ unpatch_B052_playerbots_buddies_never_teleport_to_owner
unpatch_B052_playerbots_buddies_never_teleport_to_owner() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/World/Rpg/Action/NewRpgBaseAction.cpp"
    [[ -f "${FILE}" ]] || return 0
    grep -qF "B052-buddies-never-teleport" "${FILE}" || return 0    # nothing of ours
    awk '
        /\/\/ >>> B052-buddies-never-teleport BEGIN/ { inblock = 1; next }
        inblock && /\/\/ <<< B052-buddies-never-teleport END/ { inblock = 0; next }
        inblock { next }
        { print }' "${FILE}" > "${FILE}.b052" && mv "${FILE}.b052" "${FILE}"
    return 0
}
# }}}
# ==== footer of B052 ====
# lines:      105
# ==== end of footer ====
