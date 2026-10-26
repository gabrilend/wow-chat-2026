#!/usr/bin/env bash

E019_DIR="${BASH_SOURCE[0]%/*}"

patch_E019_vanilla_no_intro_cinematic() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/01-no-intro-cinematic.sql"
    local SRC_FILE="${E019_DIR}/01-no-intro-cinematic.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E019] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E019] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E019] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E019_vanilla_no_intro_cinematic() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/01-no-intro-cinematic.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E019_REVERT" "${SQL_FILE}"; then
        echo "  [E019] Active file already holds revert-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    echo "  [E019] Writing revert-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E019_REVERT vanilla-no-intro-cinematic
-- Revert-form: drop the trigger so cinematic defaults back to 0 and
-- race intros play on first login as upstream ships.
DROP TRIGGER IF EXISTS `tr_no_intro_cinematic`;
SQL
}
