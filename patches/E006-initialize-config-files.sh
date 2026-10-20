#!/usr/bin/env bash
# E006-initialize-config-files.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E006_initialize_config_files
# Initialize config files (.dist -> .conf) and apply profile-specific values
# Runs after build completes (PHASE_END)
# Parallelizable: No (sequential file operations)
# Uses TARGET_INSTALL_DIR (defaults to INSTALL_DIR, can be set to INSTALL_DIR_SHADOW)
patch_E006_initialize_config_files() {
    local TARGET="${TARGET_INSTALL_DIR:-${INSTALL_DIR}}"
    echo "  [E006] Initializing config files..."

    # Refresh the app config .dist templates straight from source before the
    # .dist -> .conf copy below. cmake --install is *supposed* to place these,
    # but the installed .dist drifts stale: keys the binary starts reading get
    # added to source-beta between cmake installs, so the running conf lacks
    # them and the worldserver prints "Missing property X" at boot (and falls
    # back to defaults). Pulling them from source here — the same way module
    # configs are refreshed further down — keeps the .dist current with the
    # binary and carries upstream's section layout + comments verbatim. This is
    # the pipeline refresh that config/patches/C016 was written as a stopgap
    # for. (The lone @prefix@ token in worldserver.conf.dist sits inside an
    # example comment, so a raw copy is safe.)
    for app_conf_dist in "${AC_CODE_DIR}/src/server/apps"/*/*.conf.dist; do
        [[ -f "${app_conf_dist}" ]] || continue
        cp -f "${app_conf_dist}" "${TARGET}/etc/$(basename "${app_conf_dist}")"
    done

    # Copy .dist files to .conf
    if [[ -f "${TARGET}/etc/authserver.conf.dist" ]]; then
        cp -f "${TARGET}/etc/authserver.conf.dist" "${TARGET}/etc/authserver.conf"
    fi

    if [[ -f "${TARGET}/etc/worldserver.conf.dist" ]]; then
        cp -f "${TARGET}/etc/worldserver.conf.dist" "${TARGET}/etc/worldserver.conf"
    fi

    if [[ -f "${TARGET}/etc/dbimport.conf.dist" ]]; then
        cp -f "${TARGET}/etc/dbimport.conf.dist" "${TARGET}/etc/dbimport.conf"
    fi

    # Copy module configs from source (cmake doesn't install them)
    # Module configs live in source/modules/mod-*/conf/*.conf.dist
    mkdir -p "${TARGET}/etc/modules"
    for mod_conf_dir in "${AC_CODE_DIR}/modules"/*/conf; do
        if [[ -d "${mod_conf_dir}" ]]; then
            for conf_dist in "${mod_conf_dir}"/*.conf.dist; do
                if [[ -f "${conf_dist}" ]]; then
                    local conf_name=$(basename "${conf_dist}")
                    cp -f "${conf_dist}" "${TARGET}/etc/modules/${conf_name}"
                    echo "    Copied ${conf_name}"
                fi
            done
        fi
    done

    # Initialize module configs (.dist -> .conf)
    if [[ -d "${TARGET}/etc/modules" ]]; then
        for conf_dist in "${TARGET}/etc/modules/"*.conf.dist; do
            if [[ -f "${conf_dist}" ]]; then
                cp -f "${conf_dist}" "${conf_dist%.dist}"
            fi
        done
    fi

    # Apply profile-specific config values (database, paths, gameplay settings)
    # Temporarily override INSTALL_DIR for config patches
    local ORIG_INSTALL_DIR="${INSTALL_DIR}"
    INSTALL_DIR="${TARGET}"
    apply_config_values
    INSTALL_DIR="${ORIG_INSTALL_DIR}"
}

unpatch_E006_initialize_config_files() {
    local TARGET="${TARGET_INSTALL_DIR:-${INSTALL_DIR}}"
    echo "  [E006] Removing config files (keeping .dist)..."

    # Remove .conf files (leave .dist files intact)
    [[ -f "${TARGET}/etc/authserver.conf" ]] && rm "${TARGET}/etc/authserver.conf"
    [[ -f "${TARGET}/etc/worldserver.conf" ]] && rm "${TARGET}/etc/worldserver.conf"
    [[ -f "${TARGET}/etc/dbimport.conf" ]] && rm "${TARGET}/etc/dbimport.conf"

    # Remove module configs
    if [[ -d "${TARGET}/etc/modules" ]]; then
        for conf in "${TARGET}/etc/modules/"*.conf; do
            if [[ -f "${conf}" && -f "${conf}.dist" ]]; then
                rm "${conf}"
            fi
        done
    fi
}
# -- }}}
