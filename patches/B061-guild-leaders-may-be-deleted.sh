#!/usr/bin/env bash

B061_BEGIN='// >>> B061-guild-leaders-may-be-deleted BEGIN'
B061_END='// <<< B061-guild-leaders-may-be-deleted END'
B061_LINE='    if (sGuildMgr->GetGuildByLeader(guid))'

patch_B061_guild_leaders_may_be_deleted() {
    local FILE="${AC_CODE_DIR}/src/server/game/Handlers/CharacterHandler.cpp"
    [[ -f "${FILE}" ]] || { echo "  [B061] ERROR: ${FILE} is missing"; return 1; }
    grep -qF "${B061_BEGIN}" "${FILE}" && return 0      # already patched
    local found
    found="$(grep -cxF "${B061_LINE}" "${FILE}")"
    if [[ "${found}" != "1" ]]; then
        echo "  [B061] ERROR: expected the line '${B061_LINE}' once in ${FILE}, found it ${found} times"
        echo "         to debug: has upstream changed the guild-leader test in HandleCharDeleteOpcode?"
        return 1
    fi
    LINE="${B061_LINE}" BEGIN_M="${B061_BEGIN}" END_M="${B061_END}" awk '
        $0 == ENVIRON["LINE"] {
            print "    " ENVIRON["BEGIN_M"]
            print "    // basic: a guild leader may be deleted (every player leads its"
            print "    // buddies'"'"' clan); the guild passes on or is disbanded as it loses"
            print "    // its leader (Guild::DeleteMember), the clan with its owner"
            print "    if (false && sGuildMgr->GetGuildByLeader(guid))"
            print "    " ENVIRON["END_M"]
            next
        }
        { print }' "${FILE}" > "${FILE}.b061" && mv "${FILE}.b061" "${FILE}"
    grep -qF "${B061_BEGIN}" "${FILE}" || { echo "  [B061] ERROR: the change did not land in ${FILE}"; return 1; }
    echo "  [B061] Applied: guild leaders may be deleted"
}

unpatch_B061_guild_leaders_may_be_deleted() {
    local FILE="${AC_CODE_DIR}/src/server/game/Handlers/CharacterHandler.cpp"
    [[ -f "${FILE}" ]] || return 0
    grep -qF "${B061_BEGIN}" "${FILE}" || return 0
    LINE="${B061_LINE}" B="${B061_BEGIN}" E="${B061_END}" awk '
        index($0, ENVIRON["B"]) { skip = 1; print ENVIRON["LINE"]; next }
        skip { if (index($0, ENVIRON["E"])) skip = 0; next }
        { print }' "${FILE}" > "${FILE}.b061" && mv "${FILE}.b061" "${FILE}"
    echo "  [B061] Reverted"
}
