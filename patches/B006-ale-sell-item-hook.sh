#!/usr/bin/env bash
# B006 - Add PLAYER_EVENT_ON_SELL_ITEM to ALE
# Issue 403 (was 150): ALE sell item hook
# Parallelizable: Yes (unique files)

# {{{ patch_B006_ale_sell_item_hook
patch_B006_ale_sell_item_hook() {
    local HOOKS_H="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/Hooks.h"
    local ENGINE_H="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/LuaEngine.h"
    local PLAYER_HOOKS="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/hooks/PlayerHooks.cpp"
    local ITEM_HANDLER="${AC_CODE_DIR}/src/server/game/Handlers/ItemHandler.cpp"
    local APPLIED=0

    # 1. Add event enum to Hooks.h
    if [[ -f "${HOOKS_H}" ]] && ! grep -q "PLAYER_EVENT_ON_SELL_ITEM" "${HOOKS_H}"; then
        sed -i 's/PLAYER_EVENT_ON_RELEASED_GHOST                      =     73,       \/\/ (event, player)/PLAYER_EVENT_ON_RELEASED_GHOST                      =     73,       \/\/ (event, player)\
        PLAYER_EVENT_ON_SELL_ITEM                           =     74,       \/\/ (event, player, item, vendor, count)/' "${HOOKS_H}"
        APPLIED=1
    fi

    # 2. Add method declaration to LuaEngine.h
    if [[ -f "${ENGINE_H}" ]] && ! grep -q "void OnSellItem" "${ENGINE_H}"; then
        sed -i '/void OnStoreNewItem/a \    void OnSellItem(Player* player, Item* item, Creature* vendor, uint32 count);' "${ENGINE_H}"
        APPLIED=1
    fi

    # 3. Add implementation to PlayerHooks.cpp
    if [[ -f "${PLAYER_HOOKS}" ]] && ! grep -q "ALE::OnSellItem" "${PLAYER_HOOKS}"; then
        cat >> "${PLAYER_HOOKS}" << 'EOFHOOK'

// Issue 403: ALE sell item hook
void ALE::OnSellItem(Player* pPlayer, Item* pItem, Creature* pVendor, uint32 count)
{
    START_HOOK(PLAYER_EVENT_ON_SELL_ITEM);
    Push(pPlayer);
    Push(pItem);
    Push(pVendor);
    Push(count);
    CallAllFunctions(PlayerEventBindings, key);
}
EOFHOOK
        APPLIED=1
    fi

    # 4. Add ALE include to ItemHandler.cpp
    if [[ -f "${ITEM_HANDLER}" ]] && ! grep -q '#include "LuaEngine.h"' "${ITEM_HANDLER}"; then
        sed -i '/#include "WorldSession.h"/a \
\
#ifdef MOD_ALE\
#include "LuaEngine.h"\
#endif' "${ITEM_HANDLER}"
        APPLIED=1
    fi

    # 5. Add hook calls in HandleSellItemOpcode
    if [[ -f "${ITEM_HANDLER}" ]] && ! grep -q "sALE->OnSellItem" "${ITEM_HANDLER}"; then
        sed -i '/_player->AddItemToBuyBackSlot(pNewItem, money);/{
            i\
\
#ifdef MOD_ALE\
                    sALE->OnSellItem(_player, pNewItem, creature, packet.Count);\
#endif
        }' "${ITEM_HANDLER}"
        sed -i '/_player->AddItemToBuyBackSlot(pItem, money);/{
            i\
\
#ifdef MOD_ALE\
                    sALE->OnSellItem(_player, pItem, creature, pItem->GetCount());\
#endif
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

    # 1. Remove event from Hooks.h
    if [[ -f "${HOOKS_H}" ]]; then
        sed -i '/PLAYER_EVENT_ON_SELL_ITEM/d' "${HOOKS_H}"
    fi

    # 2. Remove method declaration from LuaEngine.h
    if [[ -f "${ENGINE_H}" ]]; then
        sed -i '/void OnSellItem(Player\* player, Item\* item, Creature\* vendor, uint32 count);/d' "${ENGINE_H}"
    fi

    # 3. Remove implementation from PlayerHooks.cpp
    if [[ -f "${PLAYER_HOOKS}" ]]; then
        sed -i '/\/\/ Issue 403: ALE sell item hook/,/^}$/d' "${PLAYER_HOOKS}"
    fi

    # 5. Remove hook calls from ItemHandler.cpp
    if [[ -f "${ITEM_HANDLER}" ]]; then
        sed -i '/sALE->OnSellItem/d' "${ITEM_HANDLER}"
        sed -i '/^#ifdef MOD_ALE$/{N; /sALE->OnSellItem/d}' "${ITEM_HANDLER}" 2>/dev/null || true
    fi
}
# }}}
