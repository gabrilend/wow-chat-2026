#!/usr/bin/env bash
# E013-beta-quest-spells-to-trainers.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E013_beta_quest_spells_to_trainers
# Adds quest-learned class abilities to the class trainers' lists (issue
# 701, formerly 140). Beta has no quest NPCs, so abilities normally taught
# via quests are taught by trainers instead. Source and undo:
# sql/beta/db_world.src/13-quest-spells-to-trainers.{apply,revert}.sql,
# on the current trainer tables since 2026-10-17. The old undo deleted
# every npc_trainer row numbered 200001-200020, which were mostly the
# game's own reference lists (about 2,000 rows), not this step's.
patch_E013_beta_quest_spells_to_trainers() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/13-quest-spells-to-trainers.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/13-quest-spells-to-trainers.apply.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E013_APPLY" "${SQL_FILE}"; then
        echo "  [E013] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E013] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E013] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E013_beta_quest_spells_to_trainers() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/13-quest-spells-to-trainers.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/13-quest-spells-to-trainers.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E013_REVERT" "${SQL_FILE}"; then
        echo "  [E013] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E013] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E013] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
