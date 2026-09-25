#!/usr/bin/env bash
# B032 - A buff can be cast on anyone, whatever the gap between its level and theirs
# Issue 155o (Inscription's scrolls), basic profile.
#
# For a general audience: when a player casts a buff on someone else, the
# stock server looks at the buff's lowest rank. If the target is more than 10
# levels below that rank's level, the target is dropped ("target is too low
# level"). Buffs with many ranks rarely hit this, because their first rank
# is low level; single-rank buffs do. Basic makes every Inscription scroll,
# ranks VII and VIII included (spells of level 70 and 80), usable at 60, so a
# level-60 scribe could read them on themselves but not on a buddy. Ritz,
# 2026-09-24: "sounds like we should make a patch to remove that
# restriction."
#
# What changes: in Spell::prepare's target filtering (Spell.cpp), the rule
# that drops such a target is switched off. The target then receives the
# rank as cast. Picking a lower rank for low-level targets, where a lower
# rank exists, is unchanged.
#
# Mechanics: one line is replaced inside ">>> B032 ... BEGIN" / "<<< B032 ...
# END" marker comments, with the original kept as "//B032-ORIG:<line>"; the
# revert puts exactly that line back. The anchor must occur exactly once or
# the patch stops with an error.
# Parallelizable: Yes (unique file)

B032_BEGIN='// >>> B032-no-buff-level-restriction BEGIN'
B032_END='// <<< B032-no-buff-level-restriction END'
B032_ORIG='                    if (!targetInfo.scaleAura && targetInfo.targetGUID != m_caster->GetGUID())'

# {{{ patch_B032_no_buff_level_restriction
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
# }}}

# {{{ unpatch_B032_no_buff_level_restriction
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
# }}}
