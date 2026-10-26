#!/usr/bin/env bash

patch_E011_beta_dk_class_system() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/11-dk-class-system.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/11-dk-class-system.apply.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E011_APPLY" "${SQL_FILE}"; then
        echo "  [E011] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E011] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E011] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E011_beta_dk_class_system() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/11-dk-class-system.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/11-dk-class-system.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E011_REVERT" "${SQL_FILE}"; then
        echo "  [E011] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E011] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E011] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
