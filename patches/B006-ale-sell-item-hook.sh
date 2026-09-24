#!/usr/bin/env bash
# B006 - Add PLAYER_EVENT_ON_SELL_ITEM to ALE
# Issue 403 (was 150): ALE sell item hook
# Parallelizable: Yes (unique files)
#
# Every multi-line insertion is bracketed by ">>> B006 ... BEGIN" /
# "<<< B006 ... END" marker comments, and every single-line insertion carries
# a trailing "// B006" tag; the revert deletes exactly those. (Until
# 2026-09-23 the revert re-matched the inserted text instead: it never removed
# the #include it added, and it deleted the hook-call lines before trying to
# remove their #ifdef shells, so the shells stayed. The tree never returned
# to upstream after a build.)

# {{{ patch_B006_ale_sell_item_hook
patch_B006_ale_sell_item_hook() {
    local HOOKS_H="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/Hooks.h"
    local ENGINE_H="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/LuaEngine.h"
    local PLAYER_HOOKS="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/hooks/PlayerHooks.cpp"
    local ITEM_HANDLER="${AC_CODE_DIR}/src/server/game/Handlers/ItemHandler.cpp"
    local APPLIED=0

    # 1. Add event enum to Hooks.h (one tagged line)
    if [[ -f "${HOOKS_H}" ]] && ! grep -q "PLAYER_EVENT_ON_SELL_ITEM" "${HOOKS_H}"; then
        grep -q 'PLAYER_EVENT_ON_RELEASED_GHOST                      =     73,' "${HOOKS_H}" \
            || { echo "  [B006] ERROR: PLAYER_EVENT_ON_RELEASED_GHOST = 73 anchor not found in ${HOOKS_H}"; return 1; }
        sed -i 's/PLAYER_EVENT_ON_RELEASED_GHOST                      =     73,       \/\/ (event, player)/PLAYER_EVENT_ON_RELEASED_GHOST                      =     73,       \/\/ (event, player)\
        PLAYER_EVENT_ON_SELL_ITEM                           =     74,       \/\/ (event, player, item, vendor, count) B006/' "${HOOKS_H}"
        APPLIED=1
    fi

    # 2. Add method declaration to LuaEngine.h (one tagged line)
    if [[ -f "${ENGINE_H}" ]] && ! grep -q "void OnSellItem" "${ENGINE_H}"; then
        grep -q "void OnStoreNewItem" "${ENGINE_H}" \
            || { echo "  [B006] ERROR: OnStoreNewItem anchor not found in ${ENGINE_H}"; return 1; }
        sed -i '/void OnStoreNewItem/a \    void OnSellItem(Player* player, Item* item, Creature* vendor, uint32 count); // B006' "${ENGINE_H}"
        APPLIED=1
    fi

    # 3. Append the implementation to PlayerHooks.cpp (bracketed)
    if [[ -f "${PLAYER_HOOKS}" ]] && ! grep -q "B006-sell-item-impl BEGIN" "${PLAYER_HOOKS}"; then
        cat >> "${PLAYER_HOOKS}" << 'EOFHOOK'
// >>> B006-sell-item-impl BEGIN (Issue 403: ALE sell item hook)
void ALE::OnSellItem(Player* pPlayer, Item* pItem, Creature* pVendor, uint32 count)
{
    START_HOOK(PLAYER_EVENT_ON_SELL_ITEM);
    Push(pPlayer);
    Push(pItem);
    Push(pVendor);
    Push(count);
    CallAllFunctions(PlayerEventBindings, key);
}
// <<< B006-sell-item-impl END
EOFHOOK
        APPLIED=1
    fi

    # 4. Add ALE include to ItemHandler.cpp (bracketed)
    if [[ -f "${ITEM_HANDLER}" ]] && ! grep -q "B006-include BEGIN" "${ITEM_HANDLER}"; then
        grep -q '#include "WorldSession.h"' "${ITEM_HANDLER}" \
            || { echo "  [B006] ERROR: WorldSession.h include anchor not found in ${ITEM_HANDLER}"; return 1; }
        sed -i '/#include "WorldSession.h"/a \
// >>> B006-include BEGIN\
#ifdef MOD_ALE\
#include "LuaEngine.h"\
#endif\
// <<< B006-include END' "${ITEM_HANDLER}"
        APPLIED=1
    fi

    # 5. Add hook calls in HandleSellItemOpcode (two bracketed blocks)
    if [[ -f "${ITEM_HANDLER}" ]] && ! grep -q "B006-sell-call BEGIN" "${ITEM_HANDLER}"; then
        if [[ "$(grep -c '_player->AddItemToBuyBackSlot(pNewItem, money);' "${ITEM_HANDLER}")" -ne 1 ||
              "$(grep -c '_player->AddItemToBuyBackSlot(pItem, money);' "${ITEM_HANDLER}")" -ne 1 ]]; then
            echo "  [B006] ERROR: expected exactly one of each AddItemToBuyBackSlot call in ${ITEM_HANDLER}"
            return 1
        fi
        sed -i '/_player->AddItemToBuyBackSlot(pNewItem, money);/{
            i\
                    // >>> B006-sell-call BEGIN\
#ifdef MOD_ALE\
                    sALE->OnSellItem(_player, pNewItem, creature, packet.Count);\
#endif\
                    // <<< B006-sell-call END
        }' "${ITEM_HANDLER}"
        sed -i '/_player->AddItemToBuyBackSlot(pItem, money);/{
            i\
                    // >>> B006-sell-call BEGIN\
#ifdef MOD_ALE\
                    sALE->OnSellItem(_player, pItem, creature, pItem->GetCount());\
#endif\
                    // <<< B006-sell-call END
        }' "${ITEM_HANDLER}"
        APPLIED=1
    fi

    if [[ "${APPLIED}" -eq 1 ]]; then
        echo "  [B006] ALE sell item hook (PLAYER_EVENT_ON_SELL_ITEM = 74)"
    fi
}
# }}}

# {{{ unpatch_B006_ale_sell_item_hook
unpatch_B006_ale_sell_item_hook() {
    local HOOKS_H="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/Hooks.h"
    local ENGINE_H="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/LuaEngine.h"
    local PLAYER_HOOKS="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/hooks/PlayerHooks.cpp"
    local ITEM_HANDLER="${AC_CODE_DIR}/src/server/game/Handlers/ItemHandler.cpp"

    [[ -f "${HOOKS_H}" ]]      && sed -i '/PLAYER_EVENT_ON_SELL_ITEM .*B006$/d' "${HOOKS_H}"
    [[ -f "${ENGINE_H}" ]]     && sed -i '/void OnSellItem(.*); \/\/ B006$/d' "${ENGINE_H}"
    [[ -f "${PLAYER_HOOKS}" ]] && sed -i '/>>> B006-sell-item-impl BEGIN/,/<<< B006-sell-item-impl END/d' "${PLAYER_HOOKS}"
    if [[ -f "${ITEM_HANDLER}" ]]; then
        sed -i '/>>> B006-include BEGIN/,/<<< B006-include END/d' "${ITEM_HANDLER}"
        sed -i '/>>> B006-sell-call BEGIN/,/<<< B006-sell-call END/d' "${ITEM_HANDLER}"
    fi
    return 0
}
# }}}
