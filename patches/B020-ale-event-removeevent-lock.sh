#!/usr/bin/env bash

patch_B020_ale_event_removeevent_lock() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/ALEEventMgr.cpp"

    if [[ ! -f "${FILE}" ]]; then
        echo "  [B020] WARNING: ${FILE} not found, skipping"
        return 0
    fi

    if awk '/^void ALEEventProcessor::RemoveEvent/,/^}/' "${FILE}" | grep -q "LOCK_ALE"; then
        return 0
    fi

    sed -i '/^        \/\/ Free lua function ref$/i\        LOCK_ALE;' "${FILE}"
}

unpatch_B020_ale_event_removeevent_lock() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/ALEEventMgr.cpp"

    if [[ ! -f "${FILE}" ]]; then
        return 0
    fi

    if ! awk '/^void ALEEventProcessor::RemoveEvent/,/^}/' "${FILE}" | grep -q "LOCK_ALE"; then
        return 0
    fi

    sed -i '/^        LOCK_ALE;$/{N;/\n        \/\/ Free lua function ref$/{s/^        LOCK_ALE;\n//}}' "${FILE}"
}
