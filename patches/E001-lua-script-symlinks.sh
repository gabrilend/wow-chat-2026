#!/usr/bin/env bash
# E001-lua-script-symlinks.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E001_lua_script_symlinks
# Create symlinks from install dir to the profile-specific Lua source
# directory. Each profile owns its own Lua corpus:
#   src/lua-vanilla/ — minimal vanilla scripts (148k starter-equip hook etc.)
#   src/lua-beta/    — wow-chat design corpus (ambush, travel, custom classes,
#                      the disabled-prefixed experiments). Was formerly just
#                      src/lua/ before the 2026-06-02 per-profile rename.
#   src/lua-alpha/   — placeholder for alpha-profile (mod-eluna) scripts.
# Symlink target resolves from ${PROFILE} at apply time, so each
# installed-files-${PROFILE}/bin/lua_scripts/custom points at the
# correct per-profile source.
#
# Idempotent: every call tears down whatever previously occupied the
# target paths and re-creates them fresh. This lets the patch run on
# every compile and handle three distinct squatters:
#   1. A symlink left by a prior E001 apply (most common — profile
#      rotation or repeat builds).
#   2. A broken symlink pointing at a no-longer-existing source
#      (e.g. the 2026-06-02 src/lua → src/lua-${profile} rename left
#      May-21 links pointing at the renamed-away src/lua/extensions).
#      [[ -L ... ]] matches even broken links, so they're cleaned.
#   3. A real directory unpacked at lua_scripts/extensions/ by mod-ale's
#      upstream install rule
#        install(DIRECTORY .../LuaEngine/extensions DESTINATION lua_scripts/)
#      in source-beta/modules/CMakeLists.txt. cmake's
#      file(INSTALL TYPE DIRECTORY) refuses to clobber a non-directory
#      at its destination, so squatter (1)/(2) must be cleared BEFORE
#      cmake --install; squatter (3) must be cleared AFTER, so the
#      project's extensions/ superset (incl. GetFreeBagSlots.ext,
#      .StackTracePlus.disabled, hidden by its dot) overrides mod-ale's bundled set.
#
# Parallelizable: Yes (unique directory)
# Uses TARGET_INSTALL_DIR (defaults to INSTALL_DIR, can be set to INSTALL_DIR_SHADOW)
patch_E001_lua_script_symlinks() {
    local TARGET="${TARGET_INSTALL_DIR:-${INSTALL_DIR}}"
    local LUA_SRC="${DIR}/src/lua-${PROFILE}"
    # A missing per-profile Lua directory means the profile was never set
    # up (or its name is misspelled). This used to warn and create an empty
    # directory, which booted a worldserver with no custom scripts and no
    # visible failure. Now it stops, and says what was and was not done.
    if [[ ! -d "${LUA_SRC}" ]]; then
        echo "  [E001] ERROR: Lua source directory missing: ${LUA_SRC}"
        echo "         profile='${PROFILE}'; nothing was linked into ${TARGET}/bin/lua_scripts/"
        echo "         to debug: does src/lua-${PROFILE}/ exist in git? (every profile"
        echo "         owns one, even if it holds only a README); is .profile spelled right?"
        return 1
    fi
    mkdir -p "${TARGET}/bin/lua_scripts"

    # custom/ is only ever a symlink (cmake never installs there). Tear
    # down any prior link — well-formed or broken — and recreate.
    [[ -L "${TARGET}/bin/lua_scripts/custom" ]] && rm "${TARGET}/bin/lua_scripts/custom"
    ln -sfn "${LUA_SRC}" "${TARGET}/bin/lua_scripts/custom"

    # extensions/ needs heavier handling because cmake --install can
    # leave a real directory here (see header comment, squatter #3).
    #
    # Branch (a): this profile ships its own extensions/ source. Blow
    # away whatever's at the path (symlink OR real dir) and override
    # with a project symlink.
    #
    # Branch (b): this profile has no extensions/ source. Only clear a
    # stale symlink (leftover from a prior profile that had one). Leave
    # a cmake-installed real directory alone so mod-ale's bundled
    # StackTracePlus / _Misc / ObjectVariables stay loadable.
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

# Tear down whatever E001 may have created. Only removes symlinks (the
# project's contribution) — never touches a real directory at the
# extensions/ path, because that was placed by cmake --install and
# belongs to mod-ale, not to E001. [[ -L ... ]] matches broken symlinks
# too, so the May-21-era links pointing at the renamed-away src/lua/
# get cleaned on the first call.
unpatch_E001_lua_script_symlinks() {
    local TARGET="${TARGET_INSTALL_DIR:-${INSTALL_DIR}}"
    [[ -L "${TARGET}/bin/lua_scripts/custom" ]] && rm "${TARGET}/bin/lua_scripts/custom"
    [[ -L "${TARGET}/bin/lua_scripts/extensions" ]] && rm "${TARGET}/bin/lua_scripts/extensions"
    echo "  [E001] Removed Lua script symlinks"
}
# -- }}}
