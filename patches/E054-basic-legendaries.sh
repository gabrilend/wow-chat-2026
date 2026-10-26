#!/usr/bin/env bash

patch_E054_basic_legendaries() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/35-legendaries.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/35-legendaries.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E054] Apply source missing: ${SRC_FILE} (run scripts/generate-basic-legendaries-sql)"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E054] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E054] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E054_basic_legendaries() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/35-legendaries.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/35-legendaries.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E054_REVERT" "${SQL_FILE}"; then
        echo "  [E054] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E054] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E054] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
