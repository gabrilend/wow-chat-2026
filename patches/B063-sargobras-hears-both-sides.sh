#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         B063
# profiles:   basic
# priority:   730
# kind:       source
# about:      a whisper to Sargobras crosses the faction line; every other whisper still doesn't (issue 617b2)
# ==== end of header ====
# B063 - Sargobras hears both sides
#
# For a general audience: players whisper Sargobras to choose their buddies
# from afar (issue 617b2). There is one Sargobras, and he serves the Horde
# and the Alliance alike, but basic refuses whispers between the factions
# (AllowTwoSide.Interaction.Chat = 0). The owner, 2026-10-30, asked one
# character or two: "one character, patched faction rule." This lets a
# whisper whose receiver is named Sargobras through the faction test;
# every other cross-faction whisper is refused as before. His answers go
# back by the server's own whisper, which never tests faction.
#
# Mechanics: one line in ChatHandler.cpp, the cross-faction test in the
# whisper branch of HandleMessagechatOpcode, given one more condition
# between ">>> B063" / "<<< B063" marker comments; the unpatch puts the line
# back exactly.
#   the test found once: patched
#   not found once: upstream changed it; stops, naming the file
#   markers already there: nothing to do

B063_BEGIN='// >>> B063-sargobras-hears-both-sides BEGIN'
B063_END='// <<< B063-sargobras-hears-both-sides END'
B063_LINE='                if (!sWorld->getBoolConfig(CONFIG_ALLOW_TWO_SIDE_INTERACTION_CHAT) && senderIsPlayer && receiverIsPlayer)'

# {{{ patch_B063_sargobras_hears_both_sides
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
# }}}

# {{{ unpatch_B063_sargobras_hears_both_sides
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
# }}}
# ==== footer of B063 ====
# lines:      74
# ==== end of footer ====
