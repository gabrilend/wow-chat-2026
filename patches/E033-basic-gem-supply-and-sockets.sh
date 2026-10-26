#!/usr/bin/env bash

_E033_basic_gem_supply_apply() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/18-gem-supply.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/18-gem-supply.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E033] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E033] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E033] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

_E033_basic_gem_supply_revert() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/18-gem-supply.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/18-gem-supply.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E033_REVERT" "${SQL_FILE}"; then
        echo "  [E033] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E033] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E033] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

_E034_basic_titan_jewelers_apply() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/19-titan-jewelers.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/19-titan-jewelers.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E034] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E034] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E034] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

_E034_basic_titan_jewelers_revert() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/19-titan-jewelers.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/19-titan-jewelers.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E034_REVERT" "${SQL_FILE}"; then
        echo "  [E034] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E034] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E034] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

_E035_basic_sockets_apply() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/20-sockets.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/20-sockets.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E035] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E035] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E035] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

_E035_basic_sockets_revert() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/20-sockets.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/20-sockets.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E035_REVERT" "${SQL_FILE}"; then
        echo "  [E035] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E035] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E035] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}


patch_E033_basic_gem_supply_and_sockets() {
    _E033_basic_gem_supply_apply || return 1
    _E034_basic_titan_jewelers_apply || return 1
    _E035_basic_sockets_apply || return 1
}
unpatch_E033_basic_gem_supply_and_sockets() {
    _E035_basic_sockets_revert || return 1
    _E034_basic_titan_jewelers_revert || return 1
    _E033_basic_gem_supply_revert || return 1
}
