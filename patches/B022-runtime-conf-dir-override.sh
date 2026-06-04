#!/usr/bin/env bash
# B022-runtime-conf-dir-override.sh
# Adds a runtime --conf-dir / -C CLI argument to authserver, worldserver,
# and dbimport that overrides the cmake-baked _CONF_DIR for module config
# loading.
#
# Why this exists:
#   Module config files (etc/modules/*.conf) are loaded relative to a
#   compile-time string literal (_CONF_DIR) baked into the binary by
#   cmake. The -c worldserver flag overrides only the *main* config file
#   — module configs continue to come from _CONF_DIR. That means shadow
#   validation reads the release tree's module configs even when run
#   from the shadow tree with the shadow worldserver.conf passed via -c.
#   See issues/137-shadow-conf-path-baked-into-binary.md for the full
#   account of how this was discovered.
#
# Marker-comment convention:
#   Every multi-line insertion is wrapped in unique BEGIN/END comment
#   markers (// {{{ B022-conf-dir-override ... // }}} B022-conf-dir-override).
#   The unpatch deletes the marker range — one sed per file regardless
#   of how many insertions are inside. Because the markers contain the
#   patch ID, they cannot false-match upstream code or another B-patch's
#   insertions. This is the established defense against the kind of
#   round-trip drift documented in issues/126's "1:1 Sed Targeting Rule"
#   section.

# {{{ patch_B022_runtime_conf_dir_override
patch_B022_runtime_conf_dir_override() {
    local SRC="${AC_CODE_DIR}"
    local CFG_H="${SRC}/src/common/Configuration/Config.h"
    local CFG_C="${SRC}/src/common/Configuration/Config.cpp"
    local WS_M="${SRC}/src/server/apps/worldserver/Main.cpp"
    local AS_M="${SRC}/src/server/apps/authserver/Main.cpp"
    local DBI_M="${SRC}/src/tools/dbimport/Main.cpp"

    # 1. Config.h — declare the public setter. Anchored on the unique
    #    GetConfigPath() declaration that already sits in the public
    #    section; the new declaration is inserted right below it.
    if [[ -f "${CFG_H}" ]]; then
        sed -i '/std::string const GetConfigPath();/a\
    // {{{ B022-conf-dir-override\
    void SetConfigPathOverride(std::string const\& path);\
    // }}} B022-conf-dir-override' "${CFG_H}"
    fi

    # 2. Config.cpp anonymous namespace — declare the storage. Anchored
    #    on the unique `_configLock` declaration which already lives in
    #    the same anonymous namespace as all other file-scope state.
    if [[ -f "${CFG_C}" ]]; then
        sed -i '/std::mutex _configLock;/a\
    // {{{ B022-conf-dir-override\
    std::string _configPathOverride;\
    // }}} B022-conf-dir-override' "${CFG_C}"

        # 3. Config.cpp::GetConfigPath — check the override before
        #    falling back to the baked _CONF_DIR. Anchored on the exact
        #    return line; `\%...%` is used as the address delimiter so
        #    the embedded `/` in `"/";` does not need escaping.
        sed -i '\%return std::string(_CONF_DIR) + "/";%i\
    // {{{ B022-conf-dir-override\
    if (!_configPathOverride.empty())\
        return _configPathOverride + "/";\
    // }}} B022-conf-dir-override' "${CFG_C}"

        # 4. Config.cpp — define ConfigMgr::SetConfigPathOverride().
        #    Inserted immediately above the existing Configure() impl,
        #    which is unique to this file.
        sed -i '/void ConfigMgr::Configure(std::string const& initFileName, std::vector<std::string> args/i\
// {{{ B022-conf-dir-override\
void ConfigMgr::SetConfigPathOverride(std::string const\& path)\
{\
    std::lock_guard<std::mutex> lock(_configLock);\
    _configPathOverride = path;\
}\
// }}} B022-conf-dir-override' "${CFG_C}"
    fi

    # 5-6. worldserver Main.cpp — add the --conf-dir option and wire it
    #      into ConfigMgr before Configure() is called.
    if [[ -f "${WS_M}" ]]; then
        sed -i '/"override config severity policy/a\
    // {{{ B022-conf-dir-override\
    all.add_options()\
        ("conf-dir,C", value<std::string>()->default_value(""), "override module config directory (defaults to baked _CONF_DIR)");\
    // }}} B022-conf-dir-override' "${WS_M}"

        sed -i '/sConfigMgr->Configure(configFile.generic_string(), {argv, argv + argc}, CONFIG_FILE_LIST);/i\
    // {{{ B022-conf-dir-override\
    if (vm.count("conf-dir") \&\& !vm["conf-dir"].as<std::string>().empty())\
        sConfigMgr->SetConfigPathOverride(vm["conf-dir"].as<std::string>());\
    // }}} B022-conf-dir-override' "${WS_M}"
    fi

    # 7-8. authserver Main.cpp — same pattern as worldserver. The
    #      Configure() signature differs slightly (std::vector instead
    #      of brace-init), so the anchor for the wiring sed is distinct.
    if [[ -f "${AS_M}" ]]; then
        sed -i '/"override config severity policy/a\
    // {{{ B022-conf-dir-override\
    all.add_options()\
        ("conf-dir,C", value<std::string>()->default_value(""), "override module config directory (defaults to baked _CONF_DIR)");\
    // }}} B022-conf-dir-override' "${AS_M}"

        sed -i '/sConfigMgr->Configure(configFile.generic_string(), std::vector<std::string>(argv, argv + argc));/i\
    // {{{ B022-conf-dir-override\
    if (vm.count("conf-dir") \&\& !vm["conf-dir"].as<std::string>().empty())\
        sConfigMgr->SetConfigPathOverride(vm["conf-dir"].as<std::string>());\
    // }}} B022-conf-dir-override' "${AS_M}"
    fi

    # 9-10. dbimport Main.cpp — same shape as authserver. dbimport does
    #       not load module configs in practice, but symmetry across all
    #       three apps lets future module-config-reading tools just
    #       work without another patch round.
    if [[ -f "${DBI_M}" ]]; then
        sed -i '/"override config severity policy/a\
    // {{{ B022-conf-dir-override\
    all.add_options()\
        ("conf-dir,C", value<std::string>()->default_value(""), "override module config directory (defaults to baked _CONF_DIR)");\
    // }}} B022-conf-dir-override' "${DBI_M}"

        sed -i '/sConfigMgr->Configure(configFile.generic_string(), std::vector<std::string>(argv, argv + argc));/i\
    // {{{ B022-conf-dir-override\
    if (vm.count("conf-dir") \&\& !vm["conf-dir"].as<std::string>().empty())\
        sConfigMgr->SetConfigPathOverride(vm["conf-dir"].as<std::string>());\
    // }}} B022-conf-dir-override' "${DBI_M}"
    fi
}
# }}}

# {{{ unpatch_B022_runtime_conf_dir_override
unpatch_B022_runtime_conf_dir_override() {
    local SRC="${AC_CODE_DIR}"
    # One sed per file deletes every B022 marker-bounded block.
    # The markers contain the patch ID, so the range cannot
    # accidentally match upstream code or any other patch's insertions.
    local f
    for f in \
        "${SRC}/src/common/Configuration/Config.h" \
        "${SRC}/src/common/Configuration/Config.cpp" \
        "${SRC}/src/server/apps/worldserver/Main.cpp" \
        "${SRC}/src/server/apps/authserver/Main.cpp" \
        "${SRC}/src/tools/dbimport/Main.cpp" \
    ; do
        if [[ -f "${f}" ]]; then
            sed -i '/\/\/ {{{ B022-conf-dir-override/,/\/\/ }}} B022-conf-dir-override/d' "${f}"
        fi
    done
}
# }}}
