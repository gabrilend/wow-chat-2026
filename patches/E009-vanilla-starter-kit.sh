#!/usr/bin/env bash

_E009_vanilla_starting_equipment_apply() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/02-starting-equipment.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/02-starting-equipment.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E009] Apply source missing: ${SRC_FILE}"; return 1; }

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E009] Active file already matches apply-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E009] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

_E009_vanilla_starting_equipment_revert() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/02-starting-equipment.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E009_REVERT" "${SQL_FILE}"; then
        echo "  [E009] Active file already holds revert-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E009] Writing revert-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E009_REVERT vanilla-starting-equipment
-- Revert-form: drop every row whose Note/comment carries the
-- 'vanilla-148h-' tag prefix. Default rows (upstream DK [TDB PH],
-- per-class talent skill entries) stay intact.
DELETE FROM `playercreateinfo_item`   WHERE `Note`    LIKE 'vanilla-148h-%';
DELETE FROM `playercreateinfo_skills` WHERE `comment` LIKE 'vanilla-148h-%';
SQL
}

_E018_vanilla_kit_required_level_cap_apply() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/06-kit-required-level-cap.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/06-kit-required-level-cap.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E018] Apply source missing: ${SRC_FILE}"; return 1; }

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E018] Active file already matches apply-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E018] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

_E018_vanilla_kit_required_level_cap_revert() {
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


patch_E009_vanilla_starter_kit() {
    _E009_vanilla_starting_equipment_apply || return 1
    _E018_vanilla_kit_required_level_cap_apply || return 1
}
unpatch_E009_vanilla_starter_kit() {
    _E018_vanilla_kit_required_level_cap_revert || return 1
    _E009_vanilla_starting_equipment_revert || return 1
}
