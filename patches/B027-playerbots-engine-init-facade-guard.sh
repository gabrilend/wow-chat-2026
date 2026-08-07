#!/usr/bin/env bash
# B027 - Guard Engine::Init against a strategy with a stale/foreign bot facade
# Issue 308: worldserver segfaults during the first random-bot login burst.
#
# Symptom: SIGSEGV on the main world thread shortly after "ready...", on the
# queued bot-login path: PlayerbotWorldThreadProcessor::ProcessBatch ->
# OnBotLoginOperation::Execute -> PlayerbotHolder::OnBotLogin ->
# PlayerbotsMgr::AddPlayerbotData -> PlayerbotAI ctor ->
# AiFactory::createCombatEngine -> Engine::Init -> RacialsStrategy::InitTriggers,
# faulting on `botAI->GetBot()`. Zero bots finish logging in.
#
# Root cause: Engine and Strategy both derive from PlayerbotAIAware, which holds
# a PlayerbotAI* back-pointer (the "facade"). The engine is built for one bot
# with the live, under-construction facade (provably valid). Every strategy in
# the engine map should carry that same facade. Here one carries a different or
# torn-down PlayerbotAI, and Engine::Init dereferences it -> use-after-free. This
# is the same crash site as B026 but a different trigger (a first login, not the
# duplicate-login race B026 dedups; the dangling pointer is non-null, so the B026
# null guard passes and the fault is one dereference deeper).
#
# Fix (revised 2026-07-22 after live-debugger diagnosis, issue 308): the corrupt
# facade is present AT CONSTRUCTION (verified with a breakpoint on the strategy
# ctor: garbage value at birth with a valid this) and a hardware watchpoint on
# the field proved NOTHING writes it afterward. The affected strategies are real,
# correctly-typed objects built by their real constructors -- only the facade
# argument they received is garbage. Because the engine is always constructed
# inside its owning PlayerbotAI ctor, the engine facade is deterministically the
# correct value. So instead of skipping the poisoned strategies (which left bots
# without racials/potions/chat behaviors), REPAIR them: write the engine facade
# over the corrupt one and initialize normally. Null strategies are still
# skipped. Composes with B026: it anchors on the unique InitMultipliers call, a
# different line than B026's GetType anchor, and preserves it, so the two
# patches are order-independent.
#
# Full write-up: docs/patches/playerbot-engine-init-facade-guard.md
# Parallelizable: Yes (unique files: PlayerbotAIAware.h, Engine.cpp)

# {{{ patch_B027_playerbots_engine_init_facade_guard
patch_B027_playerbots_engine_init_facade_guard() {
    local AWARE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/Engine/PlayerbotAIAware.h"
    local ENGINE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/Engine/Engine.cpp"

    # --- 1. Public facade accessor on PlayerbotAIAware -------------------------
    # Anchor on the ctor initializer tail (no regex-special chars) and append the
    # getter right after it, inside the existing public section.
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

    # --- 2. Engine::Init stale-facade guard -----------------------------------
    # Insert BEFORE the unique InitMultipliers call. GetType()/HasTargetExclusions()
    # above it return constants (no facade deref), so this anchor guards BOTH
    # botAI-dereferencing calls in the loop (InitMultipliers and InitTriggers;
    # the observed crash is in InitTriggers via RacialsStrategy). The !strategy
    # clause is deliberately redundant with B026 so this stands alone.
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
# }}}

# {{{ unpatch_B027_playerbots_engine_init_facade_guard
unpatch_B027_playerbots_engine_init_facade_guard() {
    local AWARE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/Engine/PlayerbotAIAware.h"
    local ENGINE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/Engine/Engine.cpp"

    # Delete each marker block, restoring the tree to pristine upstream.
    [[ -f "${AWARE}" ]] && sed -i '/>>> B027 facade accessor BEGIN/,/<<< B027 facade accessor END/d' "${AWARE}"
    [[ -f "${ENGINE}" ]] && sed -i '/>>> B027 stale-facade guard BEGIN/,/<<< B027 stale-facade guard END/d' "${ENGINE}"
}
# }}}
