#!/usr/bin/env bash

B031_BEGIN='// >>> B031-crush-late BEGIN'
B031_END='// <<< B031-crush-late END'
B031_ORIG_COND='    if (getLevelForTarget(victim) >= victim->getLevelForTarget(this) + 4 &&'
B031_ORIG_CHANCE='            tmp = tmp * 200 - 1500;'

patch_B031_crushing_blows_late() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Unit/Unit.cpp"
    [[ -f "${FILE}" ]] || { echo "  [B031] ERROR: ${FILE} missing"; return 1; }
    grep -qF "B031-crush-late" "${FILE}" && return 0          # witness guard
    local count_cond count_chance
    count_cond=$(grep -cxF -- "${B031_ORIG_COND}" "${FILE}")
    count_chance=$(grep -cxF -- "${B031_ORIG_CHANCE}" "${FILE}")
    if [[ "${count_cond}" -ne 1 || "${count_chance}" -ne 1 ]]; then
        echo "  [B031] ERROR: expected exactly one crushing-blow condition line and one chance line in ${FILE};"
        echo "         found ${count_cond} condition line(s) and ${count_chance} chance line(s). Nothing was changed."
        echo "         to debug: has upstream reworded Unit::RollMeleeOutcomeAgainst's crushing branch? Compare the"
        echo "         two anchors at the top of this file with the branch under \"mobs can score crushing blows\"."
        return 1
    fi
    COND="${B031_ORIG_COND}" CHANCE="${B031_ORIG_CHANCE}" BEGIN_M="${B031_BEGIN}" END_M="${B031_END}" awk '
        $0 == ENVIRON["COND"] && !cond_done {
            print "    " ENVIRON["BEGIN_M"]
            print "//B031-ORIG:" $0
            print "    // Everland Ghostsong (issue 803): crushing blows start at 8 levels above the target, not 4"
            print "    if (getLevelForTarget(victim) >= victim->getLevelForTarget(this) + 8 &&"
            print "    " ENVIRON["END_M"]
            cond_done = 1; next
        }
        $0 == ENVIRON["CHANCE"] && !chance_done {
            print "            " ENVIRON["BEGIN_M"]
            print "//B031-ORIG:" $0
            print "            // Everland Ghostsong (issue 803): the stock chance, ramped in over gaps 8-11:"
            print "            // x (gap - 7) / 5, so 1/5 at 8 up to 4/5 at 11; full from 12"
            print "            tmp = tmp * 200 - 1500;"
            print "            if (int32 b031Gap = int32(getLevelForTarget(victim)) - int32(victim->getLevelForTarget(this)); b031Gap < 12)"
            print "                tmp = tmp * (b031Gap - 7) / 5;"
            print "            " ENVIRON["END_M"]
            chance_done = 1; next
        }
        { print }' "${FILE}" > "${FILE}.b031" && mv "${FILE}.b031" "${FILE}"
    echo "  [B031] Crushing blows from 8 levels above, ramping to stock at 12"
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
