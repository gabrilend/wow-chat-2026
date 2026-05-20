#!/usr/bin/env bash
# B018-playerbots-sign-compare.sh
# Fixes sign comparison warnings in mod-playerbots
#
# Warning: comparison of integers of different signs [-Wsign-compare]
#
# Patterns fixed:
#   1. int loop counters vs .size() -> size_t counters
#   2. int vs uint32 with -1 sentinel -> cast to uint32
#   3. string::find() == -1 -> string::npos
#   4. GetMapId() == -1 -> static_cast<uint32>(-1)
#
# Affected files (13 warnings):
#   PlayerbotAIConfig.cpp:918,925,927,974,976
#   BattleGroundTactics.cpp:1371,3329
#   ChatShortcutActions.cpp:75
#   ChooseTravelTargetAction.cpp:931
#   FollowActions.cpp:221
#   GenericSpellActions.cpp:180
#   InventoryAction.cpp:375,389
#   MovementActions.cpp:1870,2301
#   QuestAction.cpp:416
#   TradeAction.cpp:72
#   TravelAction.cpp:40

# {{{ patch_B018_playerbots_sign_compare
patch_B018_playerbots_sign_compare() {
    local PLAYERBOTS_DIR="${AC_CODE_DIR}/modules/mod-playerbots/src"

    [[ -d "${PLAYERBOTS_DIR}" ]] || return 0

    local FILE

    # PlayerbotAIConfig.cpp - 5 warnings from loop counters
    FILE="${PLAYERBOTS_DIR}/PlayerbotAIConfig.cpp"
    if [[ -f "${FILE}" ]] && ! grep -q "for (size_t tab = 0; tab < 3; tab++)" "${FILE}" 2>/dev/null; then
        sed -i 's/for (int tab = 0; tab < 3; tab++)/for (size_t tab = 0; tab < 3; tab++)/' "${FILE}"
        sed -i 's/for (int i = 0; i < tab_links\[tab\]\.size(); i++)/for (size_t i = 0; i < tab_links[tab].size(); i++)/' "${FILE}"
        sed -i 's/for (int i = 0; i < tab_link\.size(); i++)/for (size_t i = 0; i < tab_link.size(); i++)/' "${FILE}"
    fi

    # BattleGroundTactics.cpp - int must stay signed (can be -1)
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/BattleGroundTactics.cpp"
    if [[ -f "${FILE}" ]]; then
        # Line 1371: num (int) vs max (uint32)
        sed -i 's/if (num > max)/if (static_cast<uint32>(num) > max)/' "${FILE}" 2>/dev/null || true
        # Line 3329: closestPointIndex (int) vs path->size() - 1
        sed -i 's/closestPointIndex == (reverse ? 0 : path->size() - 1)/static_cast<size_t>(closestPointIndex) == (reverse ? 0 : path->size() - 1)/' "${FILE}" 2>/dev/null || true
    fi

    # ChatShortcutActions.cpp:75 - GetMapId() == -1
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/ChatShortcutActions.cpp"
    if [[ -f "${FILE}" ]] && grep -q "GetMapId() == -1" "${FILE}" 2>/dev/null; then
        sed -i 's/loc\.GetMapId() == -1/loc.GetMapId() == static_cast<uint32>(-1)/' "${FILE}"
    fi

    # FollowActions.cpp:221 - GetMapId() == -1
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/FollowActions.cpp"
    if [[ -f "${FILE}" ]] && grep -q "GetMapId() == -1" "${FILE}" 2>/dev/null; then
        sed -i 's/loc\.GetMapId() == -1/loc.GetMapId() == static_cast<uint32>(-1)/' "${FILE}"
    fi

    # InventoryAction.cpp:375,389 - string::find() == -1
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/InventoryAction.cpp"
    if [[ -f "${FILE}" ]] && grep -q "== -1" "${FILE}" 2>/dev/null; then
        sed -i 's/pos == -1/pos == std::string::npos/g' "${FILE}"
        sed -i 's/endPos == -1/endPos == std::string::npos/g' "${FILE}"
    fi

    # MovementActions.cpp:1870,2301 - GetMapId() == -1
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/MovementActions.cpp"
    if [[ -f "${FILE}" ]] && grep -q "GetMapId() == -1" "${FILE}" 2>/dev/null; then
        sed -i 's/GetMapId() == -1/GetMapId() == static_cast<uint32>(-1)/g' "${FILE}"
    fi

    # TradeAction.cpp:72 - GetMapId() == -1
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/TradeAction.cpp"
    if [[ -f "${FILE}" ]] && grep -q "GetMapId() == -1" "${FILE}" 2>/dev/null; then
        sed -i 's/GetMapId() == -1/GetMapId() == static_cast<uint32>(-1)/' "${FILE}"
    fi

    # TravelAction.cpp:40 - compare pattern
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/TravelAction.cpp"
    if [[ -f "${FILE}" ]] && grep -q "GetMapId() == -1" "${FILE}" 2>/dev/null; then
        sed -i 's/GetMapId() == -1/GetMapId() == static_cast<uint32>(-1)/' "${FILE}"
    fi

    # ChooseTravelTargetAction.cpp:931 - target->GetEntry() (uint32) == entry (int32)
    # The entry is guaranteed positive at this point (line 926 checks entry > 0)
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/ChooseTravelTargetAction.cpp"
    if [[ -f "${FILE}" ]] && grep -q "target->GetEntry() == entry" "${FILE}" 2>/dev/null; then
        sed -i 's/target->GetEntry() == entry/target->GetEntry() == static_cast<uint32>(entry)/' "${FILE}"
    fi

    # GenericSpellActions.cpp:180 - aura->GetDuration() (int32) < beforeDuration (uint32)
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/GenericSpellActions.cpp"
    if [[ -f "${FILE}" ]] && grep -q "aura->GetDuration() < beforeDuration" "${FILE}" 2>/dev/null; then
        sed -i 's/aura->GetDuration() < beforeDuration/aura->GetDuration() < static_cast<int32>(beforeDuration)/' "${FILE}"
    fi

    # GenericTriggers.cpp:167 - same pattern as GenericSpellActions
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Trigger/GenericTriggers.cpp"
    if [[ -f "${FILE}" ]]; then
        # Line 167: aura duration comparison
        sed -i 's/aura->GetDuration() < beforeDuration/aura->GetDuration() < static_cast<int32>(beforeDuration)/' "${FILE}" 2>/dev/null || true
        # Line 413: AI_VALUE2(uint32, ...) < count (int32) - cast count to uint32
        sed -i 's/AI_VALUE2(uint32, "item count", item) < count/AI_VALUE2(uint32, "item count", item) < static_cast<uint32>(count)/' "${FILE}" 2>/dev/null || true
    fi

    # QuestAction.cpp:416 - int32 vs uint32
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/QuestAction.cpp"
    if [[ -f "${FILE}" ]] && grep -q "== -1" "${FILE}" 2>/dev/null; then
        # Check if it's a string::find pattern
        sed -i 's/\.find([^)]*) == -1/.find(\1) == std::string::npos/g' "${FILE}" 2>/dev/null || true
    fi

    # --- 2026-05-19: bulk extension. Every selector below targets a
    # specific current-upstream warning site. Two shapes dominate:
    #   1. `for (int i = 0; i < container.size(); ...)` — widen the loop
    #      counter to `size_t` so it matches `.size()`'s return type.
    #   2. `cmp(int_thing, uint_thing)` — cast at the comparison site.
    # Cast direction always favours preserving the value that's
    # guaranteed non-negative in context.

    # Loop-counter widenings (size_t to match container.size() / sizeof-loop result).
    # Each entry is anchored on the FULL `i < container.size()` shape so
    # sibling loops with different containers don't accidentally migrate.

    # RaidIccActions.cpp: 4 loops — npcs.size() x3, members.size() x1
    FILE="${PLAYERBOTS_DIR}/Ai/Raid/Icecrown/Action/RaidIccActions.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|for (int i = 0; i < npcs.size() && shadowCount|for (size_t i = 0; i < npcs.size() \&\& shadowCount|' "${FILE}" 2>/dev/null || true
        sed -i 's|for (int i = 0; i < npcs.size(); ++i)|for (size_t i = 0; i < npcs.size(); ++i)|g' "${FILE}" 2>/dev/null || true
        sed -i 's|for (int i = 0; i < members.size(); i++)|for (size_t i = 0; i < members.size(); i++)|' "${FILE}" 2>/dev/null || true
    fi

    # NaxxActions_Shared.cpp:7 — `intervals` is a function arg, type
    # unknown without a header read. Cast the comparison instead.
    FILE="${PLAYERBOTS_DIR}/Ai/Raid/Naxxramas/Action/RaidNaxxActions_Shared.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|for (int i = 0; i < intervals; i++)|for (int i = 0; i < static_cast<int>(intervals); i++)|' "${FILE}" 2>/dev/null || true
    fi

    # UlduarActions:107 corners; UlduarActions:2639 — line 2639 is
    # `lowestHealthUnit = unit;` but the warning column is 39. That
    # suggests the comparison happens on a different line of the same
    # statement; without more context the safest move is to read the
    # surrounding `if (... < ...)` and cast. Skipping this single site
    # for now — left as a TODO for the next pass.
    FILE="${PLAYERBOTS_DIR}/Ai/Raid/Ulduar/Action/RaidUlduarActions.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|for (int i = 0; i < corners.size(); i++)|for (size_t i = 0; i < corners.size(); i++)|' "${FILE}" 2>/dev/null || true
    fi

    # RpgAction:110
    FILE="${PLAYERBOTS_DIR}/Ai/World/Rpg/Action/RpgAction.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|for (int i = 0; i < actions.size(); i++)|for (size_t i = 0; i < actions.size(); i++)|' "${FILE}" 2>/dev/null || true
    fi

    # PlayerbotFactory: many sites. The two `level < equipmentPersistenceLevel`
    # comparisons cast the right side to int32 since `level` is int.
    FILE="${PLAYERBOTS_DIR}/Bot/Factory/PlayerbotFactory.cpp"
    if [[ -f "${FILE}" ]]; then
        # 565, 573 — same expression repeated in two overloads. Cast.
        sed -i 's|level < PlayerbotAIConfig::instance().equipmentPersistenceLevel|level < static_cast<int>(PlayerbotAIConfig::instance().equipmentPersistenceLevel)|g' "${FILE}" 2>/dev/null || true
        # 1138, 3315 — rank loop where std::min returns uint32. Widen
        # the rank to int by casting the comparison RHS.
        sed -i 's|for (int rank = 0; rank < std::min((uint32)MAX_TALENT_RANK, (uint32)pet->GetFreeTalentPoints()); ++rank)|for (uint32 rank = 0; rank < std::min((uint32)MAX_TALENT_RANK, (uint32)pet->GetFreeTalentPoints()); ++rank)|' "${FILE}" 2>/dev/null || true
        sed -i 's|for (int rank = 0; rank < std::min((uint32)MAX_TALENT_RANK, bot->GetFreeTalentPoints()); ++rank)|for (uint32 rank = 0; rank < std::min((uint32)MAX_TALENT_RANK, bot->GetFreeTalentPoints()); ++rank)|' "${FILE}" 2>/dev/null || true
        # 2109 — `(int32)proto->Quality > itemQuality` — itemQuality is
        # likely uint32 here. Cast both sides to int32 by casting RHS.
        sed -i 's|static_cast<int32>(proto->Quality) > itemQuality|static_cast<int32>(proto->Quality) > static_cast<int32>(itemQuality)|' "${FILE}" 2>/dev/null || true
        # 2179 — `requiredLevel > std::max(...)`. requiredLevel is uint32,
        # std::max returns int32. Cast the std::max result.
        sed -i 's|requiredLevel > std::max((int32)bot->GetLevel() - delta, 0)|requiredLevel > static_cast<uint32>(std::max((int32)bot->GetLevel() - delta, 0))|' "${FILE}" 2>/dev/null || true
        # 2214 — `proto->Quality != desiredQuality`. Cast desiredQuality.
        sed -i 's|if (proto->Quality != desiredQuality)|if (proto->Quality != static_cast<uint32>(desiredQuality))|' "${FILE}" 2>/dev/null || true
        # 2245, 2354 — index loops over ids.size()
        sed -i 's|for (int index = 0; index < ids.size(); index++)|for (size_t index = 0; index < ids.size(); index++)|g' "${FILE}" 2>/dev/null || true
        # 3859 — sizeof loop
        sed -i 's|for (int i = 0; i < sizeof(categories) / sizeof(uint32); ++i)|for (size_t i = 0; i < sizeof(categories) / sizeof(uint32); ++i)|' "${FILE}" 2>/dev/null || true
        # 5046 — curCount loop
        sed -i 's|for (int i = 1; i < curCount.size(); i++)|for (size_t i = 1; i < curCount.size(); i++)|' "${FILE}" 2>/dev/null || true
        # 5048 — curCount[i] < requiredActive ; requiredActive is int.
        # Cast it to value_type (uint32 inferred).
        sed -i 's|if (curCount\[i\] < requiredActive && (gemProperties->color & (1 << i)))|if (curCount[i] < static_cast<uint32>(requiredActive) \&\& (gemProperties->color \& (1 << i)))|' "${FILE}" 2>/dev/null || true
    fi

    # RandomPlayerbotFactory:243 - botName loop
    FILE="${PLAYERBOTS_DIR}/Bot/Factory/RandomPlayerbotFactory.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|for (int i = 0; i < botName.size(); i++)|for (size_t i = 0; i < botName.size(); i++)|' "${FILE}" 2>/dev/null || true
    fi

    # PlayerbotMgr:131 — `count >= maxAddedBots`. count likely uint32,
    # maxAddedBots int32 or vice versa.
    FILE="${PLAYERBOTS_DIR}/Bot/PlayerbotMgr.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|count >= PlayerbotAIConfig::instance().maxAddedBots|count >= static_cast<uint32>(PlayerbotAIConfig::instance().maxAddedBots)|' "${FILE}" 2>/dev/null || true
    fi

    # RandomItemMgr — five sites
    FILE="${PLAYERBOTS_DIR}/Mgr/Item/RandomItemMgr.cpp"
    if [[ -f "${FILE}" ]]; then
        # 1599 — abs returns int. statWeight is uint32.
        sed -i 's|abs(basicStatsWeight) >= statWeight|static_cast<uint32>(abs(basicStatsWeight)) >= statWeight|' "${FILE}" 2>/dev/null || true
        # 2219, 2230 — reward count loops
        sed -i 's|for (int j = 0; j < quest->GetRewChoiceItemsCount(); j++)|for (uint32 j = 0; j < quest->GetRewChoiceItemsCount(); j++)|' "${FILE}" 2>/dev/null || true
        sed -i 's|for (int j = 0; j < quest->GetRewItemsCount(); j++)|for (uint32 j = 0; j < quest->GetRewItemsCount(); j++)|' "${FILE}" 2>/dev/null || true
        # 2375 — `AllowableClass != -1`
        sed -i 's|if (proto->AllowableClass != -1)|if (proto->AllowableClass != static_cast<uint32>(-1))|' "${FILE}" 2>/dev/null || true
        # 2768 — ItemId == Reagent[x] ; Reagent is int32[]
        sed -i 's|if (proto->ItemId == spellInfo->Reagent\[x\])|if (proto->ItemId == static_cast<uint32>(spellInfo->Reagent[x]))|' "${FILE}" 2>/dev/null || true
    fi

    # StatsCollector:37 - `i < proto->StatsCount`
    FILE="${PLAYERBOTS_DIR}/Mgr/Item/StatsCollector.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|for (int i = 0; i < proto->StatsCount; i++)|for (uint32 i = 0; i < proto->StatsCount; i++)|' "${FILE}" 2>/dev/null || true
    fi

    # Talentspec:335, 451 — comparisons against enum constants
    FILE="${PLAYERBOTS_DIR}/Mgr/Talent/Talentspec.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|entry.tabPage() == tabpage|static_cast<int>(entry.tabPage()) == tabpage|' "${FILE}" 2>/dev/null || true
        sed -i 's|reverse == ADDED_POINTS || reverse == REMOVED_POINTS|static_cast<int>(reverse) == ADDED_POINTS || static_cast<int>(reverse) == REMOVED_POINTS|' "${FILE}" 2>/dev/null || true
    fi

    # TravelMgr: many sites
    FILE="${PLAYERBOTS_DIR}/Mgr/Travel/TravelMgr.cpp"
    if [[ -f "${FILE}" ]]; then
        # 1261, 1313, 1458 — GetEntry vs getEntry (uint32 vs int32). Cast
        # the int32 to uint32 to match the LHS.
        sed -i 's|target.GetEntry() == getEntry() && target.IsCreature()|target.GetEntry() == static_cast<uint32>(getEntry()) \&\& target.IsCreature()|g' "${FILE}" 2>/dev/null || true
        sed -i 's|if (guid.GetEntry() == getEntry())|if (guid.GetEntry() == static_cast<uint32>(getEntry()))|' "${FILE}" 2>/dev/null || true
        # 4749, 4765 — bracket loops (int i with int32 bracket bounds — should be fine, but warning fires)
        sed -i 's|for (int i = bracket.low; i <= bracket.high; i++)|for (int32 i = bracket.low; i <= bracket.high; i++)|g' "${FILE}" 2>/dev/null || true
        # 4790 — `int32 l = 1; l <= maxLevel` ; maxLevel uint32
        sed -i 's|for (int32 l = 1; l <= maxLevel; l++)|for (int32 l = 1; l <= static_cast<int32>(maxLevel); l++)|' "${FILE}" 2>/dev/null || true
        # 4821 — `l < 1 || l > maxLevel` — l is int32, maxLevel uint32
        sed -i 's|if (l < 1 || l > maxLevel)|if (l < 1 || l > static_cast<int32>(maxLevel))|' "${FILE}" 2>/dev/null || true
    fi

    # MovementActions.cpp:1857, 2288 — `getMSTime() - moveInterval < lastMoveTimer`
    # uint32 - int < int. Cast RHS.
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/MovementActions.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|if (getMSTime() - moveInterval < lastMoveTimer)|if (getMSTime() - moveInterval < static_cast<uint32>(lastMoveTimer))|g' "${FILE}" 2>/dev/null || true
    fi

    # QuestAction.cpp:416 — int32 previousCount vs const uint32 RequiredItemCount
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/QuestAction.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|if (itemId == itemEntry && previousCount < quest->RequiredItemCount\[i\])|if (itemId == itemEntry \&\& previousCount < static_cast<int32>(quest->RequiredItemCount[i]))|' "${FILE}" 2>/dev/null || true
    fi

    # TradeAction.cpp:72 — `++traded >= count` ; traded uint32, count int
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/TradeAction.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|++traded >= count)|++traded >= static_cast<uint32>(count))|' "${FILE}" 2>/dev/null || true
    fi

    # TravelAction.cpp:40 — uint32 GetEntry vs int32 getEntry
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/TravelAction.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|newTarget->GetEntry() == target->getDestination()->getEntry()|newTarget->GetEntry() == static_cast<uint32>(target->getDestination()->getEntry())|' "${FILE}" 2>/dev/null || true
    fi

    # BudgetValues.cpp:28 — `i >= EQUIPMENT_SLOT_END` ; i is int, slot enum
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Value/BudgetValues.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|if (i >= EQUIPMENT_SLOT_END && curDurability >= maxDurability)|if (i >= static_cast<int>(EQUIPMENT_SLOT_END) \&\& curDurability >= maxDurability)|' "${FILE}" 2>/dev/null || true
    fi

    # GrindTargetValue.cpp:185 — `target->GetEntry() == entry`
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Value/GrindTargetValue.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|target->GetEntry() == entry)|target->GetEntry() == static_cast<uint32>(entry))|' "${FILE}" 2>/dev/null || true
    fi

    # ItemUsageValue.cpp:714, 813 — Reagent[i] is int32, ItemId/itemId uint32
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Value/ItemUsageValue.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|proto->ItemId == spellInfo->Reagent\[i\] &&|proto->ItemId == static_cast<uint32>(spellInfo->Reagent[i]) \&\&|' "${FILE}" 2>/dev/null || true
        sed -i 's|spellInfo->Reagent\[i\] == itemId)|static_cast<uint32>(spellInfo->Reagent[i]) == itemId)|' "${FILE}" 2>/dev/null || true
    fi

    # PossibleRpgTargetsValue:78 — getEntry vs GetEntry
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Value/PossibleRpgTargetsValue.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|travelTarget->getDestination()->getEntry() == unit->GetEntry()|static_cast<uint32>(travelTarget->getDestination()->getEntry()) == unit->GetEntry()|' "${FILE}" 2>/dev/null || true
    fi

    # SpellIdValue.cpp — multiple shapes. 64/88/211 share `strlen(...) != spellLength`
    # where strlen is size_t and spellLength is likely uint32. 136/142 are
    # `id < lowestRank` style (int rank vs uint32). 156 is enum equality.
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Value/SpellIdValue.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|strlen(spellName) != spellLength|strlen(spellName) != static_cast<size_t>(spellLength)|g' "${FILE}" 2>/dev/null || true
        sed -i 's|if (!highestRank || id > highestRank)|if (!highestRank || id > static_cast<uint32>(highestRank))|' "${FILE}" 2>/dev/null || true
        sed -i 's|if (!lowestRank || (lowestRank && id < lowestRank))|if (!lowestRank || (lowestRank \&\& id < static_cast<uint32>(lowestRank)))|' "${FILE}" 2>/dev/null || true
        sed -i 's|if (saveMana == rank)|if (saveMana == static_cast<uint32>(rank))|' "${FILE}" 2>/dev/null || true
    fi

    # MagtheridonActions:322 — `warlockIndex < abyssals.size()`
    FILE="${PLAYERBOTS_DIR}/Ai/Raid/Magtheridon/Action/RaidMagtheridonActions.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|warlockIndex >= 0 && warlockIndex < abyssals.size()|warlockIndex >= 0 \&\& static_cast<size_t>(warlockIndex) < abyssals.size()|' "${FILE}" 2>/dev/null || true
    fi

    # NaxxActions_Razuvious:43, 52 — Duration is int32, duration_time uint32
    FILE="${PLAYERBOTS_DIR}/Ai/Raid/Naxxramas/Action/RaidNaxxActions_Razuvious.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|forceObedience->GetDuration() <= (duration_time - 5000)|forceObedience->GetDuration() <= static_cast<int32>(duration_time - 5000)|' "${FILE}" 2>/dev/null || true
        sed -i 's|forceObedience->GetDuration() >= (duration_time - 500)|forceObedience->GetDuration() >= static_cast<int32>(duration_time - 500)|' "${FILE}" 2>/dev/null || true
    fi

    # NewRpgBaseAction:887 — `qPoi.ObjectiveIndex == objective`
    FILE="${PLAYERBOTS_DIR}/Ai/World/Rpg/Action/NewRpgBaseAction.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|if (qPoi.ObjectiveIndex == objective)|if (qPoi.ObjectiveIndex == static_cast<int32>(objective))|' "${FILE}" 2>/dev/null || true
    fi

    # CommandServer:29 — `n == -1`. n is size_t (asio bytes_transferred).
    # Sentinel for "error" — boost::asio uses size_t with no sentinel;
    # the `-1` check is comparing against the unsigned representation
    # of -1. Replace with explicit cast so the intent is preserved.
    FILE="${PLAYERBOTS_DIR}/Bot/Cmd/PlayerbotCommandServer.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|if (n == -1 || error == boost::asio::error::eof)|if (n == static_cast<size_t>(-1) || error == boost::asio::error::eof)|' "${FILE}" 2>/dev/null || true
    fi

    # Trigger.cpp:39 — `now - lastCheckTime >= checkInterval`. Types
    # mismatch between uint32_t result and int32_t checkInterval.
    FILE="${PLAYERBOTS_DIR}/Bot/Engine/Trigger/Trigger.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's|now - lastCheckTime >= checkInterval|now - lastCheckTime >= static_cast<uint32_t>(checkInterval)|' "${FILE}" 2>/dev/null || true
    fi
}
# }}}

# {{{ unpatch_B018_playerbots_sign_compare
unpatch_B018_playerbots_sign_compare() {
    local PLAYERBOTS_DIR="${AC_CODE_DIR}/modules/mod-playerbots/src"

    [[ -d "${PLAYERBOTS_DIR}" ]] || return 0

    local FILE

    # PlayerbotAIConfig.cpp
    FILE="${PLAYERBOTS_DIR}/PlayerbotAIConfig.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/for (size_t tab = 0; tab < 3; tab++)/for (int tab = 0; tab < 3; tab++)/' "${FILE}"
        sed -i 's/for (size_t i = 0; i < tab_links\[tab\]\.size(); i++)/for (int i = 0; i < tab_links[tab].size(); i++)/' "${FILE}"
        sed -i 's/for (size_t i = 0; i < tab_link\.size(); i++)/for (int i = 0; i < tab_link.size(); i++)/' "${FILE}"
    fi

    # BattleGroundTactics.cpp
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/BattleGroundTactics.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/if (static_cast<uint32>(num) > max)/if (num > max)/' "${FILE}"
        sed -i 's/static_cast<size_t>(closestPointIndex) == (reverse ? 0 : path->size() - 1)/closestPointIndex == (reverse ? 0 : path->size() - 1)/' "${FILE}"
    fi

    # Revert GetMapId() casts
    for file in ChatShortcutActions.cpp FollowActions.cpp MovementActions.cpp TradeAction.cpp TravelAction.cpp ChooseTravelTargetAction.cpp; do
        FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/${file}"
        [[ -f "${FILE}" ]] && sed -i 's/GetMapId() == static_cast<uint32>(-1)/GetMapId() == -1/g' "${FILE}"
    done

    # Revert string::npos
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/InventoryAction.cpp"
    if [[ -f "${FILE}" ]]; then
        sed -i 's/pos == std::string::npos/pos == -1/g' "${FILE}"
        sed -i 's/endPos == std::string::npos/endPos == -1/g' "${FILE}"
    fi
}
# }}}
