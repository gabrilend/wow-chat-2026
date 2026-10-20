#!/usr/bin/env bash

patch_B010_playerbots_arena_type_none() {
    local FILE="${AC_CODE_DIR}/src/server/game/Battlegrounds/Battleground.h"

    [[ -f "${FILE}" ]] || return 0

    if grep -q "ARENA_TYPE_NONE" "${FILE}" 2>/dev/null; then
        return 0
    fi

    sed -i 's/    ARENA_TYPE_2v2                  = 2,/    ARENA_TYPE_NONE                 = 0,\n    ARENA_TYPE_2v2                  = 2,/' "${FILE}"
}

unpatch_B010_playerbots_arena_type_none() {
    local FILE="${AC_CODE_DIR}/src/server/game/Battlegrounds/Battleground.h"

    [[ -f "${FILE}" ]] || return 0

    sed -i '/ARENA_TYPE_NONE.*= 0,/d' "${FILE}"
}
