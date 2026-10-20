#!/usr/bin/env bash

B033_BEGIN='// >>> B033-white-no-repair BEGIN'
B033_END='// <<< B033-white-no-repair END'
B033_ANCHOR='    uint32 curDurability = item->GetUInt32Value(ITEM_FIELD_DURABILITY);'

patch_B033_white_gear_never_repaired() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Player/Player.cpp"
    [[ -f "${FILE}" ]] || { echo "  [B033] ERROR: ${FILE} missing"; return 1; }
    grep -qF "B033-white-no-repair" "${FILE}" && return 0      # witness guard
    local count
    count=$(grep -cxF -- "${B033_ANCHOR}" "${FILE}")
    if [[ "${count}" -ne 1 ]]; then
        echo "  [B033] ERROR: expected exactly one durability read in ${FILE}, found ${count}"
        return 1
    fi
    ANCHOR="${B033_ANCHOR}" BEGIN_M="${B033_BEGIN}" END_M="${B033_END}" awk '
        { print }
        $0 == ENVIRON["ANCHOR"] && !done {
            print "    " ENVIRON["BEGIN_M"]
            print "    // Everland Ghostsong (issue 155p): white gear is never repaired"
            print "    if (item->GetTemplate()->Quality == ITEM_QUALITY_NORMAL)"
            print "        return TotalCost;"
            print "    " ENVIRON["END_M"]
            done = 1
        }' "${FILE}" > "${FILE}.b033" && mv "${FILE}.b033" "${FILE}"
    echo "  [B033] White gear is never repaired"
}

unpatch_B033_white_gear_never_repaired() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Player/Player.cpp"
    [[ -f "${FILE}" ]] || return 0
    grep -qF "B033-white-no-repair" "${FILE}" || return 0         # nothing of ours
    awk '
        /\/\/ >>> B033-white-no-repair BEGIN/ { inblock = 1; next }
        inblock && /\/\/ <<< B033-white-no-repair END/ { inblock = 0; next }
        inblock { next }
        { print }' "${FILE}" > "${FILE}.b033" && mv "${FILE}.b033" "${FILE}"
    return 0
}
