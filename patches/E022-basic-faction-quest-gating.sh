#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E022
# profiles:   basic
# priority:   2520
# kind:       sql
# about:      Open every quest to its whole faction on the basic profile (issue 155e):
# ==== end of header ====
# E022-basic-faction-quest-gating.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E022_basic_faction_quest_gating
# Open every quest to its whole faction on the basic profile (issue 155e):
# a quest restricted to some races of one faction becomes available to all
# of that faction's races. Needed because basic characters are born in any
# of their faction's starting valleys (155d), not their race's own.
#
# Same cp-apply / cp-revert idiom as E020: the apply-form source at
# sql/basic/db_world.src/08-faction-quest-gating.apply.sql is copied into
# the AC-watched active dir. The apply form saves each changed row's
# original mask in a backup table first; the revert form restores from it.
patch_E022_basic_faction_quest_gating() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/08-faction-quest-gating.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/08-faction-quest-gating.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E022] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register first, on every run: INSERT IGNORE makes it a no-op once the
    # row exists, and a run that found MySQL down must not be the last word
    # (the early return below would otherwise skip registration forever).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    # Idempotence by content comparison, not by marker: a marker check left
    # the active file stale whenever the source was edited (new flavor lines,
    # retuned values), so an existing install never picked the edit up.
    # Same shape as E018. On a change AC's UpdateFetcher sees a new hash and
    # re-runs the file, which is written to be re-applicable.
    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E022] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E022] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E022_basic_faction_quest_gating() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/08-faction-quest-gating.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/08-faction-quest-gating.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E022_REVERT" "${SQL_FILE}"; then
        echo "  [E022] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E022] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E022] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E022 ====
# lines:      68
# ==== end of footer ====
