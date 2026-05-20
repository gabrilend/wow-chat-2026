#!/usr/bin/env bash
# B021-playerbots-misc-warnings.sh
#
# Catch-all for the small warning categories that don't share a shape
# with the existing B-patches. One patch per category would multiply
# files needlessly; bundling them keeps the registry lean. Each block
# is independent and idempotent — adding or removing one block doesn't
# affect the others.
#
# Covers:
#   -Wmisleading-indentation     — AuchenaiCrypts x2, TravelMgr x1
#   -Wrange-loop-construct       — CustomStrategy
#   -Wunused-lambda-capture      — RandomPlayerbotMgr
#   -Wint-in-bool-context        — OculusMultipliers (also fixes a real bug)
#   -Wtautological-constant-out-of-range-compare — InventoryAction

# {{{ patch_B021_playerbots_misc_warnings
patch_B021_playerbots_misc_warnings() {
    local PLAYERBOTS_DIR="${AC_CODE_DIR}/modules/mod-playerbots/src"

    [[ -d "${PLAYERBOTS_DIR}" ]] || return 0

    local FILE

    # AuchenaiCryptsMultipliers.cpp:18-19 — both lines are indented as if
    # they're part of the preceding `if (!AI_VALUE2(...)) return 1.0f;`
    # but the if has no braces and only owns its single `return` line.
    # De-indent to function-body level (4 spaces) to match sibling stmts.
    FILE="${PLAYERBOTS_DIR}/Ai/Dungeon/AuchenaiCrypts/Multiplier/AuchenaiCryptsMultipliers.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|^        std::list<Creature\*> creatureList;|    std::list<Creature*> creatureList;|' "${FILE}" 2>/dev/null || true
        sed -i 's|^            bot->GetCreatureListWithEntryInGrid(creatureList, static_cast<uint32>(AuchenaiCryptsIDs::NPC_FOCUS_FIRE)|        bot->GetCreatureListWithEntryInGrid(creatureList, static_cast<uint32>(AuchenaiCryptsIDs::NPC_FOCUS_FIRE)|' "${FILE}" 2>/dev/null || true
    fi

    # AuchenaiCryptsTriggers.cpp:19-20 — same shape as the Multipliers
    # file. Both warned lines sit at 8-space indent under a no-brace
    # `if (!AI_VALUE2(...)) return false;`. Drop to 4-space siblings.
    FILE="${PLAYERBOTS_DIR}/Ai/Dungeon/AuchenaiCrypts/Trigger/AuchenaiCryptsTriggers.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|^        std::list<Creature\*> creatureList;|    std::list<Creature*> creatureList;|' "${FILE}" 2>/dev/null || true
        sed -i 's|^        bot->GetCreatureListWithEntryInGrid(creatureList, static_cast<uint32>(AuchenaiCryptsIDs::NPC_FOCUS_FIRE)|    bot->GetCreatureListWithEntryInGrid(creatureList, static_cast<uint32>(AuchenaiCryptsIDs::NPC_FOCUS_FIRE)|' "${FILE}" 2>/dev/null || true
    fi

    # TravelMgr.cpp:4824 — `locsPerLevelCache[...].push_back(...)` is
    # extra-indented past the preceding `if (l < 1 || l > maxLevel)
    # continue;`, making it look conditional. Pull it back to the for
    # body's indent (16 spaces, matching `if` at the same level).
    FILE="${PLAYERBOTS_DIR}/Mgr/Travel/TravelMgr.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|^                    locsPerLevelCache\[(uint8)l\]\.push_back|                locsPerLevelCache[(uint8)l].push_back|' "${FILE}" 2>/dev/null || true
    fi

    # CustomStrategy.cpp:38 — range-for loop copies each std::string per
    # iteration. Add the `&` so it binds by reference. Pure performance
    # warning; no behavior change.
    FILE="${PLAYERBOTS_DIR}/Bot/Engine/Strategy/CustomStrategy.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|for (const std::string token : tokens)|for (const std::string\& token : tokens)|' "${FILE}" 2>/dev/null || true
    fi

    # RandomPlayerbotMgr.cpp:1621 — the lambda captures `bot` but never
    # uses it inside the body. Drop the capture entirely; the lambda
    # only references parameter `l` and a few globals.
    FILE="${PLAYERBOTS_DIR}/Bot/RandomPlayerbotMgr.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|\[bot\](WorldPosition l)|[](WorldPosition l)|' "${FILE}" 2>/dev/null || true
    fi

    # OculusMultipliers.cpp:96 — the int-in-bool warning is actually the
    # compiler diagnosing a real bug. Upstream wrote:
    #     boss->HasAura(SPELL_PLANAR_SHIFT && dynamic_cast<...>(action))
    # which folds the spell id and the dynamic_cast result into a single
    # bool first, then passes that as the spell id. The intended logic
    # is "boss has the aura AND action is a drake attack action". Move
    # the closing paren so the `&&` connects two boolean expressions.
    FILE="${PLAYERBOTS_DIR}/Ai/Dungeon/Oculus/Multiplier/OculusMultipliers.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|boss->HasAura(SPELL_PLANAR_SHIFT && dynamic_cast<OccDrakeAttackAction\*>(action))|boss->HasAura(SPELL_PLANAR_SHIFT) \&\& dynamic_cast<OccDrakeAttackAction*>(action)|' "${FILE}" 2>/dev/null || true
    fi

    # InventoryAction.cpp:402, 413, 416 — three string position vars are
    # declared as uint32 (or uint8 in one case) then compared to
    # std::string::npos (which is size_t = ~0ULL). On 64-bit Linux the
    # constant truncates to 0xFFFFFFFF (or 0xFF) when compared to the
    # narrower type, and the resulting `always false` comparison kills
    # the check. Widen to size_t so the comparison works as written.
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/InventoryAction.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|uint32 pos = outfit\.find("=");|size_t pos = outfit.find("=");|' "${FILE}" 2>/dev/null || true
        sed -i 's|uint8 pos = text\.find("=") + 1;|size_t pos = text.find("=") + 1;|' "${FILE}" 2>/dev/null || true
        sed -i 's|uint32 endPos = text\.find(|size_t endPos = text.find(|' "${FILE}" 2>/dev/null || true
    fi
}
# }}}

# {{{ unpatch_B021_playerbots_misc_warnings
unpatch_B021_playerbots_misc_warnings() {
    local PLAYERBOTS_DIR="${AC_CODE_DIR}/modules/mod-playerbots/src"

    [[ -d "${PLAYERBOTS_DIR}" ]] || return 0

    local FILE

    # The misleading-indentation reverts intentionally rewrite the
    # whitespace at the start of the line back to the previous (warned)
    # state — necessary to keep this patch reversible even though the
    # original indentation was a bug.
    FILE="${PLAYERBOTS_DIR}/Ai/Dungeon/AuchenaiCrypts/Multiplier/AuchenaiCryptsMultipliers.cpp"
    [[ -f "${FILE}" ]] && sed -i 's|^    std::list<Creature\*> creatureList;|        std::list<Creature*> creatureList;|' "${FILE}" 2>/dev/null || true
    [[ -f "${FILE}" ]] && sed -i 's|^        bot->GetCreatureListWithEntryInGrid(creatureList, static_cast<uint32>(AuchenaiCryptsIDs::NPC_FOCUS_FIRE)|            bot->GetCreatureListWithEntryInGrid(creatureList, static_cast<uint32>(AuchenaiCryptsIDs::NPC_FOCUS_FIRE)|' "${FILE}" 2>/dev/null || true

    FILE="${PLAYERBOTS_DIR}/Ai/Dungeon/AuchenaiCrypts/Trigger/AuchenaiCryptsTriggers.cpp"
    [[ -f "${FILE}" ]] && sed -i 's|^    std::list<Creature\*> creatureList;|        std::list<Creature*> creatureList;|' "${FILE}" 2>/dev/null || true
    [[ -f "${FILE}" ]] && sed -i 's|^    bot->GetCreatureListWithEntryInGrid(creatureList, static_cast<uint32>(AuchenaiCryptsIDs::NPC_FOCUS_FIRE)|        bot->GetCreatureListWithEntryInGrid(creatureList, static_cast<uint32>(AuchenaiCryptsIDs::NPC_FOCUS_FIRE)|' "${FILE}" 2>/dev/null || true

    FILE="${PLAYERBOTS_DIR}/Mgr/Travel/TravelMgr.cpp"
    [[ -f "${FILE}" ]] && sed -i 's|^                locsPerLevelCache\[(uint8)l\]\.push_back|                    locsPerLevelCache[(uint8)l].push_back|' "${FILE}" 2>/dev/null || true

    FILE="${PLAYERBOTS_DIR}/Bot/Engine/Strategy/CustomStrategy.cpp"
    [[ -f "${FILE}" ]] && sed -i 's|for (const std::string\& token : tokens)|for (const std::string token : tokens)|' "${FILE}" 2>/dev/null || true

    FILE="${PLAYERBOTS_DIR}/Bot/RandomPlayerbotMgr.cpp"
    [[ -f "${FILE}" ]] && sed -i 's|\[\](WorldPosition l)|[bot](WorldPosition l)|' "${FILE}" 2>/dev/null || true

    FILE="${PLAYERBOTS_DIR}/Ai/Dungeon/Oculus/Multiplier/OculusMultipliers.cpp"
    [[ -f "${FILE}" ]] && sed -i 's|boss->HasAura(SPELL_PLANAR_SHIFT) && dynamic_cast<OccDrakeAttackAction\*>(action)|boss->HasAura(SPELL_PLANAR_SHIFT \&\& dynamic_cast<OccDrakeAttackAction*>(action))|' "${FILE}" 2>/dev/null || true

    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/InventoryAction.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|size_t pos = outfit\.find("=");|uint32 pos = outfit.find("=");|' "${FILE}" 2>/dev/null || true
        sed -i 's|size_t pos = text\.find("=") + 1;|uint8 pos = text.find("=") + 1;|' "${FILE}" 2>/dev/null || true
        sed -i 's|size_t endPos = text\.find(|uint32 endPos = text.find(|' "${FILE}" 2>/dev/null || true
    fi
}
# }}}
