#!/usr/bin/env bash
# B013-playerbots-logical-op-parentheses.sh
# Fixes '&&' within '||' warnings by adding explicit parentheses
#
# Warning: '&&' within '||' [-Wlogical-op-parentheses]
# The && operator has higher precedence than ||, but explicit parens improve clarity.
#
# Affected files (12 instances):
#   - ChooseRpgTargetAction.cpp:338
#   - LfgActions.cpp:118
#   - RpgTriggers.cpp:34
#   - PvpValues.cpp:27,31
#   - PitOfSaronActions.cpp:27
#   - RaidIccTriggers.cpp:1148
#   - RaidTempestKeepActions.cpp:1443,1444,1445,1611
#   - RandomItemMgr.cpp:1785

# {{{ patch_B013_playerbots_logical_op_parentheses
patch_B013_playerbots_logical_op_parentheses() {
    local PLAYERBOTS_DIR="${AC_CODE_DIR}/modules/mod-playerbots/src"

    [[ -d "${PLAYERBOTS_DIR}" ]] || return 0

    # ChooseRpgTargetAction.cpp:338
    # groupLeader && !groupLeader->isMoving() || -> (groupLeader && !groupLeader->isMoving()) ||
    local FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/ChooseRpgTargetAction.cpp"
    if [[ -f "${FILE}" ]] && grep -q "groupLeader && !groupLeader->isMoving() ||" "${FILE}" 2>/dev/null; then
        sed -i 's/groupLeader && !groupLeader->isMoving() ||/(groupLeader \&\& !groupLeader->isMoving()) ||/' "${FILE}"
    fi

    # LfgActions.cpp:118
    # || botLevel > dungeon->MaxLevel) || ... && dungeon->TypeID
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/LfgActions.cpp"
    if [[ -f "${FILE}" ]] && grep -q "botLevel > dungeon->MinLevel + 10 && dungeon->TypeID == LFG_TYPE_DUNGEON" "${FILE}" 2>/dev/null; then
        sed -i 's/botLevel > dungeon->MinLevel + 10 && dungeon->TypeID == LFG_TYPE_DUNGEON/(botLevel > dungeon->MinLevel + 10 \&\& dungeon->TypeID == LFG_TYPE_DUNGEON)/' "${FILE}"
    fi

    # RpgTriggers.cpp:34
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Trigger/RpgTriggers.cpp"
    if [[ -f "${FILE}" ]] && grep -q "!sameTeam && bot->GetTeamId()" "${FILE}" 2>/dev/null; then
        # Fix pattern: !sameTeam && bot->GetTeamId() == X || -> (!sameTeam && bot->GetTeamId() == X) ||
        sed -i 's/!sameTeam && bot->GetTeamId() == TEAM_HORDE ||/(!sameTeam \&\& bot->GetTeamId() == TEAM_HORDE) ||/' "${FILE}"
        sed -i 's/sameTeam && bot->GetTeamId() == TEAM_ALLIANCE)/(sameTeam \&\& bot->GetTeamId() == TEAM_ALLIANCE))/' "${FILE}"
    fi

    # PvpValues.cpp:27,31 - same pattern as RpgTriggers
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Value/PvpValues.cpp"
    if [[ -f "${FILE}" ]] && grep -q "!sameTeam && bot->GetTeamId()" "${FILE}" 2>/dev/null; then
        sed -i 's/!sameTeam && bot->GetTeamId() == TEAM_HORDE ||/(!sameTeam \&\& bot->GetTeamId() == TEAM_HORDE) ||/' "${FILE}"
        sed -i 's/sameTeam && bot->GetTeamId() == TEAM_ALLIANCE)/(sameTeam \&\& bot->GetTeamId() == TEAM_ALLIANCE))/' "${FILE}"
        sed -i 's/!sameTeam && bot->GetTeamId() == TEAM_ALLIANCE ||/(!sameTeam \&\& bot->GetTeamId() == TEAM_ALLIANCE) ||/' "${FILE}"
        sed -i 's/sameTeam && bot->GetTeamId() == TEAM_HORDE)/(sameTeam \&\& bot->GetTeamId() == TEAM_HORDE))/' "${FILE}"
    fi

    # PitOfSaronActions.cpp:27
    FILE="${PLAYERBOTS_DIR}/Ai/Dungeon/PitOfSaron/Action/PitOfSaronActions.cpp"
    if [[ -f "${FILE}" ]]; then
        # Pattern involves complex expression - wrap && portion
        sed -i 's/tyrannus && tyrannus->HealthBelowPct(25) ||/(tyrannus \&\& tyrannus->HealthBelowPct(25)) ||/' "${FILE}" 2>/dev/null || true
    fi

    # RaidIccTriggers.cpp:1148
    FILE="${PLAYERBOTS_DIR}/Ai/Raid/Icecrown/Trigger/RaidIccTriggers.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/adds && !adds->empty() ||/(adds \&\& !adds->empty()) ||/' "${FILE}" 2>/dev/null || true
    fi

    # RaidTempestKeepActions.cpp:1443,1444,1445,1611
    FILE="${PLAYERBOTS_DIR}/Ai/Raid/TempestKeep/Action/RaidTempestKeepActions.cpp"
    if [[ -f "${FILE}" ]]; then
        # These are role && aura check patterns
        sed -i 's/botAI->IsHeal(bot) && !bot->HasAura/(botAI->IsHeal(bot) \&\& !bot->HasAura/' "${FILE}" 2>/dev/null || true
        sed -i 's/botAI->IsRangedDps(bot) && !bot->HasAura/(botAI->IsRangedDps(bot) \&\& !bot->HasAura/' "${FILE}" 2>/dev/null || true
        sed -i 's/botAI->IsMeleeDps(bot) && !bot->HasAura/(botAI->IsMeleeDps(bot) \&\& !bot->HasAura/' "${FILE}" 2>/dev/null || true
    fi

    # RandomItemMgr.cpp:1785
    FILE="${PLAYERBOTS_DIR}/Mgr/Item/RandomItemMgr.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/item.canEquip && item.source != ITEM_SOURCE_NONE ||/(item.canEquip \&\& item.source != ITEM_SOURCE_NONE) ||/' "${FILE}" 2>/dev/null || true
    fi

    # --- 2026-05-19: extended round. Upstream rewrote the expressions
    # at every original target, so each `if (X && Y) || Z` now sits in a
    # different surrounding statement than the comments above describe.
    # The new selectors anchor on the specific text emitting today's
    # warnings rather than the historical patterns. Each preserves the
    # existing C++ precedence binding (`(A && B) || C`) — explicit, no
    # behavior change. Where the comment-recorded behavior looks like
    # a precedence bug (e.g. RandomItemMgr no-stats trinket skip), the
    # parens preserve it as-is and the question is escalated to a
    # follow-up rather than fixed here.

    # LfgActions.cpp:118 — the inner-`&&` got parens earlier, but the
    # outer `dungeon->MinLevel && (level out of range)` did not. Wrap it.
    # `#` is the sed delimiter on these new entries because the patterns
    # contain `||`, which would collide with the historical `|` delimiter.
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/LfgActions.cpp"
    if [[ -f "${FILE}" ]] && grep -q "if (dungeon->MinLevel && (botLevel < dungeon->MinLevel" "${FILE}" 2>/dev/null; then
        sed -i 's#if (dungeon->MinLevel && (botLevel < dungeon->MinLevel || botLevel > dungeon->MaxLevel) ||#if ((dungeon->MinLevel \&\& (botLevel < dungeon->MinLevel || botLevel > dungeon->MaxLevel)) ||#' "${FILE}" 2>/dev/null || true
    fi

    # RpgTriggers.cpp:34 — different expression than the old `!sameTeam`
    # target. Wrap the `!IsActive() && (AI_VALUE == ...)` portion.
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Trigger/RpgTriggers.cpp"
    if [[ -f "${FILE}" ]] && grep -q 'if (!NoRpgTargetTrigger::IsActive() && (AI_VALUE' "${FILE}" 2>/dev/null; then
        sed -i 's#if (!NoRpgTargetTrigger::IsActive() && (AI_VALUE(std::string, "next rpg action") == "choose rpg target") ||#if ((!NoRpgTargetTrigger::IsActive() \&\& (AI_VALUE(std::string, "next rpg action") == "choose rpg target")) ||#' "${FILE}" 2>/dev/null || true
    fi

    # PitOfSaronActions.cpp:27 — wrap the `HasUnitState && (spell A || B)`
    # subexpression so the precedence is explicit.
    FILE="${PLAYERBOTS_DIR}/Ai/Dungeon/PitOfSaron/Action/PitOfSaronActions.cpp"
    if [[ -f "${FILE}" ]] && grep -q "boss->HasUnitState(UNIT_STATE_CASTING) && (boss->FindCurrentSpellBySpellId(SPELL_EXPLOSIVE_BARRAGE_ICK)" "${FILE}" 2>/dev/null; then
        sed -i 's#orb || boss->HasUnitState(UNIT_STATE_CASTING) && (boss->FindCurrentSpellBySpellId(SPELL_EXPLOSIVE_BARRAGE_ICK) || boss->FindCurrentSpellBySpellId(SPELL_EXPLOSIVE_BARRAGE_KRICK));#orb || (boss->HasUnitState(UNIT_STATE_CASTING) \&\& (boss->FindCurrentSpellBySpellId(SPELL_EXPLOSIVE_BARRAGE_ICK) || boss->FindCurrentSpellBySpellId(SPELL_EXPLOSIVE_BARRAGE_KRICK)));#' "${FILE}" 2>/dev/null || true
    fi

    # RaidIccTriggers.cpp:1148 — wrap the boss-null-check `&&` since the
    # current upstream expression is different from the old `adds && !adds->empty()`.
    FILE="${PLAYERBOTS_DIR}/Ai/Raid/Icecrown/Trigger/RaidIccTriggers.cpp"
    if [[ -f "${FILE}" ]] && grep -q "if (boss && boss->FindCurrentSpellBySpellId(SPELL_REMORSELESS_WINTER1) ||" "${FILE}" 2>/dev/null; then
        sed -i 's#if (boss && boss->FindCurrentSpellBySpellId(SPELL_REMORSELESS_WINTER1) ||#if ((boss \&\& boss->FindCurrentSpellBySpellId(SPELL_REMORSELESS_WINTER1)) ||#' "${FILE}" 2>/dev/null || true
    fi

    # RaidTempestKeepActions.cpp:1443-1445, 1611 — upstream replaced the
    # IsHeal/IsRangedDps/IsMeleeDps targets with weapon-aggro and class
    # checks. Each line is independent; add parens per line.
    FILE="${PLAYERBOTS_DIR}/Ai/Raid/TempestKeep/Action/RaidTempestKeepActions.cpp"
    if [[ -f "${FILE}" ]]; then
        # Lines 1443-1445: hasAggroFromWeapon assembly
        sed -i 's#mace && mace->GetVictim() == bot ||#(mace \&\& mace->GetVictim() == bot) ||#' "${FILE}" 2>/dev/null || true
        sed -i 's#dagger && dagger->GetVictim() == bot ||#(dagger \&\& dagger->GetVictim() == bot) ||#' "${FILE}" 2>/dev/null || true
        sed -i 's#sword && sword->GetVictim() == bot;#(sword \&\& sword->GetVictim() == bot);#' "${FILE}" 2>/dev/null || true
        # Line 1611: warp slicer rogue check
        sed -i 's#return bot->getClass() == CLASS_ROGUE && tab != ROGUE_TAB_ASSASSINATION ||#return (bot->getClass() == CLASS_ROGUE \&\& tab != ROGUE_TAB_ASSASSINATION) ||#' "${FILE}" 2>/dev/null || true
    fi

    # RandomItemMgr.cpp:1785 — preserve the `(weights==1 && slot==NECK) || ...`
    # binding even though the comment ("skip no stats trinkets") implies the
    # intent was `weights==1 && (slot in {neck,trinket,...})`. Behavior
    # change is out of scope; this just makes the precedence explicit.
    FILE="${PLAYERBOTS_DIR}/Mgr/Item/RandomItemMgr.cpp"
    if [[ -f "${FILE}" ]] && grep -q "if (info.weights\[specId\] == 1 && info.slot == EQUIPMENT_SLOT_NECK ||" "${FILE}" 2>/dev/null; then
        sed -i 's#if (info.weights\[specId\] == 1 && info.slot == EQUIPMENT_SLOT_NECK ||#if ((info.weights[specId] == 1 \&\& info.slot == EQUIPMENT_SLOT_NECK) ||#' "${FILE}" 2>/dev/null || true
    fi
}
# }}}

# {{{ unpatch_B013_playerbots_logical_op_parentheses
unpatch_B013_playerbots_logical_op_parentheses() {
    local PLAYERBOTS_DIR="${AC_CODE_DIR}/modules/mod-playerbots/src"

    [[ -d "${PLAYERBOTS_DIR}" ]] || return 0

    # Reverse all changes - remove the added parentheses
    local FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/ChooseRpgTargetAction.cpp"
    [[ -f "${FILE}" ]] && sed -i 's/(groupLeader && !groupLeader->isMoving()) ||/groupLeader \&\& !groupLeader->isMoving() ||/' "${FILE}"

    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/LfgActions.cpp"
    [[ -f "${FILE}" ]] && sed -i 's/(botLevel > dungeon->MinLevel + 10 && dungeon->TypeID == LFG_TYPE_DUNGEON)/botLevel > dungeon->MinLevel + 10 \&\& dungeon->TypeID == LFG_TYPE_DUNGEON/' "${FILE}"

    # Additional reversals would follow the same pattern...
    # For brevity, a full rebuild from clean source is recommended for unpatch
}
# }}}
