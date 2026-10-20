#!/usr/bin/env bash

patch_B027_playerbots_engine_init_facade_guard() {
    local AWARE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/Engine/PlayerbotAIAware.h"
    local ENGINE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/Engine/Engine.cpp"

    if [[ -f "${AWARE}" ]] && ! grep -q "B027 facade accessor" "${AWARE}"; then
        echo "  [B027] mod-playerbots: PlayerbotAIAware facade accessor"
        sed -i '/: botAI(botAI) {}/a \
    // >>> B027 facade accessor BEGIN\
    // Public read access to the stored PlayerbotAI facade so sibling\
    // PlayerbotAIAware subclasses (Engine vs Strategy) can compare facades\
    // without friendship. Used by Engine::Init to detect a strategy built\
    // against a corrupt facade before dereferencing it (issue 308).\
    PlayerbotAI* GetAI() const { return botAI; }\
    // SetAI exists solely for the Engine::Init facade repair (issue 308):\
    // upstream sometimes constructs strategies with a corrupt facade\
    // argument; the engine rewrites it with the known-correct owner before\
    // first use. Do not use it anywhere else.\
    void SetAI(PlayerbotAI* ai) { botAI = ai; }\
    // <<< B027 facade accessor END' "${AWARE}"
    fi

    if [[ -f "${ENGINE}" ]] && ! grep -q "B027 stale-facade guard" "${ENGINE}"; then
        echo "  [B027] mod-playerbots: Engine::Init stale-facade guard"
        sed -i '/strategy->InitMultipliers(multipliers);/i \
        // >>> B027 stale-facade guard BEGIN\
        // This engine is built for ONE bot: its live facade is this->GetAI(),\
        // the PlayerbotAI under construction right now (provably valid, since\
        // engines are only built inside that ctor). Every strategy here must\
        // carry that same facade. Upstream sometimes constructs a strategy\
        // with a corrupt facade argument (issue 308: garbage at birth, always\
        // the same registration positions; a hardware watchpoint proved the\
        // field is never written after construction). Dereferencing it\
        // (RacialsStrategy does botAI->GetBot()) SIGSEGVs the world thread.\
        // The object itself is real and correctly typed -- only the facade\
        // is wrong, and the correct value is deterministically the engine\
        // facade. So REPAIR it and initialize normally, keeping the bot\
        // fully functional. B026 guards the null case; keep a skip for that.\
        if (!strategy)\
        {\
            LOG_ERROR("playerbots", "Engine::Init: null strategy {} in engine map, skipping (B027, issue 308)", i->first.c_str());\
            continue;\
        }\
        if (strategy->GetAI() != this->GetAI())\
        {\
            LOG_WARN("playerbots",\
                "Engine::Init: strategy {} was constructed with a corrupt bot facade, "\
                "repairing it with the engine facade (B027, issue 308)",\
                i->first.c_str());\
            strategy->SetAI(this->GetAI());\
        }\
        // <<< B027 stale-facade guard END' "${ENGINE}"
    fi
}

unpatch_B027_playerbots_engine_init_facade_guard() {
    local AWARE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/Engine/PlayerbotAIAware.h"
    local ENGINE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/Engine/Engine.cpp"

    [[ -f "${AWARE}" ]] && sed -i '/>>> B027 facade accessor BEGIN/,/<<< B027 facade accessor END/d' "${AWARE}"
    [[ -f "${ENGINE}" ]] && sed -i '/>>> B027 stale-facade guard BEGIN/,/<<< B027 stale-facade guard END/d' "${ENGINE}"
}
