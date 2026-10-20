#!/usr/bin/env bash

B049_TAG='B049-spirit-heals-by-stamina'
B049_BEGIN="// >>> ${B049_TAG} BEGIN"
B049_END="// <<< ${B049_TAG} END"
B049_H_ANCHOR='    [[nodiscard]] bool IsUnderLastManaUseEffect() const;'
B049_U_ANCHOR='    damage = sScriptMgr->DealDamage(attacker, victim, damage, damagetype);'
B049_U_DEF='bool Unit::IsUnderLastManaUseEffect() const'
B049_P_FORMULA='    // Formula from PaperDollFrame script'
B049_P_TICK='        // Not in combat or they have regeneration'
B049_P_ALWAYS='    // always regeneration bonus (including combat)'

_b049_files() {
    B049_H="${AC_CODE_DIR}/src/server/game/Entities/Unit/Unit.h"
    B049_U="${AC_CODE_DIR}/src/server/game/Entities/Unit/Unit.cpp"
    B049_P="${AC_CODE_DIR}/src/server/game/Entities/Player/Player.cpp"
}

patch_B049_spirit_heals_by_stamina() {
    _b049_files
    local f
    for f in "${B049_H}" "${B049_U}" "${B049_P}"; do
        [[ -f "${f}" ]] || { echo "  [B049] ERROR: ${f} missing"; return 1; }
    done
    grep -qF "${B049_TAG}" "${B049_P}" && return 0      # witness guard

    local a b c d e g
    a=$(grep -cxF -- "${B049_H_ANCHOR}"  "${B049_H}" || true)
    b=$(grep -cxF -- "${B049_U_ANCHOR}"  "${B049_U}" || true)
    g=$(grep -cxF -- "${B049_U_DEF}"     "${B049_U}" || true)
    c=$(grep -cxF -- "${B049_P_FORMULA}" "${B049_P}" || true)
    d=$(grep -cxF -- "${B049_P_TICK}"    "${B049_P}" || true)
    e=$(grep -cxF -- "${B049_P_ALWAYS}"  "${B049_P}" || true)
    if [[ "${a}${b}${g}${c}${d}${e}" != "111111" ]]; then
        echo "  [B049] ERROR: anchors found (want 1 each): Unit.h mana rule ${a}, Unit.cpp damage hook ${b}, mana rule definition ${g}," \
             "Player.cpp spirit formula ${c}, regen tick ${d}, always-bonus ${e}"
        return 1
    fi

    ANCHOR="${B049_H_ANCHOR}" BEGIN_M="${B049_BEGIN}" END_M="${B049_END}" awk '
        { print }
        $0 == ENVIRON["ANCHOR"] {
            print "    " ENVIRON["BEGIN_M"]
            print "    // Everland Ghostsong (issue 167): the mana rule'"'"'s twin for health. When"
            print "    // this unit last took damage (ms game time, 0 = never), and whether that was"
            print "    // under 5 seconds ago: spirit heals a player at half rate then."
            print "    void SetLastHurt(uint32 hurtTime) { m_lastHurt = hurtTime; }"
            print "    [[nodiscard]] bool IsUnderLastHurtEffect() const;"
            print "    uint32 m_lastHurt = 0;                              // msecs"
            print "    " ENVIRON["END_M"]
        }' "${B049_H}" > "${B049_H}.b049" && mv "${B049_H}.b049" "${B049_H}"

    ANCHOR="${B049_U_ANCHOR}" DEF="${B049_U_DEF}" BEGIN_M="${B049_BEGIN}" END_M="${B049_END}" awk '
        $0 == ENVIRON["DEF"] {
            print ENVIRON["BEGIN_M"]
            print "// Everland Ghostsong (issue 167): as IsUnderLastManaUseEffect below, for damage taken."
            print "bool Unit::IsUnderLastHurtEffect() const"
            print "{"
            print "    return m_lastHurt && getMSTimeDiff(m_lastHurt, GameTime::GetGameTimeMS().count()) < 5000;"
            print "}"
            print ""
            print ENVIRON["END_M"]
        }
        { print }
        $0 == ENVIRON["ANCHOR"] {
            print "    " ENVIRON["BEGIN_M"]
            print "    // Everland Ghostsong (issue 167): taking damage starts the 5 seconds of"
            print "    // half-rate healing from spirit (IsUnderLastHurtEffect)."
            print "    if (damage > 0)"
            print "        victim->SetLastHurt(GameTime::GetGameTimeMS().count());"
            print "    " ENVIRON["END_M"]
        }' "${B049_U}" > "${B049_U}.b049" && mv "${B049_U}.b049" "${B049_U}"

    FORMULA="${B049_P_FORMULA}" TICK="${B049_P_TICK}" ALWAYS="${B049_P_ALWAYS}" BEGIN_M="${B049_BEGIN}" END_M="${B049_END}" awk '
        $0 == ENVIRON["FORMULA"] {
            print "    " ENVIRON["BEGIN_M"]
            print "    // Everland Ghostsong (issue 167): every class alike, health per 5 seconds ="
            print "    // spirit x stamina / 100, given per 2-second tick (x 2/5); half for 5 seconds"
            print "    // after taking damage. The stock tables below are not reached."
            print "    {"
            print "        float perTick = GetStat(STAT_SPIRIT) * GetStat(STAT_STAMINA) / 100.0f * 2.0f / 5.0f;"
            print "        if (IsUnderLastHurtEffect())"
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
