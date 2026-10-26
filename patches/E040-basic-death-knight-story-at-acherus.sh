#!/usr/bin/env bash

_E040_basic_death_knight_sargobras_apply() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/25-death-knight-sargobras.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/25-death-knight-sargobras.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E040] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E040] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E040] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

_E040_basic_death_knight_sargobras_revert() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/25-death-knight-sargobras.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/25-death-knight-sargobras.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E040_REVERT" "${SQL_FILE}"; then
        echo "  [E040] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E040] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E040] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

_E041_basic_death_knight_souls_apply() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/03-death-knight-souls.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_characters.src/03-death-knight-souls.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E041] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E041] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E041] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

_E041_basic_death_knight_souls_revert() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/03-death-knight-souls.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_characters.src/03-death-knight-souls.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E041_REVERT" "${SQL_FILE}"; then
        echo "  [E041] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E041] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    echo "  [E041] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

_E051_basic_acherus_choice_vendors_apply() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/32-acherus-choice-vendors.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/32-acherus-choice-vendors.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E051] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E051] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E051] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

_E051_basic_acherus_choice_vendors_revert() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/32-acherus-choice-vendors.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/32-acherus-choice-vendors.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E051_REVERT" "${SQL_FILE}"; then
        echo "  [E051] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E051] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E051] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}


patch_E040_basic_death_knight_story_at_acherus() {
    _E040_basic_death_knight_sargobras_apply || return 1
    _E041_basic_death_knight_souls_apply || return 1
    _E051_basic_acherus_choice_vendors_apply || return 1
}
unpatch_E040_basic_death_knight_story_at_acherus() {
    _E051_basic_acherus_choice_vendors_revert || return 1
    _E041_basic_death_knight_souls_revert || return 1
    _E040_basic_death_knight_sargobras_revert || return 1
}
