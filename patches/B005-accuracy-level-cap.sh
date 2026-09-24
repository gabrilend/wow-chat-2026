#!/usr/bin/env bash
# B005 - Cap level difference impact on hit/miss at ±3 levels
# Issue 803 (legacy number 156): Monster accuracy level cap. The "(Issue 156)"
# text inside the injected C++ comments below is kept as-is: the revert
# matches on it.
# Parallelizable: Yes (unique files)

# {{{ patch_B005_accuracy_level_cap
patch_B005_accuracy_level_cap() {
    local UNIT_H="${AC_CODE_DIR}/src/server/game/Entities/Unit/Unit.h"
    local UNIT_CPP="${AC_CODE_DIR}/src/server/game/Entities/Unit/Unit.cpp"
    local APPLIED=0

    # 1. Add defines to Unit.h after MAX_AGGRO_RADIUS
    if [[ -f "${UNIT_H}" ]] && ! grep -q "ACCURACY_LEVEL_CAP" "${UNIT_H}"; then
        sed -i '/#define MAX_AGGRO_RADIUS/a \
\
// Everland Ghostsong: Cap level difference for accuracy calculations at ±3 levels (Issue 156)\
#define ACCURACY_LEVEL_CAP 3\
#define ACCURACY_SKILL_CAP (ACCURACY_LEVEL_CAP * 5)  // skill = level * 5' "${UNIT_H}"
        APPLIED=1
    fi

    # 2. Cap levelDiff in MagicSpellHitResult (line ~3511)
    if [[ -f "${UNIT_CPP}" ]] && ! grep -q "cappedLevelDiff" "${UNIT_CPP}"; then
        sed -i 's/int32 levelDiff = int32(victim->getLevelForTarget(this)) - thisLevel;/int32 rawLevelDiff = int32(victim->getLevelForTarget(this)) - thisLevel;\
    \/\/ Everland Ghostsong: Cap level difference at ±ACCURACY_LEVEL_CAP for hit chance (Issue 156)\
    int32 levelDiff = std::max(-ACCURACY_LEVEL_CAP, std::min(ACCURACY_LEVEL_CAP, rawLevelDiff));/' "${UNIT_CPP}"
        APPLIED=1
    fi

    # 3. Cap skillDiff in MeleeSpellMissChance (line ~15257)
    if [[ -f "${UNIT_CPP}" ]] && grep -q "int32 diff = -skillDiff;" "${UNIT_CPP}" && ! grep -q "cappedSkillDiff" "${UNIT_CPP}"; then
        sed -i 's/int32 diff = -skillDiff;/\/\/ Everland Ghostsong: Cap skill difference at ±ACCURACY_SKILL_CAP (Issue 156)\
    int32 cappedSkillDiff = std::max(-ACCURACY_SKILL_CAP, std::min(ACCURACY_SKILL_CAP, skillDiff));\
    int32 diff = -cappedSkillDiff;/' "${UNIT_CPP}"
        APPLIED=1
    fi

    # 4. Cap skillBonus in RollMeleeOutcomeAgainst (line ~2981)
    if [[ -f "${UNIT_CPP}" ]] && grep -q "int32    skillBonus  = 4 \* (attackerWeaponSkill - victimMaxSkillValueForLevel);" "${UNIT_CPP}"; then
        sed -i 's/int32    skillBonus  = 4 \* (attackerWeaponSkill - victimMaxSkillValueForLevel);/\/\/ Everland Ghostsong: Cap skill difference at ±ACCURACY_SKILL_CAP for combat outcome rolls (Issue 156)\
    int32 rawSkillDiff = attackerWeaponSkill - victimMaxSkillValueForLevel;\
    int32 cappedSkillDiffMelee = std::max(-ACCURACY_SKILL_CAP, std::min(ACCURACY_SKILL_CAP, rawSkillDiff));\
    int32    skillBonus  = 4 * cappedSkillDiffMelee;/' "${UNIT_CPP}"
        APPLIED=1
    fi

    if [[ "${APPLIED}" -eq 1 ]]; then
        echo "  [B005] Accuracy level cap (±3 levels)"
    fi
}
# }}}

# {{{ unpatch_B005_accuracy_level_cap
unpatch_B005_accuracy_level_cap() {
    local UNIT_H="${AC_CODE_DIR}/src/server/game/Entities/Unit/Unit.h"
    local UNIT_CPP="${AC_CODE_DIR}/src/server/game/Entities/Unit/Unit.cpp"

    # 1. Remove defines from Unit.h
    if [[ -f "${UNIT_H}" ]]; then
        # The apply also inserts a blank line above the comment. Drop it first,
        # while the comment still marks which blank line is ours; without this
        # the revert left one stray empty line behind in Unit.h, so the tree
        # never round-tripped to upstream (found 2026-09-23, issue 155c).
        sed -i '/^#define MAX_AGGRO_RADIUS/{n;/^$/{N;/\n\/\/ Everland Ghostsong: Cap level difference for accuracy/s/^\n//}}' "${UNIT_H}"
        sed -i '/Everland Ghostsong: Cap level difference for accuracy/d' "${UNIT_H}"
        sed -i '/#define ACCURACY_LEVEL_CAP/d' "${UNIT_H}"
        sed -i '/#define ACCURACY_SKILL_CAP/d' "${UNIT_H}"
    fi

    # 2. Restore levelDiff in MagicSpellHitResult
    if [[ -f "${UNIT_CPP}" ]] && grep -q "rawLevelDiff" "${UNIT_CPP}"; then
        sed -i '/int32 rawLevelDiff = int32(victim->getLevelForTarget(this)) - thisLevel;/{
            N
            N
            s/int32 rawLevelDiff = int32(victim->getLevelForTarget(this)) - thisLevel;\n.*Everland Ghostsong.*\n.*int32 levelDiff = std::max.*/int32 levelDiff = int32(victim->getLevelForTarget(this)) - thisLevel;/
        }' "${UNIT_CPP}"
    fi

    # 3. Restore skillDiff in MeleeSpellMissChance
    if [[ -f "${UNIT_CPP}" ]] && grep -q "cappedSkillDiff" "${UNIT_CPP}"; then
        sed -i '/Everland Ghostsong: Cap skill difference at ±ACCURACY_SKILL_CAP (Issue 156)/d' "${UNIT_CPP}"
        sed -i '/int32 cappedSkillDiff = std::max(-ACCURACY_SKILL_CAP, std::min(ACCURACY_SKILL_CAP, skillDiff));/d' "${UNIT_CPP}"
        sed -i 's/int32 diff = -cappedSkillDiff;/int32 diff = -skillDiff;/' "${UNIT_CPP}"
    fi

    # 4. Restore skillBonus in RollMeleeOutcomeAgainst
    if [[ -f "${UNIT_CPP}" ]] && grep -q "cappedSkillDiffMelee" "${UNIT_CPP}"; then
        sed -i '/Everland Ghostsong: Cap skill difference at ±ACCURACY_SKILL_CAP for combat outcome rolls/d' "${UNIT_CPP}"
        sed -i '/int32 rawSkillDiff = attackerWeaponSkill - victimMaxSkillValueForLevel;/d' "${UNIT_CPP}"
        sed -i '/int32 cappedSkillDiffMelee/d' "${UNIT_CPP}"
        sed -i 's/int32    skillBonus  = 4 \* cappedSkillDiffMelee;/int32    skillBonus  = 4 * (attackerWeaponSkill - victimMaxSkillValueForLevel);/' "${UNIT_CPP}"
    fi
}
# }}}
