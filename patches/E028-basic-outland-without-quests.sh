#!/usr/bin/env bash

patch_E028_basic_outland_without_quests() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/13-outland-without-quests.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/13-outland-without-quests.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E028] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E028] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E028] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E028_basic_outland_without_quests() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/13-outland-without-quests.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/13-outland-without-quests.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E028_REVERT" "${SQL_FILE}"; then
        echo "  [E028] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E028] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E028] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
