#!/usr/bin/env bash

patch_E058_beta_dk_outfit_for_level_1() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/18-dk-outfit-for-level-1.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/18-dk-outfit-for-level-1.apply.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E058_APPLY" "${SQL_FILE}"; then
        echo "  [E058] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E058] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E058] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E058_beta_dk_outfit_for_level_1() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/18-dk-outfit-for-level-1.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/18-dk-outfit-for-level-1.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E058_REVERT" "${SQL_FILE}"; then
        echo "  [E058] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E058] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E058] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
