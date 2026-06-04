#!/usr/bin/env bash
# C001 - Database Connections
# Set database connection strings (project-specific)
# Profiles: all

# -- {{{ config_database_connections
config_database_connections() {
    local conf_auth="${INSTALL_DIR}/etc/authserver.conf"
    local conf_world="${INSTALL_DIR}/etc/worldserver.conf"

    # Database isolation policy (revised by 136a — unified-realmlist):
    #   - Release, Beta, and Vanilla share `acore_auth` so the user's account
    #       and the realmlist table are visible from every profile. The realm
    #       list shows one row per profile; flag column gates which is "online".
    #       World / characters / playerbots STAY per-profile so the actual
    #       game data never crosses profiles:
    #         release/beta : acore_world / acore_characters / acore_playerbots
    #         vanilla      : acore_world_vanilla / acore_characters_vanilla /
    #                        acore_playerbots_vanilla
    #   - Alpha is wholly isolated (different source, different schema, different era):
    #       port 3308, databases acore_auth_alpha / acore_world_alpha / acore_characters_alpha
    #
    # The rationale: release is the most up-to-date public target, alpha is the holiday
    # relic running an old AzerothCore. Their schemas are incompatible. Sharing a port
    # or any database between them risks cross-version contamination. Beta sits inside
    # release's snowglobe because it shares source-beta — same schema, safe to share.
    #
    # IMPLEMENTATION NOTE: Alpha on port 3308 requires either (a) a second MySQL instance
    # bound to 3308, or (b) the project-local MySQL configured to listen on both 3307
    # and 3308. The current mysql/ install only listens on 3307. See follow-up issue
    # for the alpha-mysql-instance work.
    local DB_HOST="127.0.0.1"
    local DB_PORT
    local DB_AUTH
    local DB_WORLD
    local DB_CHARS
    local DB_PLAYERBOTS
    case "${PROFILE}" in
        release|beta)
            DB_PORT="3307"
            DB_AUTH="acore_auth"
            DB_WORLD="acore_world"
            DB_CHARS="acore_characters"
            DB_PLAYERBOTS="acore_playerbots"
            ;;
        vanilla)
            DB_PORT="3307"
            DB_AUTH="acore_auth"
            DB_WORLD="acore_world_vanilla"
            DB_CHARS="acore_characters_vanilla"
            DB_PLAYERBOTS="acore_playerbots_vanilla"
            ;;
        alpha)
            DB_PORT="3308"
            DB_AUTH="acore_auth_alpha"
            DB_WORLD="acore_world_alpha"
            DB_CHARS="acore_characters_alpha"
            DB_PLAYERBOTS=""  # alpha has no playerbots; field unused
            ;;
        *)
            echo "ERROR: Unknown profile '${PROFILE}' in config_database_connections"
            return 1
            ;;
    esac

    # Auth database (per-isolation-group, not literally shared between release and alpha)
    sed -i 's|^LoginDatabaseInfo.*=.*|LoginDatabaseInfo = "'"${DB_HOST}"';'"${DB_PORT}"';ritz;menardi;'"${DB_AUTH}"'"|' "${conf_auth}"
    sed -i 's|^LoginDatabaseInfo.*=.*|LoginDatabaseInfo     = "'"${DB_HOST}"';'"${DB_PORT}"';ritz;menardi;'"${DB_AUTH}"'"|' "${conf_world}"

    # World database
    sed -i 's|^WorldDatabaseInfo.*=.*|WorldDatabaseInfo     = "'"${DB_HOST}"';'"${DB_PORT}"';ritz;menardi;'"${DB_WORLD}"'"|' "${conf_world}"

    # Character database
    sed -i 's|^CharacterDatabaseInfo.*=.*|CharacterDatabaseInfo = "'"${DB_HOST}"';'"${DB_PORT}"';ritz;menardi;'"${DB_CHARS}"'"|' "${conf_world}"

    # Playerbots database (module config — only present for profiles with mod-playerbots)
    local conf_playerbots="${INSTALL_DIR}/etc/modules/playerbots.conf"
    if [[ -f "${conf_playerbots}" && -n "${DB_PLAYERBOTS}" ]]; then
        sed -i 's|^PlayerbotsDatabaseInfo.*=.*|PlayerbotsDatabaseInfo = "'"${DB_HOST}"';'"${DB_PORT}"';ritz;menardi;'"${DB_PLAYERBOTS}"'"|' "${conf_playerbots}"
    fi
}
CONFIG_PROFILES[config_database_connections]="all"
CONFIG_DESCRIPTIONS[config_database_connections]="Database connections (MySQL credentials)"
# -- }}}
