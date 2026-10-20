#!/usr/bin/env bash

patch_B024_symmetric_aggro_radius() {
    local SRC="${AC_CODE_DIR}"
    local FILE="${SRC}/src/server/game/Entities/Creature/Creature.cpp"

    [[ -f "${FILE}" ]] || return 0

    sed -i -z 's|    // "The maximum Aggro Radius has a cap of 25 levels under\. Example: A level 30 char has the same Aggro Radius of a level 5 char on a level 60 mob\."\n    if (levelDiff < -25)\n        levelDiff = -25;\n\n    // "The aggro radius of a mob having the same level as the player is roughly 20 yards"\n    float retDistance = 20\.0f;\n\n    // "Aggro Radius varies with level difference at a rate of roughly 1 yard/level"\n    // radius grow if playlevel < creaturelevel\n    retDistance -= static_cast<float>(levelDiff);|    // {{{ B024-symmetric-aggro\n    static const std::array<float, 100> aggroRadiusByAbsDiff = []() {\n        std::array<float, 100> t{};\n        for (int i = 0; i < 100; ++i)\n        {\n            int decaySteps = (i > 3) ? i - 3 : 0;\n            float r = 20.0f;\n            for (int j = 0; j < decaySteps; ++j)\n                r *= 0.9f;\n            t[i] = r;\n        }\n        return t;\n    }();\n    int32 absDiff = (levelDiff < 0) ? -levelDiff : levelDiff;\n    if (absDiff >= 100) absDiff = 99;\n    float retDistance = aggroRadiusByAbsDiff[absDiff];\n    // }}} B024-symmetric-aggro|' "${FILE}"
}

unpatch_B024_symmetric_aggro_radius() {
    local SRC="${AC_CODE_DIR}"
    local FILE="${SRC}/src/server/game/Entities/Creature/Creature.cpp"

    [[ -f "${FILE}" ]] || return 0

    sed -i -z 's|    // {{{ B024-symmetric-aggro\n    static const std::array<float, 100> aggroRadiusByAbsDiff = \[\]() {\n        std::array<float, 100> t{};\n        for (int i = 0; i < 100; ++i)\n        {\n            int decaySteps = (i > 3) ? i - 3 : 0;\n            float r = 20\.0f;\n            for (int j = 0; j < decaySteps; ++j)\n                r \*= 0\.9f;\n            t\[i\] = r;\n        }\n        return t;\n    }();\n    int32 absDiff = (levelDiff < 0) ? -levelDiff : levelDiff;\n    if (absDiff >= 100) absDiff = 99;\n    float retDistance = aggroRadiusByAbsDiff\[absDiff\];\n    // }}} B024-symmetric-aggro|    // "The maximum Aggro Radius has a cap of 25 levels under. Example: A level 30 char has the same Aggro Radius of a level 5 char on a level 60 mob."\n    if (levelDiff < -25)\n        levelDiff = -25;\n\n    // "The aggro radius of a mob having the same level as the player is roughly 20 yards"\n    float retDistance = 20.0f;\n\n    // "Aggro Radius varies with level difference at a rate of roughly 1 yard/level"\n    // radius grow if playlevel < creaturelevel\n    retDistance -= static_cast<float>(levelDiff);|' "${FILE}"
}
