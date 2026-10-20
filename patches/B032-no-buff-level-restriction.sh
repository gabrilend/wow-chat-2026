#!/usr/bin/env bash

B032_BEGIN='// >>> B032-no-buff-level-restriction BEGIN'
B032_END='// <<< B032-no-buff-level-restriction END'
B032_ORIG='                    if (!targetInfo.scaleAura && targetInfo.targetGUID != m_caster->GetGUID())'

patch_B032_no_buff_level_restriction() {
    local FILE="${AC_CODE_DIR}/src/server/game/Spells/Spell.cpp"
    [[ -f "${FILE}" ]] || { echo "  [B032] ERROR: ${FILE} missing"; return 1; }
    grep -qF "B032-no-buff-level-restriction" "${FILE}" && return 0      # witness guard
    local count
    count=$(grep -cxF -- "${B032_ORIG}" "${FILE}")
    if [[ "${count}" -ne 1 ]]; then
        echo "  [B032] ERROR: expected exactly one buff level check line in ${FILE}, found ${count}"
        return 1
    fi
    ORIG="${B032_ORIG}" BEGIN_M="${B032_BEGIN}" END_M="${B032_END}" awk '
        $0 == ENVIRON["ORIG"] && !done {
            print "                    " ENVIRON["BEGIN_M"]
            print "//B032-ORIG:" $0
            print "                    // Everland Ghostsong (issue 155o): never drop a target for being too low level for the buff"
            print "                    if (false && !targetInfo.scaleAura && targetInfo.targetGUID != m_caster->GetGUID())"
            print "                    " ENVIRON["END_M"]
            done = 1; next
        }
        { print }' "${FILE}" > "${FILE}.b032" && mv "${FILE}.b032" "${FILE}"
    echo "  [B032] Buffs castable on targets of any level"
}

unpatch_B032_no_buff_level_restriction() {
    local FILE="${AC_CODE_DIR}/src/server/game/Spells/Spell.cpp"
    [[ -f "${FILE}" ]] || return 0
    grep -qF "B032-no-buff-level-restriction" "${FILE}" || return 0    # nothing of ours
    awk '
        /\/\/ >>> B032-no-buff-level-restriction BEGIN/ { inblock = 1; next }
        inblock && /^\/\/B032-ORIG:/                    { print substr($0, 13); next }   # 12 = length("//B032-ORIG:")
        inblock && /\/\/ <<< B032-no-buff-level-restriction END/ { inblock = 0; next }
        inblock                                          { next }
        { print }' "${FILE}" > "${FILE}.b032" && mv "${FILE}.b032" "${FILE}"
    return 0
}
