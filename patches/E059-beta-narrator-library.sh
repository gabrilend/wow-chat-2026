#!/usr/bin/env bash

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
