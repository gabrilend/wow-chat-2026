#!/usr/bin/env bash

patch_E060_beta_moonglade_return() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/01-moonglade-return.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_characters.src/01-moonglade-return.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E060] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E060_APPLY" "${SQL_FILE}"; then
        echo "  [E060] Active file already holds apply-form content"
        return 0
    fi

    echo "  [E060] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E060_beta_moonglade_return() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/01-moonglade-return.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_characters.src/01-moonglade-return.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E060_REVERT" "${SQL_FILE}"; then
        echo "  [E060] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E060] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    echo "  [E060] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
