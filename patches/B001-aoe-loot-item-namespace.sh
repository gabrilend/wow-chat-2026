#!/usr/bin/env bash
# B001 - Fix Item vs WorldPackets::Item ambiguity in mod-aoe-loot
# Parallelizable: Yes (unique file)

# {{{ patch_B001_aoe_loot_item_namespace
patch_B001_aoe_loot_item_namespace() {
    local FILE="${AC_CODE_DIR}/modules/mod-aoe-loot/src/aoe_loot.cpp"
    [[ ! -f "${FILE}" ]] && return 0
    if grep -q "^[[:space:]]*Item\* pItem = player->GetItemByGuid" "${FILE}"; then
        echo "  [B001] mod-aoe-loot: Item namespace fix"
        sed -i 's/^\([[:space:]]*\)Item\* pItem = player->GetItemByGuid/\1::Item* pItem = player->GetItemByGuid/' "${FILE}"
    fi
}
# }}}

# {{{ unpatch_B001_aoe_loot_item_namespace
unpatch_B001_aoe_loot_item_namespace() {
    local FILE="${AC_CODE_DIR}/modules/mod-aoe-loot/src/aoe_loot.cpp"
    [[ ! -f "${FILE}" ]] && return 0
    if grep -q "^[[:space:]]*::Item\* pItem = player->GetItemByGuid" "${FILE}"; then
        sed -i 's/^\([[:space:]]*\)::Item\* pItem = player->GetItemByGuid/\1Item* pItem = player->GetItemByGuid/' "${FILE}"
    fi
}
# }}}
