#!/usr/bin/env bash

B042_BEGIN='    // >>> B042-quiet-automatic-ai-reset BEGIN'
B042_END='    // <<< B042-quiet-automatic-ai-reset END'
B042_ANCHOR='    botAI->TellMaster("AI was reset to defaults");'

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
