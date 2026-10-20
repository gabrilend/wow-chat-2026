#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E023
# profiles:   basic
# priority:   1530
# kind:       install
# about:      Create and seed the rotation-state table the basic profile's
# ==== end of header ====
# E023-basic-starting-valley-rotation.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E023_basic_starting_valley_rotation
# Create and seed the rotation-state table the basic profile's
# character-creation patch (B028) reads and advances (issue 155d). Lives in
# the characters database because it is per-realm runtime state, not world
# content. Same cp-apply / cp-revert idiom as E022.
patch_E023_basic_starting_valley_rotation() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/02-starting-valley-rotation.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_characters.src/02-starting-valley-rotation.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E023] Apply source missing: ${SRC_FILE}"; return 1; }

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
        echo "  [E023] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E023] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E023_basic_starting_valley_rotation() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/02-starting-valley-rotation.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_characters.src/02-starting-valley-rotation.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E023_REVERT" "${SQL_FILE}"; then
        echo "  [E023] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E023] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    echo "  [E023] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E023 ====
# lines:      63
# ==== end of footer ====
