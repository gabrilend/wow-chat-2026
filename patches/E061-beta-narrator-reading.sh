#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E061
# profiles:   beta
# priority:   1910
# kind:       install
# about:      Where each narrator is in its book (issue 910a): one row per narrator bot,
# ==== end of header ====
# E061-beta-narrator-reading.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E061_beta_narrator_reading
# Where each narrator is in its book (issue 910a): one row per narrator bot,
# its book and how many sentences in, so a narrator finishes its books
# across logouts and restarts. Characters database, per-realm runtime state
# (as E060). The revert drops the table; the narrators start over. The
# folder is registered with the updater here too (E060 does the same on the
# beta branch; registering twice is harmless). Same cp-apply / cp-revert
# idiom as E060. Added 2026-10-18.
patch_E061_beta_narrator_reading() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/02-narrator-reading.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_characters.src/02-narrator-reading.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E061] Apply source missing: ${SRC_FILE}"; return 1; }
    mkdir -p "${DIR}/sql/${PROFILE}/db_characters"

    # Register on every run (see E023 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E061_APPLY" "${SQL_FILE}"; then
        echo "  [E061] Active file already holds apply-form content"
        return 0
    fi

    echo "  [E061] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E061_beta_narrator_reading() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/02-narrator-reading.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_characters.src/02-narrator-reading.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E061_REVERT" "${SQL_FILE}"; then
        echo "  [E061] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E061] Revert source missing: ${SRC_FILE}"; return 1; }
    mkdir -p "${DIR}/sql/${PROFILE}/db_characters"

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    echo "  [E061] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E061 ====
# lines:      61
# ==== end of footer ====
