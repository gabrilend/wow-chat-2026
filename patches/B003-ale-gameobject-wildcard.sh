#!/usr/bin/env bash
# B003 - Enable entry 0 as wildcard for RegisterGameObjectEvent
# Issue 325: ALE doesn't support entry 0 wildcard for gameobject events
# Parallelizable: Yes (unique file)

# {{{ patch_B003_ale_gameobject_wildcard
patch_B003_ale_gameobject_wildcard() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/LuaEngine.cpp"
    [[ ! -f "${FILE}" ]] && return 0

    # Check if patch already applied
    if grep -q "entry != 0 && !eObjectMgr->GetGameObjectTemplate" "${FILE}"; then
        return 0  # Already patched
    fi

    echo "  [B003] mod-ale: Gameobject wildcard support"

    # Patch both REGTYPE_GAMEOBJECT and REGTYPE_GAMEOBJECT_GOSSIP
    sed -i 's/if (!eObjectMgr->GetGameObjectTemplate(entry))/\/\/ entry 0 = wildcard for all gameobjects (Issue 325)\n                if (entry != 0 \&\& !eObjectMgr->GetGameObjectTemplate(entry))/g' "${FILE}"
}
# }}}

# {{{ unpatch_B003_ale_gameobject_wildcard
unpatch_B003_ale_gameobject_wildcard() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/LuaEngine.cpp"
    [[ ! -f "${FILE}" ]] && return 0
    if grep -q "entry != 0 && !eObjectMgr->GetGameObjectTemplate" "${FILE}"; then
        sed -i '/\/\/ entry 0 = wildcard for all gameobjects (Issue 325)/d' "${FILE}"
        sed -i 's/if (entry != 0 && !eObjectMgr->GetGameObjectTemplate(entry))/if (!eObjectMgr->GetGameObjectTemplate(entry))/g' "${FILE}"
    fi
}
# }}}
