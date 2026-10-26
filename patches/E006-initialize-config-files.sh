#!/usr/bin/env bash

patch_E006_initialize_config_files() {
    local TARGET="${TARGET_INSTALL_DIR:-${INSTALL_DIR}}"
    echo "  [E006] Initializing config files..."

    for app_conf_dist in "${AC_CODE_DIR}/src/server/apps"/*/*.conf.dist; do
        [[ -f "${app_conf_dist}" ]] || continue
        cp -f "${app_conf_dist}" "${TARGET}/etc/$(basename "${app_conf_dist}")"
    done

    if [[ -f "${TARGET}/etc/authserver.conf.dist" ]]; then
        cp -f "${TARGET}/etc/authserver.conf.dist" "${TARGET}/etc/authserver.conf"
    fi

    if [[ -f "${TARGET}/etc/worldserver.conf.dist" ]]; then
        cp -f "${TARGET}/etc/worldserver.conf.dist" "${TARGET}/etc/worldserver.conf"
    fi

    if [[ -f "${TARGET}/etc/dbimport.conf.dist" ]]; then
        cp -f "${TARGET}/etc/dbimport.conf.dist" "${TARGET}/etc/dbimport.conf"
    fi

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

    if [[ -d "${TARGET}/etc/modules" ]]; then
        for conf_dist in "${TARGET}/etc/modules/"*.conf.dist; do
            if [[ -f "${conf_dist}" ]]; then
                cp -f "${conf_dist}" "${conf_dist%.dist}"
            fi
        done
    fi

}

unpatch_E006_initialize_config_files() {
    local TARGET="${TARGET_INSTALL_DIR:-${INSTALL_DIR}}"
    echo "  [E006] Removing config files (keeping .dist)..."

    [[ -f "${TARGET}/etc/authserver.conf" ]] && rm "${TARGET}/etc/authserver.conf"
    [[ -f "${TARGET}/etc/worldserver.conf" ]] && rm "${TARGET}/etc/worldserver.conf"
    [[ -f "${TARGET}/etc/dbimport.conf" ]] && rm "${TARGET}/etc/dbimport.conf"

    if [[ -d "${TARGET}/etc/modules" ]]; then
        for conf in "${TARGET}/etc/modules/"*.conf; do
            if [[ -f "${conf}" && -f "${conf}.dist" ]]; then
                rm "${conf}"
            fi
        done
    fi
}
