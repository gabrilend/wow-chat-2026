#!/usr/bin/env bash
# B026 - Fix the bot-login Engine::Init crash (dangling strategy on duplicate add)
#
# Symptom: worldserver segfaults shortly after startup on the queued bot-login
# path (main world thread): OnBotLoginOperation::Execute -> AddPlayerbotData ->
# new PlayerbotAI -> AiFactory::createCombatEngine -> Engine::Init, faulting
# while iterating the engine's `strategies` map (the -O2 build mislabels the PC
# as PlayerbotAI::GetBot()).
#
# Root cause (confirmed by ownership analysis): PlayerbotsMgr::AddPlayerbotData
# erased a pre-existing PlayerbotAI map entry WITHOUT deleting it, then built a
# SECOND PlayerbotAI on the same live Player. The world-thread login queue has
# no GUID dedupe, and the per-holder `playerBots` guard doesn't cover the global
# `_playerbotsAIMap`, so two OnBotLoginOperations resolving to different holders
# both reach AddPlayerbotData for one GUID. The orphaned old AI's AiObjectContext
# gets torn down, leaving the fresh engine's `strategies` pointing at a strategy
# owned by a dead context — a dangling read in Engine::Init.
#
# Why delete-before-reconstruct is safe: `_playerbotsAIMap` (on the singleton
# PlayerbotsMgr) is the SOLE owner of every PlayerbotAI*. The Player holds no
# back-pointer; every accessor (GET_PLAYERBOT_AI) re-looks-up by GUID. Every
# deletion path (OnDestructPlayer via ~Player, DisablePlayerBot) fetches the
# pointer FROM the map, so once the entry is gone nothing can re-delete it.
# `~PlayerbotAI` self-unregisters via RemovePlayerBotData(GUID), so we delete
# the stale AI (its dtor erases the slot) then erase-by-GUID as an idempotent
# guarantee before the emplace ASSERT. No double-free is reachable.
#
# The fix reclaims the stale context so Engine::Init never reads a dead strategy.
# A defensive null-guard in Engine::Init is added too, so any *future* corruption
# on this path becomes a named log line instead of a segfault.
#
# Full write-up + confirming datum: docs/patches/playerbot-bot-login-strategy-guard.md
# Parallelizable: Yes (unique files: Engine.cpp, PlayerbotMgr.cpp)

# {{{ patch_B026_playerbots_bot_login_strategy_guard
patch_B026_playerbots_bot_login_strategy_guard() {
    local ENGINE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/Engine/Engine.cpp"
    local MGR="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/PlayerbotMgr.cpp"

    # --- 1. Engine::Init null-strategy guard (defense-in-depth) ----------------
    # Insert BEFORE the (unique) `strategyTypeMask |= strategy->GetType();` line,
    # i.e. right after `Strategy* strategy = i->second;` in the Init loop only.
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

    # --- 2. AddPlayerbotData: delete-before-reconstruct (the actual fix) --------
    # Scope to the AddPlayerbotData branch (opened by the unique
    # `find(player->GetGUID())`) so the identical erase in the GUID-removal path
    # is untouched, and REPLACE the leaking `erase(itr)` with delete + idempotent
    # erase-by-GUID. `delete` runs ~PlayerbotAI which self-erases the slot; the
    # explicit erase-by-GUID then guarantees the slot is clear before emplace.
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
# }}}

# {{{ unpatch_B026_playerbots_bot_login_strategy_guard
unpatch_B026_playerbots_bot_login_strategy_guard() {
    local ENGINE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/Engine/Engine.cpp"
    local MGR="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/PlayerbotMgr.cpp"
    # Engine guard: delete the marker range.
    [[ -f "${ENGINE}" ]] && sed -i '/>>> B026 dangling-strategy guard BEGIN/,/<<< B026 dangling-strategy guard END/d' "${ENGINE}"
    # Mgr fix: replace the marker block back with the original leaking erase, so
    # the tree round-trips exactly to upstream HEAD.
    [[ -f "${MGR}" ]] && sed -i '/>>> B026 duplicate-login fix BEGIN/,/<<< B026 duplicate-login fix END/c\
            _playerbotsAIMap.erase(itr);' "${MGR}"
}
# }}}
