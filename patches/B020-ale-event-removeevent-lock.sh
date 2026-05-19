#!/usr/bin/env bash
# B020 - Add LOCK_ALE to ALEEventProcessor::RemoveEvent
# Issue 208: ALE registry corruption crash
#
# Root cause: ALEEventProcessor::Update is called by ALE::OnWorldUpdate
# WITHOUT holding LOCK_ALE. Inside Update, RemoveEvent calls
# luaL_unref(L, LUA_REGISTRYINDEX, funcRef) without the lock. This races
# with any concurrent thread holding LOCK_ALE and doing luaL_ref or other
# registry mutations — Lua's internal ref-slot free list gets corrupted,
# and subsequent luaL_ref allocations return slots whose contents are
# inconsistent. Result: a TABLE ends up in a registry slot where the
# caller expected a function ref, and ExecuteCall asserts.
#
# Fix: acquire LOCK_ALE inside RemoveEvent, around the luaL_unref call.
# Safe because ALE::LockType is std::recursive_mutex (LuaEngine.h:115),
# so callers that already hold LOCK_ALE (notably the destructor) re-enter
# without deadlock.
#
# Parallelizable: Yes (single file, narrow scope)

# {{{ patch_B020_ale_event_removeevent_lock
patch_B020_ale_event_removeevent_lock() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/ALEEventMgr.cpp"

    if [[ ! -f "${FILE}" ]]; then
        echo "  [B020] WARNING: ${FILE} not found, skipping"
        return 0
    fi

    # Idempotent check: don't re-apply if RemoveEvent already has LOCK_ALE.
    # Use awk to extract just the RemoveEvent function body so we don't
    # false-positive on LOCK_ALE elsewhere in the file (constructor,
    # destructor, etc.)
    if awk '/^void ALEEventProcessor::RemoveEvent/,/^}/' "${FILE}" | grep -q "LOCK_ALE"; then
        return 0
    fi

    # Insert "LOCK_ALE;" with matching 8-space indent immediately before
    # the "// Free lua function ref" comment. That comment is unique to
    # this function in this file, so the match anchor is precise.
    sed -i '/^        \/\/ Free lua function ref$/i\        LOCK_ALE;' "${FILE}"
}
# }}}

# {{{ unpatch_B020_ale_event_removeevent_lock
unpatch_B020_ale_event_removeevent_lock() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/ALEEventMgr.cpp"

    if [[ ! -f "${FILE}" ]]; then
        return 0
    fi

    # Idempotent: only remove if it's actually there. Look specifically
    # in the RemoveEvent body so we don't strip LOCK_ALE from other
    # functions that legitimately use it.
    if ! awk '/^void ALEEventProcessor::RemoveEvent/,/^}/' "${FILE}" | grep -q "LOCK_ALE"; then
        return 0
    fi

    # Delete the "        LOCK_ALE;" line ONLY when it's immediately
    # followed by the "// Free lua function ref" comment line. sed's N
    # reads the next line into the pattern space; the inner regex matches
    # the two-line pair; the substitution removes just the LOCK_ALE; line.
    sed -i '/^        LOCK_ALE;$/{N;/\n        \/\/ Free lua function ref$/{s/^        LOCK_ALE;\n//}}' "${FILE}"
}
# }}}
