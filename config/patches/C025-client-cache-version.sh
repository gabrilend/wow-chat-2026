#!/usr/bin/env bash
# C025 - Client cache version follows the profile's content (issue 160)
#
# For a general audience: the game client keeps a local cache of what the
# server has told it about items, creatures, quests, objects and NPC dialogue,
# and reuses it forever. When this project edits those things (a quest opened
# to the whole faction, a creature renamed, a flight master's new line), a
# player with a warm cache keeps seeing the old version. At login the server
# sends a "cache version" number; if it differs from the number the client
# stored, the client throws its cache away and asks again. This patch makes
# that number a fingerprint of the profile's own database edits, so it
# changes exactly when the content does, and differs between profiles (all
# profiles share one client, and one cache).
#
# The fingerprint: CRC-32 (cksum) over, in order,
#   - the profile name,
#   - the source tree's commit (upstream database content moves with it),
#   - every file under sql/<profile>/*.src/ (symbolic links followed, so
#     basic's links to vanilla's sources count by their content).
# Written as ClientCacheVersion in worldserver.conf. 0 would mean "use the
# database's own value", so a zero fingerprint is bumped to 1.
#
# Key: ClientCacheVersion (worldserver.conf.dist: "Use any value different from
# DB and not recently been used to trigger client side cache reset").
# Profiles: all

# -- {{{ config_client_cache_version
config_client_cache_version() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    local project="${PROJECT_DIR:-${DIR}}"

    if ! grep -qE '^ClientCacheVersion[[:space:]]*=' "${conf}"; then
        echo "    ERROR: C025 found no ClientCacheVersion line in ${conf}; cache version NOT set"
        return 1
    fi

    # profile → source tree (mirrors the case blocks in scripts/compile)
    local -A SOURCE_BY_PROFILE=(
        [release]="source-beta" [beta]="source-beta" [vanilla]="source-beta"
        [basic]="source-beta"   [alpha]="source-alpha"
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

    # Content fingerprint. A profile with no sql/<profile>/ (release) is
    # fingerprinted by name and commit alone.
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
# -- }}}
