#!/usr/bin/env bash

B045_TAG='B045-companions-take-no-commands'
B045_INCLUDE='#include "PlayerbotAI.h"'
B045_FN_LANG='void PlayerbotAI::HandleCommand(uint32 type, std::string const& text, Player& fromPlayer, const uint32 lang)'
B045_FN_PTR='void PlayerbotAI::HandleCommand(uint32 type, std::string const text, Player* fromPlayer)'

patch_B045_playerbots_companions_take_no_commands() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/PlayerbotAI.cpp"
    local HEADER="${AC_CODE_DIR}/src/server/game/Cache/CompanionAccounts.h"
    [[ -f "${FILE}" ]] || { echo "  [B045] ERROR: ${FILE} missing"; return 1; }
    [[ -f "${HEADER}" ]] || { echo "  [B045] ERROR: ${HEADER} missing (B044 must be applied first)"; return 1; }
    grep -qF "${B045_TAG}" "${FILE}" && return 0                  # witness guard

    local a b c
    a=$(grep -cxF -- "${B045_INCLUDE}" "${FILE}")
    b=$(grep -cxF -- "${B045_FN_LANG}" "${FILE}")
    c=$(grep -cxF -- "${B045_FN_PTR}" "${FILE}")
    if [[ "${a}${b}${c}" != "111" ]]; then
        echo "  [B045] ERROR: anchors found (want 1 each): PlayerbotAI.h include ${a}," \
             "HandleCommand(..., lang) ${b}, HandleCommand(..., Player*) ${c}"
        return 1
    fi

    INC="${B045_INCLUDE}" FN1="${B045_FN_LANG}" FN2="${B045_FN_PTR}" TAG="${B045_TAG}" awk '
        { print }
        $0 == ENVIRON["INC"] && !inc {
            print "// >>> " ENVIRON["TAG"] " BEGIN"
            print "#include \"CompanionAccounts.h\""
            print "// <<< " ENVIRON["TAG"] " END"
            inc = 1
        }
        $0 == ENVIRON["FN1"] || $0 == ENVIRON["FN2"] { infn = 1; next }
        infn && $0 == "{" {
            print "    // >>> " ENVIRON["TAG"] " BEGIN"
            print "    // Everland Ghostsong (issue 617a5): a buddy (a bot on a companion account)"
            print "    // runs on its own rules and takes no chat commands; other bots as stock."
            print "    if (bot && CompanionAccounts::Is(bot->GetSession()->GetAccountId()))"
            print "        return;"
            print "    // <<< " ENVIRON["TAG"] " END"
        }
        { infn = 0 }
    ' "${FILE}" > "${FILE}.b045" && mv "${FILE}.b045" "${FILE}"

    local n
    n=$(grep -c "// >>> ${B045_TAG} BEGIN" "${FILE}")
    if [[ "${n}" -ne 3 ]]; then
        echo "  [B045] ERROR: expected 3 inserted blocks (include + 2 handlers), found ${n}"
        return 1
    fi

    echo "  [B045] Playerbots: bots on companion accounts take no chat commands"
}

unpatch_B045_playerbots_companions_take_no_commands() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/PlayerbotAI.cpp"
    [[ -f "${FILE}" ]] || return 0
    grep -qF "B045-companions-take-no-commands" "${FILE}" || return 0    # nothing of ours
    awk '
        /\/\/ >>> B045-companions-take-no-commands BEGIN/ { inblock = 1; next }
        inblock && /\/\/ <<< B045-companions-take-no-commands END/ { inblock = 0; next }
        inblock { next }
        { print }' "${FILE}" > "${FILE}.b045" && mv "${FILE}.b045" "${FILE}"
    return 0
}
