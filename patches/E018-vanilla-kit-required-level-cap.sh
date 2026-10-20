#!/usr/bin/env bash
# E018-vanilla-kit-required-level-cap.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E018_vanilla_kit_required_level_cap
# Clones every kit-referenced item to a new entry (original + 2000000),
# tunes the clones to RequiredLevel=20 + DPS=15 (weapons) / DPS=20
# (wands) + per-stat overrides (e.g. +1 Spell Power on the Amani
# Sacrificial Dagger clone), restores originals to their canonical
# pre-modification RequiredLevel, and sweeps every loot-table /
# vendor / quest-reward reference in the vanilla profile world DB
# so the live world consistently uses the server-tuned clones.
#
# Supersedes the V1 patch (148h follow-up): V1 modified RL in-place,
# which leaked across the entire world's drops/vendors/quests, and
# the V1 unpatch was a soft revert (floor to RL=22, no snapshot). The
# V2 clone-to-new-ID design fixes both — originals stay canonical as
# Wowhead references, clones carry the server-tuned values, and the
# revert is deterministic (drop the 2000000-2099999 range + reverse
# the sweep using the same clone-map).
#
# See 148h "Item Cloning Procedure" + "Loot Table Update Procedure".
# Vanilla-DB scope only (acore_world_vanilla). Release/beta read a
# different world DB so their item_template stays untouched.
patch_E018_vanilla_kit_required_level_cap() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/06-kit-required-level-cap.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/06-kit-required-level-cap.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E018] Apply source missing: ${SRC_FILE}"; return 1; }

    # Idempotence by content comparison rather than marker presence —
    # apply-form source can change with the same marker (DPS
    # retuning, kit additions). See same-shape comment in E009.
    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E018] Active file already matches apply-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E018] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E018_vanilla_kit_required_level_cap() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/06-kit-required-level-cap.sql"
    local REV_FILE="${DIR}/sql/${PROFILE}/db_world.src/06-kit-required-level-cap.revert.sql"

    [[ ! -f "${REV_FILE}" ]] && { echo "  [E018] Revert source missing: ${REV_FILE}"; return 1; }

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${REV_FILE}" "${SQL_FILE}"; then
        echo "  [E018] Active file already matches revert-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E018] Copying revert-form source → ${SQL_FILE}"
    cp "${REV_FILE}" "${SQL_FILE}"
}
# -- }}}
