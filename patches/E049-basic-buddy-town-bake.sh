#!/usr/bin/env bash

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
