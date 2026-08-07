#!/usr/bin/env bash
# B025 - Vanilla playerbots start in the 148h starter kit (issue 148s)
#
# When a random bot is first geared at the vanilla start level (20), equip it
# from the 148h starter kit — the same playercreateinfo_item rows a human
# player receives — instead of the factory's randomized gear. The bot then
# upgrades normally as it levels past 20 (the existing IncrementalGearInit /
# AutoUpgradeEquip path), so the kit is a starting state, not a pin.
#
# Self-scoping: the kit query returns no rows on release/beta (those world
# DBs carry no vanilla-148h data), so on those profiles the injected branch
# is a no-op and gearing falls through to the stock random pass. That makes
# the change safe even though the module binary is shared.
#
# Full spec (context, before/after, rationale): docs/patches/playerbot-vanilla-starter-kit.md
# Parallelizable: Yes (unique file: PlayerbotFactory.cpp)

# {{{ patch_B025_playerbots_vanilla_starter_kit
patch_B025_playerbots_vanilla_starter_kit() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/Factory/PlayerbotFactory.cpp"
    [[ ! -f "${FILE}" ]] && return 0

    # Idempotent: the injected block carries a unique marker.
    grep -q "B025-vanilla-starter-kit" "${FILE}" && return 0

    echo "  [B025] mod-playerbots: vanilla bots start in the 148h kit"

    # The C++ block lives in a quoted heredoc so its single quotes and braces
    # reach a temp file verbatim, then sed reads it in at the top of
    # PlayerbotFactory::InitEquipment, right after the opening brace. Upstream
    # removed the old `incrementalGearInit` guard we used to anchor on (pull
    # ~2026-07), so we anchor on the function signature instead; the block
    # self-guards on `!incremental && level == 20`, so the position is
    # equivalent. Marker comments bracket it so the unpatch deletes a clean range.
    local BLOCK
    BLOCK="$(mktemp)"
    cat > "${BLOCK}" << 'CPP_B025'
    // >>> B025-vanilla-starter-kit (148s) BEGIN
    // A freshly-geared level-20 bot wears the 148h starter kit (the same
    // playercreateinfo_item rows players get) instead of random gear. Self-
    // scoping: on release/beta the query returns no rows and this falls
    // through to the normal gearing below, so it is safe in the shared module
    // binary. Only the initial (non-incremental) level-20 gearing is touched;
    // past level 20 the ordinary upgrade path runs and the bot outgrows it.
    if (!incremental && level == 20)
    {
        if (QueryResult kitResult = WorldDatabase.Query(
                "SELECT itemid, amount FROM playercreateinfo_item "
                "WHERE race = {} AND class = {} AND Note LIKE 'vanilla-148h-%'",
                uint32(bot->getRace()), uint32(bot->getClass())))
        {
            do
            {
                Field* kitFields = kitResult->Fetch();
                uint32 kitItemId = kitFields[0].Get<uint32>();
                uint32 kitAmount = kitFields[1].Get<uint32>();
                if (sObjectMgr->GetItemTemplate(kitItemId))
                    bot->StoreNewItemInBestSlots(kitItemId, kitAmount);
            } while (kitResult->NextRow());
            return;  // kit applied — skip the random-gear pass
        }
    }
    // <<< B025-vanilla-starter-kit (148s) END
CPP_B025

    sed -i "/void PlayerbotFactory::InitEquipment(bool incremental, bool second_chance)/{
n
r ${BLOCK}
}" "${FILE}"

    rm -f "${BLOCK}"
}
# }}}

# {{{ unpatch_B025_playerbots_vanilla_starter_kit
unpatch_B025_playerbots_vanilla_starter_kit() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/Factory/PlayerbotFactory.cpp"
    [[ ! -f "${FILE}" ]] && return 0
    grep -q "B025-vanilla-starter-kit (148s) BEGIN" "${FILE}" || return 0
    # Delete the marker-bracketed block, restoring the pristine factory.
    sed -i "/>>> B025-vanilla-starter-kit (148s) BEGIN/,/<<< B025-vanilla-starter-kit (148s) END/d" "${FILE}"
}
# }}}
