#!/usr/bin/env bash

patch_E016_beta_empty_loot_chests() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/16-empty-loot-chests.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/16-empty-loot-chests.apply.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E016_APPLY" "${SQL_FILE}"; then
        echo "  [E016] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E016] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E016] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E016_beta_empty_loot_chests() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/16-empty-loot-chests.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E016_REVERT" "${SQL_FILE}"; then
        echo "  [E016] Active file already holds revert-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E016] Writing revert-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E016_REVERT beta-empty-loot-chests
-- Revert-form: drop the project's custom empty-loot gameobjects.
-- Entry range 900001-900037 is project-owned.
DELETE FROM `gameobject_template` WHERE `entry` BETWEEN 900001 AND 900037;
SQL
}
