#!/usr/bin/env bash
# E005-dk-levelstats.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E005_dk_levelstats
# Apply Death Knight level 1-20 stats to the beta-profile DB (issue
# 206). Required before worldserver first start so DK characters
# can be created at level 1 with sensible stats.
#
# Single-idiom (UpdateFetcher). Apply cp's the source file into
# sql/beta/db_world/01-dk-levelstats.sql; unpatch overwrites with a
# revert heredoc; AC's UpdateFetcher hashes and runs whichever is
# current on next worldserver boot.
#
# Shared-DB note: beta+release share acore_world. Once the beta
# install registers sql/beta/db_world/, the release worldserver also
# scans it. That is a DB-sharing consequence; address by splitting
# into acore_world_beta if beta-only isolation is required.
patch_E005_dk_levelstats() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/01-dk-levelstats.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/01-dk-levelstats.apply.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E005_APPLY" "${SQL_FILE}"; then
        echo "  [E005] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E005] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E005] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E005_dk_levelstats() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/01-dk-levelstats.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E005_REVERT" "${SQL_FILE}"; then
        echo "  [E005] Active file already holds revert-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E005] Writing revert-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E005_REVERT beta-dk-levelstats
-- Revert-form: drop the DK level 1..20 rows from player_levelstats.
-- Table itself is preserved (release shares this DB).
DELETE FROM `player_levelstats` WHERE `class` = 6 AND `level` BETWEEN 1 AND 20;
SQL
}
# -- }}}
