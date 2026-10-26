#!/usr/bin/env bash

B031_BEGIN='// >>> B031-crush-late BEGIN'
B031_END='// <<< B031-crush-late END'
B031_ORIG_COND='    if (getLevelForTarget(victim) >= victim->getLevelForTarget(this) + 4 &&'

patch_B031_crushing_blows_late() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Unit/Unit.cpp"
    [[ -f "${FILE}" ]] || { echo "  [B031] ERROR: ${FILE} missing"; return 1; }
    grep -qF "B031-crush-late" "${FILE}" && return 0          # witness guard
    local count_cond
    count_cond=$(grep -cxF -- "${B031_ORIG_COND}" "${FILE}")
    if [[ "${count_cond}" -ne 1 ]]; then
        echo "  [B031] ERROR: expected exactly one crushing-blow condition line in ${FILE};"
        echo "         found ${count_cond}. Nothing was changed."
        echo "         to debug: has upstream reworded Unit::RollMeleeOutcomeAgainst's crushing branch? Compare the"
        echo "         anchor at the top of this file with the branch under \"mobs can score crushing blows\"."
        return 1
    fi
    COND="${B031_ORIG_COND}" BEGIN_M="${B031_BEGIN}" END_M="${B031_END}" awk '
        $0 == ENVIRON["COND"] && !cond_done {
            print "    " ENVIRON["BEGIN_M"]
            print "//B031-ORIG:" $0
            print "    // Everland Ghostsong (issues 803, 155f1): no crushing blows on basic. A level-60 tank"
            print "    // cannot raise its defence past 300, so nothing would answer them; per-creature"
            print "    // damage multipliers (155i) carry that difficulty instead. The rest of the branch"
            print "    // is left as it was, never entered."
            print "    if (false && getLevelForTarget(victim) >= victim->getLevelForTarget(this) + 4 &&"
            print "    " ENVIRON["END_M"]
            cond_done = 1; next
        }
        { print }' "${FILE}" > "${FILE}.b031" && mv "${FILE}.b031" "${FILE}"
    echo "  [B031] No crushing blows"
}

unpatch_B031_crushing_blows_late() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Unit/Unit.cpp"
    [[ -f "${FILE}" ]] || return 0
    grep -qF "B031-crush-late" "${FILE}" || return 0            # nothing of ours
    awk '
        /\/\/ >>> B031-crush-late BEGIN/  { inblock = 1; next }
        inblock && /^\/\/B031-ORIG:/      { print substr($0, 13); next }   # 12 = length("//B031-ORIG:")
        inblock && /\/\/ <<< B031-crush-late END/ { inblock = 0; next }
        inblock                            { next }
        { print }' "${FILE}" > "${FILE}.b031" && mv "${FILE}.b031" "${FILE}"
    return 0
}
