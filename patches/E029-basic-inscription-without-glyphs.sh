#!/usr/bin/env bash

patch_E029_basic_inscription_without_glyphs() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/14-inscription-without-glyphs.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/14-inscription-without-glyphs.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E029] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E029] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E029] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E029_basic_inscription_without_glyphs() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/14-inscription-without-glyphs.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/14-inscription-without-glyphs.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E029_REVERT" "${SQL_FILE}"; then
        echo "  [E029] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E029] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E029] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
