#!/usr/bin/env bash

patch_B003_ale_gameobject_wildcard() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/LuaEngine.cpp"
    [[ ! -f "${FILE}" ]] && return 0

    if grep -q "entry != 0 && !eObjectMgr->GetGameObjectTemplate" "${FILE}"; then
        return 0  # Already patched
    fi

    echo "  [B003] mod-ale: Gameobject wildcard support"

    sed -i 's/if (!eObjectMgr->GetGameObjectTemplate(entry))/\/\/ entry 0 = wildcard for all gameobjects (Issue 307)\n                if (entry != 0 \&\& !eObjectMgr->GetGameObjectTemplate(entry))/g' "${FILE}"
}

unpatch_B003_ale_gameobject_wildcard() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/LuaEngine.cpp"
    [[ ! -f "${FILE}" ]] && return 0
    if grep -q "entry != 0 && !eObjectMgr->GetGameObjectTemplate" "${FILE}"; then
        sed -i '/\/\/ entry 0 = wildcard for all gameobjects (Issue 307)/d' "${FILE}"
        sed -i 's/if (entry != 0 && !eObjectMgr->GetGameObjectTemplate(entry))/if (!eObjectMgr->GetGameObjectTemplate(entry))/g' "${FILE}"
    fi
}
