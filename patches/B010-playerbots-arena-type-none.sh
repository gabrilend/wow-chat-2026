#!/usr/bin/env bash
# B010-playerbots-arena-type-none.sh
# Adds ARENA_TYPE_NONE constant required by mod-playerbots
#
# mod-playerbots checks: if (type != ARENA_TYPE_NONE)
# But the core enum only defines 2v2, 3v3, 5v5 - no NONE value.
# This patch adds ARENA_TYPE_NONE = 0 to the ArenaType enum.

# {{{ patch_B010_playerbots_arena_type_none
patch_B010_playerbots_arena_type_none() {
    local FILE="${AC_CODE_DIR}/src/server/game/Battlegrounds/Battleground.h"

    [[ -f "${FILE}" ]] || return 0

    # Check if already patched
    if grep -q "ARENA_TYPE_NONE" "${FILE}" 2>/dev/null; then
        return 0
    fi

    # Patch: Add ARENA_TYPE_NONE = 0 before ARENA_TYPE_2v2
    sed -i 's/    ARENA_TYPE_2v2                  = 2,/    ARENA_TYPE_NONE                 = 0,\n    ARENA_TYPE_2v2                  = 2,/' "${FILE}"
}
# }}}

# {{{ unpatch_B010_playerbots_arena_type_none
unpatch_B010_playerbots_arena_type_none() {
    local FILE="${AC_CODE_DIR}/src/server/game/Battlegrounds/Battleground.h"

    [[ -f "${FILE}" ]] || return 0

    # Remove ARENA_TYPE_NONE line
    sed -i '/ARENA_TYPE_NONE.*= 0,/d' "${FILE}"
}
# }}}
