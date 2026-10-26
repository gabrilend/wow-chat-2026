#!/usr/bin/env bash

E066_DIR="${BASH_SOURCE[0]%/*}"

patch_E066_sargobras() {
    local TARGET="${TARGET_INSTALL_DIR:-${INSTALL_DIR}}"
    local TO="${TARGET}/bin/lua_scripts/sargobras"
    [[ -d "${TARGET}/bin/lua_scripts" ]] || { echo "  [E066] ERROR: ${TARGET}/bin/lua_scripts/ does not exist (the compile's install makes it)"; return 1; }
    rm -rf "${TO:?}"
    mkdir -p "${TO}"
    place_carried "${E066_DIR}/sargobras.lua" "${TO}/sargobras.lua" || return 1
    place_carried "${E066_DIR}/helpers"       "${TO}/helpers"       || return 1
    echo "  [E066] Sargobras placed in ${TO#${DIR}/}/ ($(find "${TO}" -type f | wc -l) files)"
}

unpatch_E066_sargobras() {
    local TARGET="${TARGET_INSTALL_DIR:-${INSTALL_DIR}}"
    remove_carried "${TARGET}/bin/lua_scripts/sargobras"
    echo "  [E066] Sargobras removed from ${TARGET#${DIR}/}/bin/lua_scripts/"
}
