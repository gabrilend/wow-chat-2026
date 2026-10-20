#!/usr/bin/env bash

B050_TAG='B050-buddy-spirit-worth'
B050_BEGIN="// >>> ${B050_TAG} BEGIN"
B050_END="// <<< ${B050_TAG} END"
B050_INCLUDE='#include "Unit.h"'
B050_LAST_STEP='    ApplyWeightFinetune(player);'

patch_B050_playerbots_buddy_spirit_worth() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Mgr/Item/StatsWeightCalculator.cpp"
    [[ -f "${FILE}" ]] || { echo "  [B050] ERROR: StatsWeightCalculator.cpp missing under ${AC_CODE_DIR}"; return 1; }
    grep -qF "${B050_TAG}" "${FILE}" && return 0          # witness guard

    local a b
    a=$(grep -cxF -- "${B050_INCLUDE}"   "${FILE}")
    b=$(grep -cxF -- "${B050_LAST_STEP}" "${FILE}")
    if [[ "${a}${b}" != "11" ]]; then
        echo "  [B050] ERROR: anchors found in StatsWeightCalculator.cpp (want 1 each): Unit.h include ${a}, ApplyWeightFinetune call ${b}"
        return 1
    fi

    INC="${B050_INCLUDE}" LAST="${B050_LAST_STEP}" BEGIN_M="${B050_BEGIN}" END_M="${B050_END}" awk '
        { print }
        $0 == ENVIRON["INC"] {
            print ENVIRON["BEGIN_M"]
            print "// Everland Ghostsong (issue 617j3): what one spirit is worth in stamina to a"
            print "// buddy right now; negative for anyone else. Defined in the buddy module"
            print "// (modules/mod-buddies, buddies_loot.cpp)."
            print "float BuddySpiritWorth(Player* player);"
            print ENVIRON["END_M"]
        }
        $0 == ENVIRON["LAST"] {
            print "    " ENVIRON["BEGIN_M"]
            print "    // Everland Ghostsong (issue 617j3): spirit also heals by stamina (issue 167);"
            print "    // a buddy weighs that in, by its stats as they stand, on top of the stock"
            print "    // weight (which values spirit for mana)."
            print "    if (float worth = BuddySpiritWorth(player); worth > 0.0f)"
            print "        stats_weights_[STATS_TYPE_SPIRIT] += stats_weights_[STATS_TYPE_STAMINA] * worth;"
            print "    " ENVIRON["END_M"]
        }' "${FILE}" > "${FILE}.b050" && mv "${FILE}.b050" "${FILE}"

    echo "  [B050] A buddy weighs spirit by what it heals against stamina (StatsWeightCalculator)"
}

unpatch_B050_playerbots_buddy_spirit_worth() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Mgr/Item/StatsWeightCalculator.cpp"
    [[ -f "${FILE}" ]] || return 0
    grep -qF "${B050_TAG}" "${FILE}" || return 0         # nothing of ours
    TAG="${B050_TAG}" awk '
        index($0, ">>> " ENVIRON["TAG"] " BEGIN") { inblock = 1; next }
        inblock && index($0, "<<< " ENVIRON["TAG"] " END") { inblock = 0; next }
        inblock { next }
        { print }' "${FILE}" > "${FILE}.b050" && mv "${FILE}.b050" "${FILE}"
    return 0
}
