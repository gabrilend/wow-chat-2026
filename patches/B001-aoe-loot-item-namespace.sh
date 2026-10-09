#!/usr/bin/env bash
# B001 - Fix Item vs WorldPackets::Item ambiguity in mod-aoe-loot
# Parallelizable: Yes (unique file)
#
# Also, since 2026-10-09: the packet hook takes a read-only packet. The core
# at 2a2211cd8 keeps only CanPacketReceive(WorldSession*, WorldPacket
# const&); the fork (TerraByte-tbwps, last changed 2025-12) still overrides
# the removed non-const one, which no longer compiles ("marked 'override'
# hides virtual member function"). Its hook only reads the opcode, so the
# two signature lines become const and nothing else changes. The core at
# the old pin had both overloads, so this edit compiles there too.

# path (from the source root) <TAB> old line <TAB> new line
B001_EDITS=$(cat <<'EDITS'
modules/mod-aoe-loot/src/aoe_loot.h	    bool CanPacketReceive(WorldSession* session, WorldPacket& packet) override;	    bool CanPacketReceive(WorldSession* session, WorldPacket const& packet) override;
modules/mod-aoe-loot/src/aoe_loot.cpp	bool AoeLootManager::CanPacketReceive(WorldSession* session, WorldPacket& packet)	bool AoeLootManager::CanPacketReceive(WorldSession* session, WorldPacket const& packet)
EDITS
)

# {{{ patch_B001_aoe_loot_item_namespace
patch_B001_aoe_loot_item_namespace() {
    local FILE="${AC_CODE_DIR}/modules/mod-aoe-loot/src/aoe_loot.cpp"
    [[ ! -f "${FILE}" ]] && return 0
    if grep -q "^[[:space:]]*Item\* pItem = player->GetItemByGuid" "${FILE}"; then
        echo "  [B001] mod-aoe-loot: Item namespace fix"
        sed -i 's/^\([[:space:]]*\)Item\* pItem = player->GetItemByGuid/\1::Item* pItem = player->GetItemByGuid/' "${FILE}"
    fi
    line_edits_apply B001 <<< "${B001_EDITS}"
}
# }}}

# {{{ unpatch_B001_aoe_loot_item_namespace
unpatch_B001_aoe_loot_item_namespace() {
    local FILE="${AC_CODE_DIR}/modules/mod-aoe-loot/src/aoe_loot.cpp"
    [[ ! -f "${FILE}" ]] && return 0
    if grep -q "^[[:space:]]*::Item\* pItem = player->GetItemByGuid" "${FILE}"; then
        sed -i 's/^\([[:space:]]*\)::Item\* pItem = player->GetItemByGuid/\1Item* pItem = player->GetItemByGuid/' "${FILE}"
    fi
    line_edits_revert B001 <<< "${B001_EDITS}"
}
# }}}
