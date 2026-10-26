#!/usr/bin/env bash

patch_E061_beta_narrator_reading() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/02-narrator-reading.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_characters.src/02-narrator-reading.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E061] Apply source missing: ${SRC_FILE}"; return 1; }
    mkdir -p "${DIR}/sql/${PROFILE}/db_characters"

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E061_APPLY" "${SQL_FILE}"; then
        echo "  [E061] Active file already holds apply-form content"
        return 0
    fi

    echo "  [E061] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E061_beta_narrator_reading() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/02-narrator-reading.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_characters.src/02-narrator-reading.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E061_REVERT" "${SQL_FILE}"; then
        echo "  [E061] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E061] Revert source missing: ${SRC_FILE}"; return 1; }
    mkdir -p "${DIR}/sql/${PROFILE}/db_characters"

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    echo "  [E061] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
