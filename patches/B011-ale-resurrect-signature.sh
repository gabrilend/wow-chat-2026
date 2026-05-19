#!/usr/bin/env bash
# B011-ale-resurrect-signature.sh
#
# DEPRECATED 2026-05-19 — removed from PHASE_BEGIN_PATCHES for all profiles.
#
# History: this patch was written when mod-ale had `bool&` and core had `bool`
# in the OnPlayerResurrect signature. The sed'd direction was mod-ale's
# `bool&` down to `bool` to match the older core. Since then both sides
# converged — upstream mod-ale PR #376 / commit 3eca176 updated mod-ale, and
# core's PlayerScript.h:638 currently uses `bool&`. The two signatures now
# match upstream. The patch has become actively harmful: applying it takes
# correct code and breaks the override match, causing the build to fail with
# "fatal error: non-virtual member function marked 'override' hides virtual
# member function" at ALE_SC.cpp:650.
#
# File kept (not deleted) in case upstream regresses and the patch is needed
# again. If that happens, re-register it in PHASE_BEGIN_PATCHES and update
# the sed direction to match whatever signature mismatch needs correcting.
#
# Original (now-obsolete) intent below:
# Fixes OnPlayerResurrect signature mismatch between mod-ale and core
# mod-ale declared: bool& applySickness (reference) [at that time]
# Core declared:    bool applySickness  (value)     [at that time]
# This patch updated mod-ale to match the core signature.

# {{{ patch_B011_ale_resurrect_signature
patch_B011_ale_resurrect_signature() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/ALE_SC.cpp"

    [[ -f "${FILE}" ]] || return 0

    # Check if already patched (no bool& in the signature)
    if ! grep -q "OnPlayerResurrect.*bool&" "${FILE}" 2>/dev/null; then
        return 0
    fi

    # Patch: Change bool& to bool
    sed -i 's/OnPlayerResurrect(Player\* player, float \/\*restore_percent\*\/, bool& \/\*applySickness\*\/)/OnPlayerResurrect(Player* player, float \/*restore_percent*\/, bool \/*applySickness*\/)/' "${FILE}"
}
# }}}

# {{{ unpatch_B011_ale_resurrect_signature
unpatch_B011_ale_resurrect_signature() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/ALE_SC.cpp"

    [[ -f "${FILE}" ]] || return 0

    # Reverse: Change bool back to bool&
    sed -i 's/OnPlayerResurrect(Player\* player, float \/\*restore_percent\*\/, bool \/\*applySickness\*\/)/OnPlayerResurrect(Player* player, float \/*restore_percent*\/, bool\& \/*applySickness*\/)/' "${FILE}"
}
# }}}
