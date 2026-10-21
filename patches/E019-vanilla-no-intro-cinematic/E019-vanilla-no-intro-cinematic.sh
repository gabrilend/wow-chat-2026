#!/usr/bin/env bash
# ==== header: 8 lines, footer: 3 lines ====
# id:         E019
# profiles:   basic vanilla
# priority:   2490
# kind:       sql
# about:      Installs a BEFORE INSERT trigger on acore_characters_vanilla.characters
# carries:    01-no-intro-cinematic.apply.sql
# ==== end of header ====
# E019-vanilla-no-intro-cinematic.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# Its SQL is carried beside this file (issue 189e), for both profiles that
# take it (basic and vanilla); until then basic read it from vanilla's folders.
E019_DIR="${BASH_SOURCE[0]%/*}"

# -- {{{ patch_E019_vanilla_no_intro_cinematic
# Installs a BEFORE INSERT trigger on acore_characters_vanilla.characters
# that sets cinematic = 1 on every new row. AC's first-login flow plays
# the race intro only when cinematic = 0; pre-flipping it to 1 makes
# first login skip straight to gameplay.
#
# Vanilla-scoped — the trigger lives in acore_characters_vanilla only.
# Release/beta read a different characters DB so their race intros stay
# on for anyone who wants them. Requires log_bin_trust_function_creators
# = 1 in mysql/conf/my.cnf so ritz can install the trigger without
# SUPER (project-local MySQL is set that way).
patch_E019_vanilla_no_intro_cinematic() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/01-no-intro-cinematic.sql"
    local SRC_FILE="${E019_DIR}/01-no-intro-cinematic.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E019] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register first, on every run: INSERT IGNORE makes it a no-op once the
    # row exists, and a run that found MySQL down must not be the last word
    # (the early return below would otherwise skip registration forever).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    # Idempotence by content comparison, not by marker: a marker check left
    # the active file stale whenever the source was edited (new flavor lines,
    # retuned values), so an existing install never picked the edit up.
    # Same shape as E018. On a change AC's UpdateFetcher sees a new hash and
    # re-runs the file, which is written to be re-applicable.
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
# -- }}}
# ==== footer of E019 ====
# lines:      76
# ==== end of footer ====
