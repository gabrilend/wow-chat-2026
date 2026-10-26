#!/usr/bin/env bash

E071_DIR="${BASH_SOURCE[0]%/*}"

patch_E071_basic_fight_multipliers() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/40-fight-multipliers.sql"
    local SRC_FILE="${E071_DIR}/40-fight-multipliers.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E071] Apply source missing: ${SRC_FILE} (run scripts/generate-basic-fight-multipliers-sql)"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E071] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E071] Copying apply-form source → ${SQL_FILE}"
    mkdir -p "$(dirname "${SQL_FILE}")"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E071_basic_fight_multipliers() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/40-fight-multipliers.sql"
    local SRC_FILE="${E071_DIR}/40-fight-multipliers.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E071_REVERT" "${SQL_FILE}"; then
        echo "  [E071] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E071] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E071] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
