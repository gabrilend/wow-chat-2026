#!/usr/bin/env bash
# B045 - Playerbots: a bot on a companion account takes no chat commands
# Issue 617a5 (basic, 2026-10-02).
#
# For a general audience: the bot module lets a bot's master steer it by
# chat: whisper or party-say "follow", "stay", "attack", and dozens more. On
# basic the bots are buddies, who run on their own rules (mod-buddies), and
# the owner decided (617a, 2026-09-25) that a buddy ignores those commands;
# the language-model layer reaches the same actions later as tool calls
# (917 / 617m), not through chat. This patch makes the bot module drop every
# chat command sent to a bot whose account is on the companion list (B044's
# CompanionAccounts, filled by mod-buddies). Bots on other accounts, random
# bots included, are unchanged; so is chat itself (a whisper still arrives,
# it just isn't read as a command).
#
# Where: every chat path into a bot (whisper, party, guild, channel) ends in
# one of the two PlayerbotAI::HandleCommand overloads, so the test sits at
# the top of each. The module's own internal callers of HandleCommand chain
# from a chat command (the "cast" command re-issuing itself), so for a buddy
# they are never reached.
#
# Mechanics: pure insertions between ">>> B045-companions-take-no-commands
# BEGIN" / "<<< ... END" marker comments, after anchors that must each occur
# exactly once (else the patch stops); the revert deletes the blocks.
# Requires: B044 (the CompanionAccounts header it includes).
# Needs: B044 (its CompanionAccounts.h)
# Parallelizable: No (needs B044 applied first)

B045_TAG='B045-companions-take-no-commands'
B045_INCLUDE='#include "PlayerbotAI.h"'
# 2026-10-09: upstream wrote "const std::string&" as "std::string const&" (playerbots
# 037c0141); the anchor follows it. Found on a clean tree at the new commits.
B045_FN_LANG='void PlayerbotAI::HandleCommand(uint32 type, std::string const& text, Player& fromPlayer, const uint32 lang)'
B045_FN_PTR='void PlayerbotAI::HandleCommand(uint32 type, std::string const text, Player* fromPlayer)'

# {{{ patch_B045_playerbots_companions_take_no_commands
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

    # Each overload's opening brace is followed by the test. `bot` is checked
    # because the first overload's stock code checks it on its next line.
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
# }}}

# {{{ unpatch_B045_playerbots_companions_take_no_commands
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
# }}}
