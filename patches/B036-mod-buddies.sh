#!/usr/bin/env bash
# B036 - Build the project's buddy module (mod-buddies) into the worldserver
# Issue 617a1 (buddy roster); the home of every buddy part written in C++.
#
# For a general audience: the server compiles every folder it finds under
# its own modules/ directory. The buddy module is written in the project
# (modules/mod-buddies/), so this patch copies it in before a build and the
# revert deletes the copy, leaving the server tree exactly as upstream has
# it. Nothing else in the server changes.
#
# Mechanics: a copy, not a link (B008 links; whether the build's folder scan
# follows a linked folder was never tested, since B008's module is absent).
# The copy carries a marker file naming this patch; the revert removes the
# folder only when that marker is there, so it can never delete a folder
# someone put there by other means. The copy is refreshed on every apply, so
# edits in the project reach the next build.
# Parallelizable: Yes (unique folder)

# {{{ patch_B036_mod_buddies
patch_B036_mod_buddies() {
    local SRC="${DIR}/modules/mod-buddies"
    local DST="${AC_CODE_DIR}/modules/mod-buddies"
    local MARK="${DST}/.installed-by-B036"

    if [[ ! -d "${SRC}/src" ]]; then
        echo "  [B036] ERROR: module folder missing: ${SRC}/src"
        echo "         the buddy module (issue 617a1) is not in the project, so it"
        echo "         cannot be built into ${AC_CODE_DIR}/modules/."
        echo "         to debug: was modules/mod-buddies committed (git log -- modules/mod-buddies)?"
        return 1
    fi
    if [[ -e "${DST}" && ! -f "${MARK}" ]]; then
        echo "  [B036] ERROR: ${DST} exists and was not put there by B036"
        echo "         (no ${MARK}); refusing to overwrite it."
        echo "         to debug: is an upstream module of the same name cloned there?"
        return 1
    fi

    echo "  [B036] mod-buddies: copying the project's buddy module into the build"
    rm -rf "${DST}"
    cp -r "${SRC}" "${DST}"
    echo "B036: copied from ${SRC}; removed by the revert" > "${MARK}"
}
# }}}

# {{{ unpatch_B036_mod_buddies
unpatch_B036_mod_buddies() {
    local DST="${AC_CODE_DIR}/modules/mod-buddies"
    # Only a folder carrying B036's marker is removed.
    if [[ -f "${DST}/.installed-by-B036" ]]; then
        rm -rf "${DST}"
    fi
    return 0
}
# }}}
