#!/usr/bin/env bash
# B012-player-equipment-slot-sign.sh
# Fixes sign comparison warnings in Player.cpp equipment slot loops
#
# Warning: comparison of integers of different signs: 'int' and 'EquipmentSlots'
# Lines 11196 and 15878 use 'int' for loop variable comparing against unsigned enum
#
# Fix: Change 'int' to 'uint8' to match the unsigned enum type

# {{{ patch_B012_player_equipment_slot_sign
#
# Rewritten 2026-10-03 as exact whole-line edits (patches.sh,
# line_edits_apply / line_edits_revert): each edited line carries the tag
# "  // B012", the revert turns back only tagged lines, and an old line not
# found the expected number of times stops the patch as stale. The old sed
# revert also changed lines upstream had since written the fixed way
# (scripts/verify-patches). Both loops it fixes still read "int" upstream; the other
# "uint8 i = EQUIPMENT_SLOT_START" loops in Player.cpp are upstream's own,
# which the old revert wrongly turned into "int i".

# path (from the source root) <TAB> old line <TAB> new line
B012_EDITS=$(cat <<'EDITS'
src/server/game/Entities/Player/Player.cpp	    for (int slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)	    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
src/server/game/Entities/Player/Player.cpp	    for (int i = EQUIPMENT_SLOT_START; i < EQUIPMENT_SLOT_END; ++i)	    for (uint8 i = EQUIPMENT_SLOT_START; i < EQUIPMENT_SLOT_END; ++i)
EDITS
)

# {{{ patch_B012_player_equipment_slot_sign
patch_B012_player_equipment_slot_sign() {
    line_edits_apply B012 <<< "${B012_EDITS}"
}
# }}}

# {{{ unpatch_B012_player_equipment_slot_sign
unpatch_B012_player_equipment_slot_sign() {
    line_edits_revert B012 <<< "${B012_EDITS}"
}
# }}}
