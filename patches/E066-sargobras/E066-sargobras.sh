#!/usr/bin/env bash
# ==== header: 8 lines, footer: 3 lines ====
# id:         E066
# profiles:   basic
# priority:   1960
# kind:       install
# about:      Sargobras, his own patch: his script and his own copies of what it loads, placed per profile
# carries:    sargobras.lua helpers
# ==== end of header ====
# E066 - Sargobras, his own patch
# E066-sargobras.sh - one install step, a patch that is a directory (issue
# 189e), loaded by patches/E-patches.sh. Its helpers (place_carried,
# remove_carried) are in patches/E-helpers.sh, loaded first.
#
# For a general audience: Sargobras, who stands at the starting valleys
# and hands out buddies (issue 617b), lived in basic's own Lua folder,
# so a profile wanting him had to take all of basic's scripts. The owner,
# 2026-10-20: "he is his own patch. he deserves all the space to do with
# as he chooses. for he is the real guild master." His script and his own
# copies of everything it loads now live in this directory, in git, and
# this step copies them into the install of each profile that takes him.
#
# What it carries (each beside this file):
#   sargobras.lua   his script
#   helpers/        what he loads: his jokes (only his), and his own copies
#                   of the race and class data, the buddy talent data and
#                   spender, the buddy choice, the starting valleys and the
#                   valley deck, which basic's other scripts also load from
#                   basic's folder. Each is named sargobras-<name>: the Lua
#                   engine loads every file under lua_scripts/ and refuses
#                   two of one name, so the prefix keeps his copies from
#                   clashing with basic's. In plain sight on purpose (the
#                   owner: "we shouldn't hide source-code from the
#                   developer"). A change to one of the shared helpers is
#                   made in both copies (the generators write both).
#
# Where they go: installed-files-<profile>/bin/lua_scripts/sargobras/, a
# real folder (custom/ beside it is a link into src/lua-<profile>/ in git,
# so a copy placed there would land in git). Undone, the folder goes.

E066_DIR="${BASH_SOURCE[0]%/*}"

# -- {{{ patch_E066_sargobras
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
# -- }}}
# ==== footer of E066 ====
# lines:      63
# ==== end of footer ====
