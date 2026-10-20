#!/usr/bin/env bash

config_client_cache_version() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    local project="${PROJECT_DIR:-${DIR}}"

    if ! grep -qE '^ClientCacheVersion[[:space:]]*=' "${conf}"; then
        echo "    ERROR: C025 found no ClientCacheVersion line in ${conf}; cache version NOT set"
        return 1
    fi

    local -A SOURCE_BY_PROFILE=(
        [release]="source-beta" [beta]="source-beta" [vanilla]="source-beta"
        [basic]="source-beta"   [alpha]="source-alpha"
        [cc-test]="source-beta"
    )
    local src="${SOURCE_BY_PROFILE[${PROFILE}]:-}"
    if [[ -z "${src}" ]]; then
        echo "    ERROR: C025 has no source tree for profile '${PROFILE}' (add a row)"
        return 1
    fi
    local commit
    commit=$(git -C "${project}/${src}" rev-parse HEAD 2>&1) || {
        echo "    ERROR: C025 could not read the commit of ${project}/${src}: ${commit}"
        return 1
    }

    local fingerprint
    fingerprint=$(
        {
            printf '%s\n%s\n' "${PROFILE}" "${commit}"
            if [[ -d "${project}/sql/${PROFILE}" ]]; then
                find -L "${project}/sql/${PROFILE}" -path '*.src/*' -type f -print0 \
                    | sort -z | xargs -0 -r cat
            fi
        } | cksum | cut -d' ' -f1
    )
    [[ "${fingerprint}" == "0" ]] && fingerprint=1

    sed -i "s|^ClientCacheVersion[[:space:]]*=.*|ClientCacheVersion = ${fingerprint}|" "${conf}"
}
CONFIG_PROFILES[config_client_cache_version]="all"
CONFIG_DESCRIPTIONS[config_client_cache_version]="ClientCacheVersion = fingerprint of profile + source commit + its SQL edits"
