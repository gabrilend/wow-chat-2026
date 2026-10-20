#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E049
# profiles:   basic
# priority:   1790
# kind:       install
# about:      Every town's exploring grid baked ahead of time (issue 617o3), so buddies
# ==== end of header ====
# E049-basic-buddy-town-bake.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E049_basic_buddy_town_bake
# Every town's exploring grid baked ahead of time (issue 617o3), so buddies
# cross a town by its distance maps from their first visit: runs
# scripts/bake-buddy-towns, which writes <DataDir>/buddy-towns/*.btown.
# It reads the area pieces from the world database (install step E044's
# table), which a fresh install only fills at the server's first start; with
# the table not there yet the step is skipped, and says so, and the bake is
# run by hand after that first start. Re-baking is harmless (the files are
# rewritten), so the step runs every install.
patch_E049_basic_buddy_town_bake() {
    local WORLD_DB
    WORLD_DB="$(_profile_db_name acore_world)"
    local PIECES
    PIECES="$("${DIR}/mysql/installed-files/bin/mysql" -h127.0.0.1 -P3307 -uritz -pmenardi -N --batch "${WORLD_DB}" \
        -e "SELECT COUNT(*) FROM buddy_area_centre" 2>&1 | grep -v "Using a password" | tail -1)"
    if ! [[ "${PIECES}" =~ ^[0-9]+$ ]] || [[ "${PIECES}" -eq 0 ]]; then
        echo "  [E049] the database answered: ${PIECES}"
        echo "  [E049] SKIPPED: ${WORLD_DB}.buddy_area_centre is empty or missing (E044's table is loaded at the server's"
        echo "         first start); run scripts/bake-buddy-towns after it. Until then towns are measured live."
        return 0
    fi
    echo "  [E049] Baking the towns' exploring grids (scripts/bake-buddy-towns)"
    "${DIR}/scripts/bake-buddy-towns" "${DIR}" || { echo "  [E049] ERROR: the bake failed (its output is above)"; return 1; }
}

unpatch_E049_basic_buddy_town_bake() {
    local DATA
    DATA="$(sed -n 's|^DataDir[[:space:]]*=[[:space:]]*"\{0,1\}\([^"]*\)"\{0,1\}.*|\1|p' "${DIR}/installed-files-${PROFILE}/etc/worldserver.conf" | tail -1)"
    [[ -n "${DATA}" && -d "${DATA}/buddy-towns" ]] || return 0
    echo "  [E049] Removing the baked towns (${DATA}/buddy-towns); the server measures towns live again"
    rm -rf "${DATA}/buddy-towns"
}
# -- }}}
# ==== footer of E049 ====
# lines:      49
# ==== end of footer ====
