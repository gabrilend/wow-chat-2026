#!/usr/bin/env bash
# B031 - Crushing blows start 4 levels later and ramp in over 4 more
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
#               percentage with another 4 levels." (This version.)
#
# The rule now, for creatures of every level:
#   level gap (creature over target) under 8   no crushing blows
#   gap 8 to 11                                the stock chance x (gap - 7) / 5
#                                              (1/5 at 8, 2/5 at 9, 3/5 at 10,
#                                              4/5 at 11)
#   gap 12 and up                              the stock chance
# "+4 the level it normally is": the stock start is 4, so crushing starts
# at 8. "scale up to it's nominal percentage with another 4 levels": full
# strength at 12. The factor starts at 1/5 rather than 0 so that a creature
# 8 levels up really can crush (a ramp from 0 at 8 would only start at 9).
# A crushing blow still does 150% damage (stock, untouched).
# docs/patches/crushing-blows-late.md has the table of chances.
#
# Kept separate from B005 (the accuracy cap) on purpose, so another profile
# can take one without the other: "they can pull from our patchlist if they
# want. Let's keep them separate so they can be separately applied."
#
# Where: Unit::RollMeleeOutcomeAgainst in Unit.cpp, the crushing branch:
#   1. its opening condition: "+ 4" levels becomes "+ 8";
#   2. its chance line (2% per point of weapon skill over defense, minus
#      15%, in hundredths of a percent) gains the ramp factor below a gap
#      of 12. Players never crush (the branch already excludes them).
#
# Mechanics: each of the two lines is replaced inside ">>> B031 ... BEGIN" /
# "<<< B031 ... END" marker comments, with the original kept as
# "//B031-ORIG:<line>"; the revert puts exactly those lines back. Each
# anchor must occur exactly once or the patch stops with an error, having
# changed nothing.
# Parallelizable: Yes (unique file)

B031_BEGIN='// >>> B031-crush-late BEGIN'
B031_END='// <<< B031-crush-late END'
B031_ORIG_COND='    if (getLevelForTarget(victim) >= victim->getLevelForTarget(this) + 4 &&'
B031_ORIG_CHANCE='            tmp = tmp * 200 - 1500;'

# {{{ patch_B031_crushing_blows_late
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
