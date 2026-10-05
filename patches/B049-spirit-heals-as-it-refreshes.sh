#!/usr/bin/env bash
# B049 - Spirit heals as it refreshes
# Issue 167 (basic, 2026-10-04).
#
# For a general audience: out of combat, health comes back every 2 seconds
# from spirit by one table and mana from spirit and intellect by another;
# for a caster the mana figure is far the larger. The owner, 2026-10-04:
# "can we add a patch that makes spirit restore hp5 equal to the amount of
# mana it would restore if the character wasn't casting?" Now a character
# whose spirit gives mana regains, each 2-second health tick, the mana its
# spirit would give back in those 2 seconds out of casting: square root of
# intellect x spirit x the class's mana-per-spirit ratio, x 2. Warriors,
# rogues and death knights (ratio 0) keep the stock rate. The rest of
# health regeneration (out of combat only, sitting +33%, regeneration
# effects) is untouched; it calls this function.
#
# Mechanics, one file, one insertion inside ">>> B049 ... BEGIN" /
# "<<< B049 ... END" marker comments:
#   Player.cpp   Player::OCTRegenHPPerSpirit returns the mana-from-spirit
#                figure x 2 first, when the class has a mana-per-spirit
#                ratio above 0 (Player::OCTRegenMPPerSpirit, which is
#                spirit x that ratio).
# The anchor must occur exactly once or the patch stops with an error.
# Parallelizable: Yes

B049_BEGIN='// >>> B049-spirit-heals-as-it-refreshes BEGIN'
B049_END='// <<< B049-spirit-heals-as-it-refreshes END'
B049_ANCHOR='    // Formula from PaperDollFrame script'

# {{{ patch_B049_spirit_heals_as_it_refreshes
patch_B049_spirit_heals_as_it_refreshes() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Player/Player.cpp"
    [[ -f "${FILE}" ]] || { echo "  [B049] ERROR: Player.cpp missing under ${AC_CODE_DIR}"; return 1; }
    grep -qF "B049-spirit-heals-as-it-refreshes" "${FILE}" && return 0      # witness guard

    local a
    a=$(grep -cxF -- "${B049_ANCHOR}" "${FILE}")
    if [[ "${a}" != "1" ]]; then
        echo "  [B049] ERROR: anchor found ${a} times in Player.cpp (want 1): the health-per-spirit formula comment"
        return 1
    fi

    ANCHOR="${B049_ANCHOR}" BEGIN_M="${B049_BEGIN}" END_M="${B049_END}" awk '
        $0 == ENVIRON["ANCHOR"] {
            print "    " ENVIRON["BEGIN_M"]
            print "    // Everland Ghostsong (issue 167): spirit heals, each 2-second tick, what it"
            print "    // would give back as mana in 2 seconds out of casting (sqrt(intellect) x"
            print "    // spirit x the mana-per-spirit ratio, as UpdateManaRegen reckons it)."
            print "    // A class whose spirit gives no mana (ratio 0) keeps the stock rate below."
            print "    if (float manaPerSecond = std::sqrt(GetStat(STAT_INTELLECT)) * OCTRegenMPPerSpirit(); manaPerSecond > 0.0f)"
            print "        return manaPerSecond * 2.0f;"
            print "    " ENVIRON["END_M"]
        }
        { print }
    ' "${FILE}" > "${FILE}.b049" && mv "${FILE}.b049" "${FILE}"

    echo "  [B049] Spirit heals each tick what it would give back as mana out of casting (Player::OCTRegenHPPerSpirit)"
}
# }}}

# {{{ unpatch_B049_spirit_heals_as_it_refreshes
unpatch_B049_spirit_heals_as_it_refreshes() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Player/Player.cpp"
    [[ -f "${FILE}" ]] || return 0
    grep -qF "B049-spirit-heals-as-it-refreshes" "${FILE}" || return 0     # nothing of ours
    awk '
        /\/\/ >>> B049-spirit-heals-as-it-refreshes BEGIN/ { inblock = 1; next }
        inblock && /\/\/ <<< B049-spirit-heals-as-it-refreshes END/ { inblock = 0; next }
        inblock { next }
        { print }' "${FILE}" > "${FILE}.b049" && mv "${FILE}.b049" "${FILE}"
    return 0
}
# }}}
