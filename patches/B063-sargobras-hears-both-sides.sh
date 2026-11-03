#!/usr/bin/env bash

B063_BEGIN='// >>> B063-sargobras-hears-both-sides BEGIN'
B063_END='// <<< B063-sargobras-hears-both-sides END'
B063_LINE='                if (!sWorld->getBoolConfig(CONFIG_ALLOW_TWO_SIDE_INTERACTION_CHAT) && senderIsPlayer && receiverIsPlayer)'

patch_B063_sargobras_hears_both_sides() {
    local FILE="${AC_CODE_DIR}/src/server/game/Handlers/ChatHandler.cpp"
    [[ -f "${FILE}" ]] || { echo "  [B063] ERROR: ${FILE} is missing"; return 1; }
    grep -qF "${B063_BEGIN}" "${FILE}" && return 0      # already patched
    local found
    found="$(grep -cxF "${B063_LINE}" "${FILE}")"
    if [[ "${found}" != "1" ]]; then
        echo "  [B063] ERROR: expected the line '${B063_LINE}' once in ${FILE}, found it ${found} times"
        echo "         to debug: has upstream changed the cross-faction whisper test in HandleMessagechatOpcode?"
        return 1
    fi
    LINE="${B063_LINE}" BEGIN_M="${B063_BEGIN}" END_M="${B063_END}" awk '
        $0 == ENVIRON["LINE"] {
            print "                " ENVIRON["BEGIN_M"]
            print "                // basic: a whisper to Sargobras (one character for both"
            print "                // factions, issue 617b2) is let through; the rest are tested"
            print "                if (!sWorld->getBoolConfig(CONFIG_ALLOW_TWO_SIDE_INTERACTION_CHAT) && senderIsPlayer && receiverIsPlayer"
            print "                    && receiver->GetName() != \"Sargobras\")"
            print "                " ENVIRON["END_M"]
            next
        }
        { print }' "${FILE}" > "${FILE}.b063" && mv "${FILE}.b063" "${FILE}"
    grep -qF "${B063_BEGIN}" "${FILE}" || { echo "  [B063] ERROR: the change did not land in ${FILE}"; return 1; }
    echo "  [B063] Applied: Sargobras hears both sides"
}

unpatch_B063_sargobras_hears_both_sides() {
    local FILE="${AC_CODE_DIR}/src/server/game/Handlers/ChatHandler.cpp"
    [[ -f "${FILE}" ]] || return 0
    grep -qF "${B063_BEGIN}" "${FILE}" || return 0
    LINE="${B063_LINE}" B="${B063_BEGIN}" E="${B063_END}" awk '
        index($0, ENVIRON["B"]) { skip = 1; print ENVIRON["LINE"]; next }
        skip { if (index($0, ENVIRON["E"])) skip = 0; next }
        { print }' "${FILE}" > "${FILE}.b063" && mv "${FILE}.b063" "${FILE}"
    echo "  [B063] Reverted"
}
