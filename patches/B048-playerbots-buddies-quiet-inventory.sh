#!/usr/bin/env bash

B048_BEGIN='// >>> B048-buddies-quiet-inventory BEGIN'
B048_END='// <<< B048-buddies-quiet-inventory END'
B048_INCLUDE='#include "Playerbots.h"'
B048_MASTER_CHECK='    if (!botAI->GetMaster())'

patch_B048_playerbots_buddies_quiet_inventory() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Actions/InventoryChangeFailureAction.cpp"
    [[ -f "${FILE}" ]] || { echo "  [B048] ERROR: InventoryChangeFailureAction.cpp missing under ${AC_CODE_DIR}"; return 1; }
    [[ -f "${AC_CODE_DIR}/src/server/game/Cache/CompanionAccounts.h" ]] || { echo "  [B048] ERROR: B044's CompanionAccounts.h is missing; B044 must come first"; return 1; }
    grep -qF "B048-buddies-quiet-inventory" "${FILE}" && return 0      # witness guard

    local a b
    a=$(grep -cxF -- "${B048_INCLUDE}" "${FILE}")
    b=$(grep -cxF -- "${B048_MASTER_CHECK}" "${FILE}")
    if [[ "${a}${b}" != "11" ]]; then
        echo "  [B048] ERROR: anchors found in InventoryChangeFailureAction.cpp (want 1 each): Playerbots.h include ${a}, master check ${b}"
        return 1
    fi

    INC="${B048_INCLUDE}" CHECK="${B048_MASTER_CHECK}" BEGIN_M="${B048_BEGIN}" END_M="${B048_END}" awk '
        $0 == ENVIRON["CHECK"] {
            print "    " ENVIRON["BEGIN_M"]
            print "    // Everland Ghostsong (issue 617h1): a buddy never whispers about a failed"
            print "    // item move; full bags send it to a vendor instead."
            print "    if (CompanionAccounts::Is(bot->GetSession()->GetAccountId()))"
            print "        return false;"
            print "    " ENVIRON["END_M"]
        }
        { print }
        $0 == ENVIRON["INC"] && !inc {
            print ENVIRON["BEGIN_M"]
            print "#include \"CompanionAccounts.h\""
            print ENVIRON["END_M"]
            inc = 1
        }
    ' "${FILE}" > "${FILE}.b048" && mv "${FILE}.b048" "${FILE}"

    echo "  [B048] Buddies don't whisper their owner about failed item moves (InventoryChangeFailureAction)"
}

unpatch_B048_playerbots_buddies_quiet_inventory() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Actions/InventoryChangeFailureAction.cpp"
    [[ -f "${FILE}" ]] || return 0
    grep -qF "B048-buddies-quiet-inventory" "${FILE}" || return 0     # nothing of ours
    awk '
        /\/\/ >>> B048-buddies-quiet-inventory BEGIN/ { inblock = 1; next }
        inblock && /\/\/ <<< B048-buddies-quiet-inventory END/ { inblock = 0; next }
        inblock { next }
        { print }' "${FILE}" > "${FILE}.b048" && mv "${FILE}.b048" "${FILE}"
    return 0
}
