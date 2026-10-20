#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E059
# profiles:   beta
# priority:   1890
# kind:       install
# about:      The narrators' books (issue 909): every book on the shelf
# ==== end of header ====
# E059-beta-narrator-library.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E059_beta_narrator_library
# The narrators' books (issue 909): every book on the shelf
# (src/lua-beta/data/gutenberg-books.lua) fetched from Project Gutenberg,
# checked to be the book the shelf names, and cut into sentences under
# src/lua-beta/data/texts/, which the narrator library reads in game. Made
# at install time rather than kept in git (the owner, 2026-10-18: "made at
# install time, so we can always include new additions"): a book added to
# the shelf arrives on the next install. Downloads are kept in the RAM
# scratch folder, so a reinstall re-cuts without fetching again while the
# machine stays up. A book that can't be fetched or fails its title check
# stops the step (an error, not a partial library said to be whole); the
# scraper names each book it wrote and each it could not. The revert
# removes the cut books; the shelf and the tools stay.
patch_E059_beta_narrator_library() {
    local SCRAPER="${DIR}/scripts/gutenberg-scraper"
    local TEXTS="${DIR}/src/lua-beta/data/texts"

    [[ ! -x "${SCRAPER}" ]] && { echo "  [E059] Scraper missing or not runnable: ${SCRAPER}"; return 1; }
    command -v luajit > /dev/null || { echo "  [E059] luajit not found; the scraper is a LuaJIT script"; return 1; }

    echo "  [E059] Building the narrators' library into ${TEXTS}"
    if ! "${SCRAPER}" "${DIR}"; then
        echo "  [E059] Some books were not written (listed above); the library is incomplete"
        return 1
    fi
}

unpatch_E059_beta_narrator_library() {
    local TEXTS="${DIR}/src/lua-beta/data/texts"

    if [[ ! -d "${TEXTS}" ]]; then
        echo "  [E059] No narrators' library to remove"
        return 0
    fi
    echo "  [E059] Removing the cut books in ${TEXTS} (the shelf and the scraper stay)"
    rm -rf "${TEXTS}"
}
# -- }}}
# ==== footer of E059 ====
# lines:      54
# ==== end of footer ====
