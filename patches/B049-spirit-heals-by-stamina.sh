#!/usr/bin/env bash
# B049 - Spirit heals by stamina, in combat too
# Issue 167 (basic, 2026-10-04).
#
# For a general audience: stock, spirit gives back health only out of
# combat, through per-class tables (warriors much more than casters). The
# owner, 2026-10-04: every class alike, "make that rate equal to about
# 1/100th of the amount of stamina ... a tank with 300 stamina would get
# 3hp5 per spirit, so 300 spirit means 900hp per 5 seconds", and "in
# combat too. Interrupted by taking damage, and recovers at 50%, just like
# spirit does with mana". So: health per 5 seconds = spirit x stamina /
# 100, given every 2-second tick as 2/5 of it, in and out of combat; for
# 5 seconds after taking damage, half. Sitting (+33%) and health
# regeneration effects apply as before.
#
# Mechanics, three files, every edit an insertion inside ">>> B049 ...
# BEGIN" / "<<< B049 ... END" marker comments:
#   Player.h    the player keeps when it was last hurt (game time in
#               milliseconds, 0 = never). Player.h is included almost
#               everywhere: the next compile rebuilds most of the server.
#   Unit.cpp    damage dealt to a player sets it (after the server's own
#               damage hooks, which may have changed the amount).
#   Player.cpp  OCTRegenHPPerSpirit returns the stamina rule (halved when
#               hurt within 5 s) before the stock tables; the 2-second tick
#               also runs for a player in combat whom the stock check would
#               skip; RegenerateHealth adds the spirit part in combat (out of
#               combat its stock branch already adds it).
# Anchors must occur exactly once or the patch stops with an error.
# Parallelizable: No (Player.h)

B049_TAG='B049-spirit-heals-by-stamina'
B049_BEGIN="// >>> ${B049_TAG} BEGIN"
B049_END="// <<< ${B049_TAG} END"
B049_H_ANCHOR='    void RegenerateHealth();'
B049_U_ANCHOR='    damage = sScriptMgr->DealDamage(attacker, victim, damage, damagetype);'
B049_P_FORMULA='    // Formula from PaperDollFrame script'
B049_P_TICK='        // Not in combat or they have regeneration'
B049_P_ALWAYS='    // always regeneration bonus (including combat)'

# {{{ _b049_files
_b049_files() {
    B049_H="${AC_CODE_DIR}/src/server/game/Entities/Player/Player.h"
    B049_U="${AC_CODE_DIR}/src/server/game/Entities/Unit/Unit.cpp"
    B049_P="${AC_CODE_DIR}/src/server/game/Entities/Player/Player.cpp"
}
# }}}

# {{{ patch_B049_spirit_heals_by_stamina
patch_B049_spirit_heals_by_stamina() {
    _b049_files
    local f
    for f in "${B049_H}" "${B049_U}" "${B049_P}"; do
        [[ -f "${f}" ]] || { echo "  [B049] ERROR: ${f} missing"; return 1; }
    done
    grep -qF "${B049_TAG}" "${B049_P}" && return 0      # witness guard

    local a b c d e
    a=$(grep -cxF -- "${B049_H_ANCHOR}"  "${B049_H}")
    b=$(grep -cxF -- "${B049_U_ANCHOR}"  "${B049_U}")
    c=$(grep -cxF -- "${B049_P_FORMULA}" "${B049_P}")
    d=$(grep -cxF -- "${B049_P_TICK}"    "${B049_P}")
    e=$(grep -cxF -- "${B049_P_ALWAYS}"  "${B049_P}")
    if [[ "${a}${b}${c}${d}${e}" != "11111" ]]; then
        echo "  [B049] ERROR: anchors found (want 1 each): Player.h RegenerateHealth ${a}, Unit.cpp damage hook ${b}," \
             "Player.cpp spirit formula ${c}, regen tick ${d}, always-bonus ${e}"
        return 1
    fi

    # Player.h: the last-hurt time, after the RegenerateHealth declaration
    ANCHOR="${B049_H_ANCHOR}" BEGIN_M="${B049_BEGIN}" END_M="${B049_END}" awk '
        { print }
        $0 == ENVIRON["ANCHOR"] {
            print "    " ENVIRON["BEGIN_M"]
            print "    // Everland Ghostsong (issue 167): when this player last took damage (game"
            print "    // time, ms; 0 = never). Set in Unit::DealDamage; spirit heals at half rate"
            print "    // for 5 seconds after it."
            print "    uint64 m_everlandHurtAt = 0;"
            print "    " ENVIRON["END_M"]
        }' "${B049_H}" > "${B049_H}.b049" && mv "${B049_H}.b049" "${B049_H}"

    # Unit.cpp: damage dealt to a player marks it hurt
    ANCHOR="${B049_U_ANCHOR}" BEGIN_M="${B049_BEGIN}" END_M="${B049_END}" awk '
        { print }
        $0 == ENVIRON["ANCHOR"] {
            print "    " ENVIRON["BEGIN_M"]
            print "    // Everland Ghostsong (issue 167): a player taking damage heals by spirit"
            print "    // at half rate for the next 5 seconds."
            print "    if (damage > 0)"
            print "        if (Player* hurt = victim->ToPlayer())"
            print "            hurt->m_everlandHurtAt = GameTime::GetGameTimeMS().count();"
            print "    " ENVIRON["END_M"]
        }' "${B049_U}" > "${B049_U}.b049" && mv "${B049_U}.b049" "${B049_U}"

    # Player.cpp: the formula, the in-combat tick, the in-combat spirit part
    FORMULA="${B049_P_FORMULA}" TICK="${B049_P_TICK}" ALWAYS="${B049_P_ALWAYS}" BEGIN_M="${B049_BEGIN}" END_M="${B049_END}" awk '
        $0 == ENVIRON["FORMULA"] {
            print "    " ENVIRON["BEGIN_M"]
            print "    // Everland Ghostsong (issue 167): every class alike, health per 5 seconds ="
            print "    // spirit x stamina / 100, given per 2-second tick (x 2/5); half for 5 seconds"
            print "    // after taking damage. The stock tables below are not reached."
            print "    {"
            print "        float perTick = GetStat(STAT_SPIRIT) * GetStat(STAT_STAMINA) / 100.0f * 2.0f / 5.0f;"
            print "        if (m_everlandHurtAt && GameTime::GetGameTimeMS().count() - m_everlandHurtAt < 5000)"
            print "            perTick *= 0.5f;"
            print "        return perTick;"
            print "    }"
            print "    " ENVIRON["END_M"]
        }
        $0 == ENVIRON["TICK"] {
            print "        " ENVIRON["BEGIN_M"]
            print "        // Everland Ghostsong (issue 167): spirit heals in combat too; a fighting"
            print "        // player the stock check below would skip still gets its tick (the two"
            print "        // conditions never both hold, so the tick runs once)."
            print "        if (IsInCombat() && !IsPolymorphed() && !m_baseHealthRegen &&"
            print "                !HasRegenDuringCombatAura() && !HasHealthRegenInCombatAura())"
            print "            RegenerateHealth();"
            print "        " ENVIRON["END_M"]
        }
        $0 == ENVIRON["ALWAYS"] {
            print "    " ENVIRON["BEGIN_M"]
            print "    // Everland Ghostsong (issue 167): in combat, the spirit part too (out of"
            print "    // combat the branch above already added it); sitting and regeneration"
            print "    // effects as there."
            print "    if (IsInCombat() && !IsPolymorphed())"
            print "    {"
            print "        float fighting = OCTRegenHPPerSpirit() * HealthIncreaseRate;"
            print "        if (!IsStandState())"
            print "            fighting *= 1.33f;"
            print "        addvalue += fighting * GetTotalAuraMultiplier(SPELL_AURA_MOD_HEALTH_REGEN_PERCENT);"
            print "    }"
            print "    " ENVIRON["END_M"]
        }
        { print }' "${B049_P}" > "${B049_P}.b049" && mv "${B049_P}.b049" "${B049_P}"

    echo "  [B049] Spirit heals by stamina (spirit x stamina / 100 per 5 s), in combat too, half for 5 s after damage"
}
# }}}

# {{{ unpatch_B049_spirit_heals_by_stamina
unpatch_B049_spirit_heals_by_stamina() {
    _b049_files
    local f
    for f in "${B049_H}" "${B049_U}" "${B049_P}"; do
        [[ -f "${f}" ]] || continue
        grep -qF "${B049_TAG}" "${f}" || continue        # nothing of ours in this file
        TAG="${B049_TAG}" awk '
            index($0, ">>> " ENVIRON["TAG"] " BEGIN") { inblock = 1; next }
            inblock && index($0, "<<< " ENVIRON["TAG"] " END") { inblock = 0; next }
            inblock { next }
            { print }' "${f}" > "${f}.b049" && mv "${f}.b049" "${f}"
    done
    return 0
}
# }}}
