#!/usr/bin/env bash

B052_TAG='B052-buddies-never-teleport'
B052_INCLUDE='#include "TravelMgr.h"'
B052_CHECK='    // stuck check'

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
