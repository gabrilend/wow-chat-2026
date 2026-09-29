#!/usr/bin/env bash
# B031 - Creatures of level 64 and higher never land crushing blows
# Issue 803 (extension, 2026-09-24), for the basic profile's +4 Outland.
#
# For a general audience: in the stock server, a creature 4 or more levels
# above its target can land "crushing blows", hits for 150% damage. The
# chance grows 10% per level of the gap, so against a level-60 player a
# level-68 creature already crushes on every hit that isn't dodged, parried,
# blocked or missed. Basic raises Outland's creatures to 62–78, which would
# make every Outland tank's life a string of crushes. Ritz, 2026-09-24:
# "let's say that crushing blows do not take effect for creatures level 64
# and higher." Below 64 the stock rule stands (a level-45 creature can still
# crush a level-40 player while levelling).
#
# Kept separate from B005 (the accuracy cap) on purpose, so another profile
# can take one without the other: "they can pull from our patchlist if they
# want. Let's keep them separate so they can be separately applied."
#
# Where: Unit::RollMeleeOutcomeAgainst in Unit.cpp, the crushing branch's
# opening condition gains "and the attacker is below level 64". Players
# never crush (the branch already excludes them).
#
# Mechanics: one line is replaced inside ">>> B031 ... BEGIN" / "<<< B031 ...
# END" marker comments, with the original kept as "//B031-ORIG:<line>"; the
# revert puts exactly that line back. The anchor must occur exactly once or
# the patch stops with an error.
# Parallelizable: Yes (unique file)

B031_BEGIN='// >>> B031-no-crush-64 BEGIN'
B031_END='// <<< B031-no-crush-64 END'
B031_ORIG='    if (getLevelForTarget(victim) >= victim->getLevelForTarget(this) + 4 &&'

# {{{ patch_B031_no_crushing_blows_64
patch_B031_no_crushing_blows_64() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Unit/Unit.cpp"
    [[ -f "${FILE}" ]] || { echo "  [B031] ERROR: ${FILE} missing"; return 1; }
    grep -qF "B031-no-crush-64" "${FILE}" && return 0          # witness guard
    local count
    count=$(grep -cxF -- "${B031_ORIG}" "${FILE}")
    if [[ "${count}" -ne 1 ]]; then
        echo "  [B031] ERROR: expected exactly one crushing-blow condition line in ${FILE}, found ${count}"
        return 1
    fi
    ORIG="${B031_ORIG}" BEGIN_M="${B031_BEGIN}" END_M="${B031_END}" awk '
        $0 == ENVIRON["ORIG"] && !done {
            print "    " ENVIRON["BEGIN_M"]
            print "//B031-ORIG:" $0
            print "    // Everland Ghostsong (issue 803): creatures of level 64 and up never crush"
            print "    if (getLevelForTarget(victim) >= victim->getLevelForTarget(this) + 4 && getLevelForTarget(victim) < 64 &&"
            print "    " ENVIRON["END_M"]
            done = 1; next
        }
        { print }' "${FILE}" > "${FILE}.b031" && mv "${FILE}.b031" "${FILE}"
    echo "  [B031] No crushing blows from creatures level 64+"
}
# }}}

# {{{ unpatch_B031_no_crushing_blows_64
unpatch_B031_no_crushing_blows_64() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Unit/Unit.cpp"
    [[ -f "${FILE}" ]] || return 0
    grep -qF "B031-no-crush-64" "${FILE}" || return 0            # nothing of ours
    awk '
        /\/\/ >>> B031-no-crush-64 BEGIN/ { inblock = 1; next }
        inblock && /^\/\/B031-ORIG:/      { print substr($0, 13); next }   # 12 = length("//B031-ORIG:")
        inblock && /\/\/ <<< B031-no-crush-64 END/ { inblock = 0; next }
        inblock                            { next }
        { print }' "${FILE}" > "${FILE}.b031" && mv "${FILE}.b031" "${FILE}"
    return 0
}
# }}}
