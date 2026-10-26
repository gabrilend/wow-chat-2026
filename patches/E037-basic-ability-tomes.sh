#!/usr/bin/env bash

patch_E037_basic_ability_tomes() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/22-ability-tomes.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/22-ability-tomes.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E037] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E037] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E037] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E037_basic_ability_tomes() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/22-ability-tomes.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/22-ability-tomes.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E037_REVERT" "${SQL_FILE}"; then
        echo "  [E037] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E037] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E037] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
