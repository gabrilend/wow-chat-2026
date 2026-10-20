#!/usr/bin/env bash
# E031-basic-outland-gear-scaling.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E031_basic_outland_gear_scaling
# Outland gear scaling (issue 155k, with 155f's dungeon ladder): Outland's
# world and dungeon gear rescaled onto the level-60 ladder (stats by budget,
# the Burning Crusade rating discount, Kael'thas's epics to item level 100),
# wearable at 60, world blues bind on pickup. Reads E024's template list, so
# it comes after E024. Same cp-apply / cp-revert idiom as E022.
patch_E031_basic_outland_gear_scaling() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/16-outland-gear-scaling.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/16-outland-gear-scaling.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E031] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register on every run (see E022 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E031] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E031] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E031_basic_outland_gear_scaling() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/16-outland-gear-scaling.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/16-outland-gear-scaling.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E031_REVERT" "${SQL_FILE}"; then
        echo "  [E031] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E031] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E031] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
