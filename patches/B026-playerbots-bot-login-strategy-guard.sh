#!/usr/bin/env bash

patch_B026_playerbots_bot_login_strategy_guard() {
    local ENGINE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/Engine/Engine.cpp"
    local MGR="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/PlayerbotMgr.cpp"

    if [[ -f "${ENGINE}" ]] && ! grep -q "B026 dangling-strategy guard" "${ENGINE}"; then
        echo "  [B026] mod-playerbots: Engine::Init null-strategy guard"
        sed -i '/strategyTypeMask |= strategy->GetType();/i \
        // >>> B026 dangling-strategy guard BEGIN\
        // A strategy in this engine map should never be null (addStrategy only\
        // inserts non-null). If it is, the map was corrupted on the bot-login\
        // path. Skip + name it instead of dereferencing into a segfault, so any\
        // future recurrence is a logged event rather than a crash.\
        if (!strategy)\
        {\
            LOG_ERROR("playerbots", "Engine::Init: null strategy {} in engine map — skipping (bot AI state corrupted)", i->first.c_str());\
            continue;\
        }\
        // <<< B026 dangling-strategy guard END' "${ENGINE}"
    fi

    if [[ -f "${MGR}" ]] && ! grep -q "B026 duplicate-login fix" "${MGR}"; then
        echo "  [B026] mod-playerbots: AddPlayerbotData delete-before-reconstruct"
        sed -i '/_playerbotsAIMap.find(player->GetGUID());/,/_playerbotsAIMap.erase(itr);/{/_playerbotsAIMap.erase(itr);/c\
            // >>> B026 duplicate-login fix BEGIN\
            // Duplicate add for a live GUID (two OnBotLoginOperations resolving to\
            // different holders; the queue has no dedupe). The old AI was orphaned\
            // here (erased, never deleted), leaving Engine::Init to read a strategy\
            // owned by a torn-down context. Delete the stale AI — its dtor\
            // (~PlayerbotAI -> RemovePlayerBotData) self-erases the slot by GUID —\
            // then erase-by-GUID idempotently so the slot is clear before emplace.\
            LOG_WARN("playerbots", "AddPlayerbotData: duplicate PlayerbotAI for GUID {} — reclaiming stale AI (B026)", player->GetGUID().ToString().c_str());\
            PlayerbotAIBase* stale = itr->second;\
            delete stale;\
            _playerbotsAIMap.erase(player->GetGUID());\
            // <<< B026 duplicate-login fix END
}' "${MGR}"
    fi
}

unpatch_B026_playerbots_bot_login_strategy_guard() {
    local ENGINE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/Engine/Engine.cpp"
    local MGR="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/PlayerbotMgr.cpp"
    [[ -f "${ENGINE}" ]] && sed -i '/>>> B026 dangling-strategy guard BEGIN/,/<<< B026 dangling-strategy guard END/d' "${ENGINE}"
    [[ -f "${MGR}" ]] && sed -i '/>>> B026 duplicate-login fix BEGIN/,/<<< B026 duplicate-login fix END/c\
            _playerbotsAIMap.erase(itr);' "${MGR}"
}
