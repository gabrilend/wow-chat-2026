#!/usr/bin/env bash
# E051-basic-acherus-choice-vendors.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E051_basic_acherus_choice_vendors
# Acherus sells the death knight story's reward choices (issue 718): Lady
# Alistra the three cloaks, Instructor Razuvious the two two-handers, 1 gold
# each, worth nothing to any other vendor. For death knights who skipped the
# story and want the item the server didn't pick. World database. Same
# cp-apply / cp-revert idiom as E050.
patch_E051_basic_acherus_choice_vendors() {
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

unpatch_E051_basic_acherus_choice_vendors() {
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
# -- }}}
