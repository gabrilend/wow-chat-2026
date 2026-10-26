#!/usr/bin/env bash

patch_E030_basic_darkmoon_cards() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/15-darkmoon-cards.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/15-darkmoon-cards.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E030] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E030] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E030] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E030_basic_darkmoon_cards() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/15-darkmoon-cards.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/15-darkmoon-cards.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E030_REVERT" "${SQL_FILE}"; then
        echo "  [E030] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E030] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E030] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
