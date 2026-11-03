#!/usr/bin/env bash

B067_BEGIN='// >>> B067-radius-seen-hook BEGIN'
B067_END='// <<< B067-radius-seen-hook END'
B067_SIGNATURE='void Player::UpdateVisibilityOf(T* target, UpdateData& data,'
B067_FIRST='    GetMap()->AddObjectToPendingUpdateList(target);'

patch_B067_radius_seen_hook() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Player/PlayerUpdates.cpp"
    [[ -f "${FILE}" ]] || { echo "  [B067] ERROR: PlayerUpdates.cpp missing under ${AC_CODE_DIR}"; return 1; }
    grep -qF "B067-radius-seen-hook" "${FILE}" && return 0         # witness guard

    local a b
    a=$(grep -cxF -- "${B067_SIGNATURE}" "${FILE}")
    b=$(grep -cxF -- "${B067_FIRST}" "${FILE}")
    if [[ "${a}${b}" != "11" ]]; then
        echo "  [B067] ERROR: anchors found in PlayerUpdates.cpp (want 1 each): the batched UpdateVisibilityOf ${a}, its first line ${b}"
        return 1
    fi

    SIG="${B067_SIGNATURE}" FIRST="${B067_FIRST}" BEGIN_M="${B067_BEGIN}" END_M="${B067_END}" awk '
        held != "" && $0 == ENVIRON["SIG"] {
            print ENVIRON["BEGIN_M"]
            print "// Everland Ghostsong (issue 165): set by a module that wants to hear"
            print "// \"this thing is near this player\" as the server works it out (mod-buddies,"
            print "// buddies_board.cpp); empty by default."
            print "void (*RadiusSeenHook)(Player* seer, WorldObject* target) = nullptr;"
            print ENVIRON["END_M"]
            print held
            held = ""
            print
            next
        }
        held != "" { print held; held = "" }
        $0 == "template <class T>" { held = $0; next }
        { print }
        $0 == ENVIRON["FIRST"] {
            print "    " ENVIRON["BEGIN_M"]
            print "    if (RadiusSeenHook)"
            print "        RadiusSeenHook(this, target);"
            print "    " ENVIRON["END_M"]
        }
        END { if (held != "") print held }
    ' "${FILE}" > "${FILE}.b067" && mv "${FILE}.b067" "${FILE}"

    if [[ "$(grep -c "B067-radius-seen-hook" "${FILE}")" != "4" ]]; then
        echo "  [B067] ERROR: the patch did not land in both places in PlayerUpdates.cpp"
        return 1
    fi
    echo "  [B067] A hook in the server's \"what this player sees\" pass (PlayerUpdates.cpp)"
}

unpatch_B067_radius_seen_hook() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Player/PlayerUpdates.cpp"
    [[ -f "${FILE}" ]] || return 0
    grep -qF "B067-radius-seen-hook" "${FILE}" || return 0          # nothing of ours
    awk '
        /\/\/ >>> B067-radius-seen-hook BEGIN/ { inblock = 1; next }
        inblock && /\/\/ <<< B067-radius-seen-hook END/ { inblock = 0; next }
        inblock { next }
        { print }' "${FILE}" > "${FILE}.b067" && mv "${FILE}.b067" "${FILE}"
    return 0
}
