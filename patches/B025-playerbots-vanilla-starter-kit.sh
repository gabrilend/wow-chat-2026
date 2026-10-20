#!/usr/bin/env bash

patch_B025_playerbots_vanilla_starter_kit() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/Factory/PlayerbotFactory.cpp"
    [[ ! -f "${FILE}" ]] && return 0

    grep -q "B025-vanilla-starter-kit" "${FILE}" && return 0

    echo "  [B025] mod-playerbots: vanilla bots start in the 148h kit"

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

unpatch_B025_playerbots_vanilla_starter_kit() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/Factory/PlayerbotFactory.cpp"
    [[ ! -f "${FILE}" ]] && return 0
    grep -q "B025-vanilla-starter-kit (148s) BEGIN" "${FILE}" || return 0
    sed -i "/>>> B025-vanilla-starter-kit (148s) BEGIN/,/<<< B025-vanilla-starter-kit (148s) END/d" "${FILE}"
}
