#!/usr/bin/env bash
# B024-symmetric-aggro-radius.sh
# Inverts the "prey on the weak" aggro asymmetry in
# Creature::GetAttackDistance. Vanilla AzerothCore implements the
# original WoW behavior where a creature's aggro radius shrinks for
# higher-level players and grows for lower-level ones — the high-level
# mob notices the low-level character from further away.
#
# The Everland Ghostsong design inverts this: creatures preferentially
# notice players whose level matches their own. A level-60 creature
# notices a level-60 player from 20 yards, a level-50 or level-70
# player less easily, a level-20 or level-100 player barely at all.
# The "seek common foe" semantic.
#
# Curve: 20-yard radius for the ±3 level plateau, then exponential
# decay at 0.9 per level of mismatch beyond that. So |levelDiff|=4 →
# 18 yards, |levelDiff|=5 → 16.2 yards, |levelDiff|=13 → ~7 yards,
# eventually clamped to the vanilla 5-yard minimum further down the
# function.
#
# The 25-level cap from vanilla becomes redundant — the symmetric
# decay naturally drives the radius below the 5-yard floor at large
# mismatches in either direction. Cap is removed.
#
# Affects one function in one file:
#   src/server/game/Entities/Creature/Creature.cpp::GetAttackDistance
#
# Worth submitting upstream behind a config flag (e.g.
# CONFIG_CREATURE_AGGRO_LEVEL_SYMMETRIC) so existing servers aren't
# affected. See docs/patches/contributing-upstream.md for the
# workflow. Locally we don't need the flag — the project has no
# vanilla creatures to preserve compatibility with.

# {{{ patch_B024_symmetric_aggro_radius
patch_B024_symmetric_aggro_radius() {
    local SRC="${AC_CODE_DIR}"
    local FILE="${SRC}/src/server/game/Entities/Creature/Creature.cpp"

    [[ -f "${FILE}" ]] || return 0

    # Single multi-line substitution. The OLD block is the three-section
    # asymmetric formula (cap, base distance, signed subtraction).
    # The NEW block is the symmetric plateau-and-decay formula,
    # marker-wrapped so the unpatch can find it exactly.
    sed -i -z 's|    // "The maximum Aggro Radius has a cap of 25 levels under\. Example: A level 30 char has the same Aggro Radius of a level 5 char on a level 60 mob\."\n    if (levelDiff < -25)\n        levelDiff = -25;\n\n    // "The aggro radius of a mob having the same level as the player is roughly 20 yards"\n    float retDistance = 20\.0f;\n\n    // "Aggro Radius varies with level difference at a rate of roughly 1 yard/level"\n    // radius grow if playlevel < creaturelevel\n    retDistance -= static_cast<float>(levelDiff);|    // {{{ B024-symmetric-aggro\n    static const std::array<float, 100> aggroRadiusByAbsDiff = []() {\n        std::array<float, 100> t{};\n        for (int i = 0; i < 100; ++i)\n        {\n            int decaySteps = (i > 3) ? i - 3 : 0;\n            float r = 20.0f;\n            for (int j = 0; j < decaySteps; ++j)\n                r *= 0.9f;\n            t[i] = r;\n        }\n        return t;\n    }();\n    int32 absDiff = (levelDiff < 0) ? -levelDiff : levelDiff;\n    if (absDiff >= 100) absDiff = 99;\n    float retDistance = aggroRadiusByAbsDiff[absDiff];\n    // }}} B024-symmetric-aggro|' "${FILE}"
}
# }}}

# {{{ unpatch_B024_symmetric_aggro_radius
unpatch_B024_symmetric_aggro_radius() {
    local SRC="${AC_CODE_DIR}"
    local FILE="${SRC}/src/server/game/Entities/Creature/Creature.cpp"

    [[ -f "${FILE}" ]] || return 0

    # Inverse of the apply. The marker `B024-symmetric-aggro` inside
    # the matched text means this can never false-match upstream or
    # any other patch.
    sed -i -z 's|    // {{{ B024-symmetric-aggro\n    static const std::array<float, 100> aggroRadiusByAbsDiff = \[\]() {\n        std::array<float, 100> t{};\n        for (int i = 0; i < 100; ++i)\n        {\n            int decaySteps = (i > 3) ? i - 3 : 0;\n            float r = 20\.0f;\n            for (int j = 0; j < decaySteps; ++j)\n                r \*= 0\.9f;\n            t\[i\] = r;\n        }\n        return t;\n    }();\n    int32 absDiff = (levelDiff < 0) ? -levelDiff : levelDiff;\n    if (absDiff >= 100) absDiff = 99;\n    float retDistance = aggroRadiusByAbsDiff\[absDiff\];\n    // }}} B024-symmetric-aggro|    // "The maximum Aggro Radius has a cap of 25 levels under. Example: A level 30 char has the same Aggro Radius of a level 5 char on a level 60 mob."\n    if (levelDiff < -25)\n        levelDiff = -25;\n\n    // "The aggro radius of a mob having the same level as the player is roughly 20 yards"\n    float retDistance = 20.0f;\n\n    // "Aggro Radius varies with level difference at a rate of roughly 1 yard/level"\n    // radius grow if playlevel < creaturelevel\n    retDistance -= static_cast<float>(levelDiff);|' "${FILE}"
}
# }}}
