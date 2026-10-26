#!/usr/bin/env bash

patch_E053_custom_command_help() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/34-custom-command-help.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/34-custom-command-help.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E053] Apply source missing: ${SRC_FILE} (run scripts/generate-custom-command-help-sql)"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E053] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E053] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E053_custom_command_help() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/34-custom-command-help.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/34-custom-command-help.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E053_REVERT" "${SQL_FILE}"; then
        echo "  [E053] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E053] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E053] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
