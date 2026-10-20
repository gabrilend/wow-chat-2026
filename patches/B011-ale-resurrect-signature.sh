#!/usr/bin/env bash

patch_B011_ale_resurrect_signature() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/ALE_SC.cpp"

    [[ -f "${FILE}" ]] || return 0

    if ! grep -q "OnPlayerResurrect.*bool&" "${FILE}" 2>/dev/null; then
        return 0
    fi

    sed -i 's/OnPlayerResurrect(Player\* player, float \/\*restore_percent\*\/, bool& \/\*applySickness\*\/)/OnPlayerResurrect(Player* player, float \/*restore_percent*\/, bool \/*applySickness*\/)/' "${FILE}"
}

unpatch_B011_ale_resurrect_signature() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/ALE_SC.cpp"

    [[ -f "${FILE}" ]] || return 0

    sed -i 's/OnPlayerResurrect(Player\* player, float \/\*restore_percent\*\/, bool \/\*applySickness\*\/)/OnPlayerResurrect(Player* player, float \/*restore_percent*\/, bool\& \/*applySickness*\/)/' "${FILE}"
}
