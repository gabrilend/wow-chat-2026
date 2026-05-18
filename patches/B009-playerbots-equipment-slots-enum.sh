#!/usr/bin/env bash
# B009-playerbots-equipment-slots-enum.sh
# Fixes enum underlying type mismatch between mod-playerbots and AzerothCore
#
# mod-playerbots forward-declares: enum EquipmentSlots : uint32;
# AzerothCore defines: enum EquipmentSlots { ... }
#
# C++ requires forward declarations to match the underlying type.
# This patch adds `: uint32` to the core definition to match mod-playerbots.

# {{{ patch_B009_playerbots_equipment_slots_enum
patch_B009_playerbots_equipment_slots_enum() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Player/Player.h"

    [[ -f "${FILE}" ]] || return 0

    # Check if already patched (has : uint32 after EquipmentSlots)
    if grep -q "enum EquipmentSlots : uint32" "${FILE}" 2>/dev/null; then
        return 0
    fi

    # Patch: Add uint32 underlying type to EquipmentSlots enum
    sed -i 's/^enum EquipmentSlots\([[:space:]]*\/\/\)/enum EquipmentSlots : uint32\1/' "${FILE}"
}
# }}}

# {{{ unpatch_B009_playerbots_equipment_slots_enum
unpatch_B009_playerbots_equipment_slots_enum() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Player/Player.h"

    [[ -f "${FILE}" ]] || return 0

    # Reverse: Remove uint32 underlying type
    sed -i 's/^enum EquipmentSlots : uint32\([[:space:]]*\/\/\)/enum EquipmentSlots\1/' "${FILE}"
}
# }}}
