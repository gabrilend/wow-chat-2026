#!/usr/bin/env bash

B035_TAG='B035-respec-cost'
B035_ANCHOR='uint32 Player::resetTalentsCost() const'

patch_B035_respec_cost_weekly() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Player/Player.cpp"
    [[ -f "${FILE}" ]] || { echo "  [B035] ERROR: ${FILE} missing"; return 1; }
    grep -qF "${B035_TAG}" "${FILE}" && return 0                  # witness guard
    local count
    count=$(grep -cxF -- "${B035_ANCHOR}" "${FILE}")
    if [[ "${count}" -ne 1 ]]; then
        echo "  [B035] ERROR: expected exactly one '${B035_ANCHOR}' in ${FILE}, found ${count}"
        return 1
    fi
    ANCHOR="${B035_ANCHOR}" awk '
        { print }
        $0 == ENVIRON["ANCHOR"] { armed = 1; next }
        armed && $0 == "{" {
            print "    // >>> B035-respec-cost BEGIN"
            print "    // Everland Ghostsong (issue 155r): 1, 5, 10 gold, then 10 gold more each"
            print "    // respec without a cap; one 10-gold step off per weekly reset since the"
            print "    // last respec, never below 10 gold."
            print "    {"
            print "        if (m_resetTalentsCost < 1 * GOLD)"
            print "            return 1 * GOLD;"
            print "        if (m_resetTalentsCost < 5 * GOLD)"
            print "            return 5 * GOLD;"
            print "        if (m_resetTalentsCost < 10 * GOLD)"
            print "            return 10 * GOLD;"
            print "        // weekly resets between the last respec and now: the last reset was a"
            print "        // week before the next one the server has scheduled"
            print "        int64 lastWeeklyReset = int64(sWorld->GetNextWeeklyQuestsResetTime().count()) - int64(WEEK);"
            print "        int64 resets = 0;"
            print "        if (lastWeeklyReset > int64(m_resetTalentsTime))"
            print "            resets = (lastWeeklyReset - int64(m_resetTalentsTime)) / int64(WEEK) + 1;"
            print "        if (resets > 0)"
            print "        {"
            print "            int64 dropped = int64(m_resetTalentsCost) - int64(10 * GOLD) * resets;"
            print "            return dropped < int64(10 * GOLD) ? uint32(10 * GOLD) : uint32(dropped);"
            print "        }"
            print "        return m_resetTalentsCost + 10 * GOLD;"
            print "    }"
            print "    // <<< B035-respec-cost END"
            armed = 0
        }' "${FILE}" > "${FILE}.b035" && mv "${FILE}.b035" "${FILE}"
    echo "  [B035] Respec cost: no cap, falls on the weekly reset"
}

unpatch_B035_respec_cost_weekly() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Player/Player.cpp"
    [[ -f "${FILE}" ]] || return 0
    grep -qF "B035-respec-cost" "${FILE}" || return 0             # nothing of ours
    awk '
        /\/\/ >>> B035-respec-cost BEGIN/ { inblock = 1; next }
        inblock && /\/\/ <<< B035-respec-cost END/ { inblock = 0; next }
        inblock { next }
        { print }' "${FILE}" > "${FILE}.b035" && mv "${FILE}.b035" "${FILE}"
    return 0
}
