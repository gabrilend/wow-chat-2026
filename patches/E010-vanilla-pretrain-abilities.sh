#!/usr/bin/env bash

patch_E010_vanilla_pretrain_abilities() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/04-pretrain-abilities.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/04-pretrain-abilities.apply.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E010_APPLY" "${SQL_FILE}"; then
        echo "  [E010] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E010] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E010] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E010_vanilla_pretrain_abilities() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/04-pretrain-abilities.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E010_REVERT" "${SQL_FILE}"; then
        echo "  [E010] Active file already holds revert-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E010] Writing revert-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E010_REVERT vanilla-pretrain-abilities
-- Revert-form: drop every pretrain row tagged 'vanilla-148j-'.
DELETE FROM `playercreateinfo_spell_custom` WHERE `Note` LIKE 'vanilla-148j-%';
SQL
}
