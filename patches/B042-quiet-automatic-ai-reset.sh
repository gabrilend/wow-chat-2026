#!/usr/bin/env bash
# B042 - A bot says "AI was reset to defaults" only when asked to reset
# Issue 617c2 (buddies grouped by distance), 2026-09-29.
#
# For a general audience: the bot module resets a bot's behaviour both when
# its player types the reset command and, automatically, whenever the
# bot's group changes (the server's "group list" and "group set leader"
# messages). Either way the bot whispered "AI was reset to defaults". On
# basic, buddies join and leave their owner's party by distance all the
# time, so the whisper came again and again for nothing the owner did
# (owner, 2026-09-29: 'Sometimes they say "reset to default AI" which
# seems weird' / silence it: "sure."). The reset itself is unchanged; only
# the automatic one is silent. A typed reset still answers.
#
# Mechanics: the one line that whispers is kept inside ">>> B042 ...
# BEGIN" / "<<< B042 ... END" marker comments, behind a test: the
# automatic resets arrive with the server message that caused them, the
# typed one with none. The original line is kept as "//B042-ORIG:<line>"
# for the revert. The anchor must occur exactly once or the patch stops.
# Parallelizable: Yes (unique file)

B042_BEGIN='    // >>> B042-quiet-automatic-ai-reset BEGIN'
B042_END='    // <<< B042-quiet-automatic-ai-reset END'
B042_ANCHOR='    botAI->TellMaster("AI was reset to defaults");'

# {{{ patch_B042_quiet_automatic_ai_reset
patch_B042_quiet_automatic_ai_reset() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Actions/ResetAiAction.cpp"
    [[ -f "${FILE}" ]] || { echo "  [B042] ERROR: ${FILE} missing"; return 1; }
    grep -qF "B042-quiet-automatic-ai-reset" "${FILE}" && return 0     # witness guard
    local a
    a=$(grep -cxF -- "${B042_ANCHOR}" "${FILE}")
    if [[ "${a}" -ne 1 ]]; then
        echo "  [B042] ERROR: expected one '${B042_ANCHOR}' in ${FILE}, found ${a}"
        return 1
    fi
    ANCHOR="${B042_ANCHOR}" BEGIN_M="${B042_BEGIN}" END_M="${B042_END}" awk '
        $0 == ENVIRON["ANCHOR"] {
            print ENVIRON["BEGIN_M"]
            print "//B042-ORIG:" $0
            print "    // Everland Ghostsong (617c2): only a typed reset answers; one caused by a"
            print "    // group change (it arrives with that server message) is silent."
            print "    if (event.getPacket().empty())"
            print "        botAI->TellMaster(\"AI was reset to defaults\");"
            print ENVIRON["END_M"]
            next
        }
        { print }
    ' "${FILE}" > "${FILE}.b042" && mv "${FILE}.b042" "${FILE}"
    echo "  [B042] Automatic AI resets no longer whisper \"AI was reset to defaults\""
}
# }}}

# {{{ unpatch_B042_quiet_automatic_ai_reset
unpatch_B042_quiet_automatic_ai_reset() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Actions/ResetAiAction.cpp"
    [[ -f "${FILE}" ]] || return 0
    grep -qF "B042-quiet-automatic-ai-reset" "${FILE}" || return 0    # nothing of ours
    awk '
        /\/\/ >>> B042-quiet-automatic-ai-reset BEGIN/ { inblock = 1; next }
        inblock && /^\/\/B042-ORIG:/ { sub(/^\/\/B042-ORIG:/, ""); print; next }
        inblock && /\/\/ <<< B042-quiet-automatic-ai-reset END/ { inblock = 0; next }
        inblock { next }
        { print }' "${FILE}" > "${FILE}.b042" && mv "${FILE}.b042" "${FILE}"
    return 0
}
# }}}
