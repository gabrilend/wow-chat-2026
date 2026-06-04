#!/usr/bin/env bash
# B012-player-equipment-slot-sign.sh
# Fixes sign comparison warnings in Player.cpp equipment slot loops
#
# Warning: comparison of integers of different signs: 'int' and 'EquipmentSlots'
# Lines 11196 and 15878 use 'int' for loop variable comparing against unsigned enum
#
# Fix: Change 'int' to 'uint8' to match the unsigned enum type

# {{{ patch_B012_player_equipment_slot_sign
patch_B012_player_equipment_slot_sign() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Player/Player.cpp"

    [[ -f "${FILE}" ]] || return 0

    # Check if already patched (no 'int slot = EQUIPMENT_SLOT_START' pattern)
    if ! grep -q "for (int slot = EQUIPMENT_SLOT_START" "${FILE}" 2>/dev/null && \
       ! grep -q "for (int i = EQUIPMENT_SLOT_START" "${FILE}" 2>/dev/null; then
        return 0
    fi

    # Fix ToggleMetaGemsActive: int slot -> uint8 slot
    sed -i 's/for (int slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END/for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END/' "${FILE}"

    # Fix GetAverageItemLevelForDF: int i -> uint8 i
    sed -i 's/for (int i = EQUIPMENT_SLOT_START; i < EQUIPMENT_SLOT_END/for (uint8 i = EQUIPMENT_SLOT_START; i < EQUIPMENT_SLOT_END/' "${FILE}"
}
# }}}

# {{{ unpatch_B012_player_equipment_slot_sign
unpatch_B012_player_equipment_slot_sign() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Player/Player.cpp"

    [[ -f "${FILE}" ]] || return 0

    # Reverse: uint8 slot -> int slot
    sed -i 's/for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END/for (int slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END/' "${FILE}"

    # Reverse: uint8 i -> int i
    sed -i 's/for (uint8 i = EQUIPMENT_SLOT_START; i < EQUIPMENT_SLOT_END/for (int i = EQUIPMENT_SLOT_START; i < EQUIPMENT_SLOT_END/' "${FILE}"
}
# }}}
