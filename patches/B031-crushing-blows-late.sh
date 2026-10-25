#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         B031
# profiles:   basic
# priority:   410
# kind:       source
# about:      No crushing blows on basic (was: start 4 levels later)
# ==== end of header ====
# B031 - No crushing blows on basic (named for its earlier rule: start late)
# Issue 803 (extension 2026-09-24, retargeted 2026-09-27), basic profile.
#
# For a general audience: in the stock server, a creature 4 or more levels
# above its target can land "crushing blows", hits for 150% damage. The
# chance grows 10% per level of the gap (25% at 4 levels, 65% at 8), so
# against a level-60 player a level-68 creature already crushes on nearly
# every hit that isn't dodged, parried, blocked or missed. Basic raises
# Outland's creatures to 62-78, which would make every Outland tank's life a
# string of crushes.
#
# History of the rule:
#   2026-09-24  Ritz: "let's say that crushing blows do not take effect for
#               creatures level 64 and higher." (B031 as first built: no
#               crushing from level 64 up; stock below.)
#   2026-09-27  Ritz: "can we re-enable the crushing blow penalty at +4 the
#               level it normally is? And have it scale up to it's nominal
#               percentage with another 4 levels." (none under 8 levels up,
#               1/5 of the stock chance at 8, full at 12.)
#   2026-10-25  The owner, shown that a level-60 tank's defence stops
#               counting at 300, so from level 71 every swing that lands
#               crushes and no gear answers it (issue 155f1,
#               scripts/tank-damage-taken): "let's remove them. There's
#               already crits." (This version.)
#
# The rule now: no creature ever lands a crushing blow on basic. The
# difficulty they added is set per creature instead, through the damage
# multipliers (issue 155i, rows by 155f1).
#
# Kept separate from B005 (the accuracy cap) on purpose, so another profile
# can take one without the other: "they can pull from our patchlist if they
# want. Let's keep them separate so they can be separately applied."
#
# Where: Unit::RollMeleeOutcomeAgainst in Unit.cpp, the crushing branch:
# its opening condition is made always false, so the branch (and its
# chance line, left stock) is never entered. Players never crushed anyway
# (the branch already excluded them).
#
# Mechanics: the condition line is replaced inside ">>> B031 ... BEGIN" /
# "<<< B031 ... END" marker comments, with the original kept as
# "//B031-ORIG:<line>"; the revert puts exactly that line back. The anchor
# must occur exactly once or the patch stops with an error, having changed
# nothing.
# Parallelizable: Yes (unique file)

B031_BEGIN='// >>> B031-crush-late BEGIN'
B031_END='// <<< B031-crush-late END'
B031_ORIG_COND='    if (getLevelForTarget(victim) >= victim->getLevelForTarget(this) + 4 &&'

# {{{ patch_B031_crushing_blows_late
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
# }}}

# {{{ unpatch_B031_crushing_blows_late
unpatch_B031_crushing_blows_late() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Unit/Unit.cpp"
    [[ -f "${FILE}" ]] || return 0
    grep -qF "B031-crush-late" "${FILE}" || return 0            # nothing of ours
    # Each marked block becomes its one original line again.
    awk '
        /\/\/ >>> B031-crush-late BEGIN/  { inblock = 1; next }
        inblock && /^\/\/B031-ORIG:/      { print substr($0, 13); next }   # 12 = length("//B031-ORIG:")
        inblock && /\/\/ <<< B031-crush-late END/ { inblock = 0; next }
        inblock                            { next }
        { print }' "${FILE}" > "${FILE}.b031" && mv "${FILE}.b031" "${FILE}"
    return 0
}
# }}}
# ==== footer of B031 ====
# lines:      106
# ==== end of footer ====
