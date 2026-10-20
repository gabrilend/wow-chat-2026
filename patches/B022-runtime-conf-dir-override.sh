#!/usr/bin/env bash

patch_B022_runtime_conf_dir_override() {
    local SRC="${AC_CODE_DIR}"
    local CFG_H="${SRC}/src/common/Configuration/Config.h"
    local CFG_C="${SRC}/src/common/Configuration/Config.cpp"
    local WS_M="${SRC}/src/server/apps/worldserver/Main.cpp"
    local AS_M="${SRC}/src/server/apps/authserver/Main.cpp"
    local DBI_M="${SRC}/src/tools/dbimport/Main.cpp"

    if [[ -f "${CFG_H}" ]] && ! grep -qF "B022-conf-dir-override" "${CFG_H}"; then   # already applied here: skip (repeatable)
        sed -i '/std::string const GetConfigPath();/a\
    // {{{ B022-conf-dir-override\
    void SetConfigPathOverride(std::string const\& path);\
    // }}} B022-conf-dir-override' "${CFG_H}"
    fi

    if [[ -f "${CFG_C}" ]] && ! grep -qF "B022-conf-dir-override" "${CFG_C}"; then   # already applied here: skip (repeatable)
        sed -i '/std::mutex _configLock;/a\
    // {{{ B022-conf-dir-override\
    std::string _configPathOverride;\
    // }}} B022-conf-dir-override' "${CFG_C}"

        sed -i '\%return std::string(_CONF_DIR) + "/";%i\
    // {{{ B022-conf-dir-override\
    if (!_configPathOverride.empty())\
        return _configPathOverride + "/";\
    // }}} B022-conf-dir-override' "${CFG_C}"

        sed -i '/void ConfigMgr::Configure(std::string const& initFileName, std::vector<std::string> args/i\
// {{{ B022-conf-dir-override\
void ConfigMgr::SetConfigPathOverride(std::string const\& path)\
{\
    std::lock_guard<std::mutex> lock(_configLock);\
    _configPathOverride = path;\
}\
// }}} B022-conf-dir-override' "${CFG_C}"
    fi

    if [[ -f "${WS_M}" ]] && ! grep -qF "B022-conf-dir-override" "${WS_M}"; then   # already applied here: skip (repeatable)
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

    if [[ -f "${AS_M}" ]] && ! grep -qF "B022-conf-dir-override" "${AS_M}"; then   # already applied here: skip (repeatable)
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

    if [[ -f "${DBI_M}" ]] && ! grep -qF "B022-conf-dir-override" "${DBI_M}"; then   # already applied here: skip (repeatable)
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

unpatch_B022_runtime_conf_dir_override() {
    local SRC="${AC_CODE_DIR}"
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
