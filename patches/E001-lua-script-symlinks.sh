#!/usr/bin/env bash


_e001_lua_src() {
    local profile="$1"
    case "${profile}" in
        release) echo "${DIR}/src/lua-beta" ;;          # release: beta's corpus
        *)       echo "${DIR}/src/lua-${profile}" ;;    # every other profile: its own
    esac
}

patch_E001_lua_script_symlinks() {
    local TARGET="${TARGET_INSTALL_DIR:-${INSTALL_DIR}}"
    local LUA_SRC
    LUA_SRC="$(_e001_lua_src "${PROFILE}")"
    if [[ ! -d "${LUA_SRC}" ]]; then
        echo "  [E001] ERROR: Lua source directory missing: ${LUA_SRC}"
        echo "         profile='${PROFILE}'; nothing was linked into ${TARGET}/bin/lua_scripts/"
        echo "         to debug: does ${LUA_SRC#${DIR}/}/ exist in git? (every profile owns"
        echo "         one, even if it holds only a README, or runs another's: _e001_lua_src);"
        echo "         is .profile spelled right?"
        return 1
    fi
    mkdir -p "${TARGET}/bin/lua_scripts"

    [[ -L "${TARGET}/bin/lua_scripts/custom" ]] && rm "${TARGET}/bin/lua_scripts/custom"
    ln -sfn "${LUA_SRC}" "${TARGET}/bin/lua_scripts/custom"

    if [[ -d "${LUA_SRC}/extensions" ]]; then
        if [[ -L "${TARGET}/bin/lua_scripts/extensions" ]]; then
            rm "${TARGET}/bin/lua_scripts/extensions"
        elif [[ -d "${TARGET}/bin/lua_scripts/extensions" ]]; then
            rm -rf "${TARGET}/bin/lua_scripts/extensions"
        fi
        ln -sfn "${LUA_SRC}/extensions" "${TARGET}/bin/lua_scripts/extensions"
    else
        [[ -L "${TARGET}/bin/lua_scripts/extensions" ]] && rm "${TARGET}/bin/lua_scripts/extensions"
    fi

    echo "  [E001] Lua script symlinks (profile=${PROFILE}, src=${LUA_SRC#${DIR}/})"
}

unpatch_E001_lua_script_symlinks() {
    local TARGET="${TARGET_INSTALL_DIR:-${INSTALL_DIR}}"
    [[ -L "${TARGET}/bin/lua_scripts/custom" ]] && rm "${TARGET}/bin/lua_scripts/custom"
    [[ -L "${TARGET}/bin/lua_scripts/extensions" ]] && rm "${TARGET}/bin/lua_scripts/extensions"
    echo "  [E001] Removed Lua script symlinks"
}
