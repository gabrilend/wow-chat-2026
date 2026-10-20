#!/usr/bin/env bash
# E020-vanilla-mount-level-requirements.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E020_vanilla_mount_level_requirements
# Push the two ground riding skills to Classic level gates (148l): Apprentice
# Riding to level 40, Journeyman to 60. Under vanilla's level-40 cap the 60%
# mount becomes the cap reward and the 100% mount is permanently out of reach.
#
# Same cp-apply / cp-revert idiom as E008/E018: the apply-form source at
# sql/vanilla/db_world.src/05-mount-level-requirements.apply.sql is copied into
# the AC-watched active dir; the revert-form source restores the 20/40
# defaults. The UPDATEs touch both trainer_spell (the live trainer gate) and
# the legacy npc_trainer table so the two never disagree.
patch_E020_vanilla_mount_level_requirements() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/05-mount-level-requirements.sql"
    local SRC_FILE="$(_shared_sql_src db_world)/05-mount-level-requirements.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E020] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register first, on every run: INSERT IGNORE makes it a no-op once the
    # row exists, and a run that found MySQL down must not be the last word
    # (the early return below would otherwise skip registration forever).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    # Idempotence by content comparison, not by marker: a marker check left
    # the active file stale whenever the source was edited (new flavor lines,
    # retuned values), so an existing install never picked the edit up.
    # Same shape as E018. On a change AC's UpdateFetcher sees a new hash and
    # re-runs the file, which is written to be re-applicable.
    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E020] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E020] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E020_vanilla_mount_level_requirements() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/05-mount-level-requirements.sql"
    local SRC_FILE="$(_shared_sql_src db_world)/05-mount-level-requirements.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E020_REVERT" "${SQL_FILE}"; then
        echo "  [E020] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E020] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E020] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
