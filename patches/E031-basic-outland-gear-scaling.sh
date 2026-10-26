#!/usr/bin/env bash

patch_E031_basic_outland_gear_scaling() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/16-outland-gear-scaling.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/16-outland-gear-scaling.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E031] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E031] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E031] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E031_basic_outland_gear_scaling() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/16-outland-gear-scaling.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/16-outland-gear-scaling.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E031_REVERT" "${SQL_FILE}"; then
        echo "  [E031] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E031] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E031] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
