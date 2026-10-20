#!/usr/bin/env bash

config_database_connections() {
    local conf_auth="${INSTALL_DIR}/etc/authserver.conf"
    local conf_world="${INSTALL_DIR}/etc/worldserver.conf"

    local DB_HOST="127.0.0.1"
    local DB_PORT
    local DB_AUTH
    local DB_WORLD
    local DB_CHARS
    local DB_PLAYERBOTS
    case "${PROFILE}" in
        release)
            DB_PORT="3307"
            DB_AUTH="acore_auth"
            DB_WORLD="acore_world"
            DB_CHARS="acore_characters"
            DB_PLAYERBOTS="acore_playerbots"
            ;;
        beta)
            DB_PORT="3307"
            DB_AUTH="acore_auth"
            DB_WORLD="acore_world_beta"
            DB_CHARS="acore_characters_beta"
            DB_PLAYERBOTS="acore_playerbots_beta"
            ;;
        vanilla)
            DB_PORT="3307"
            DB_AUTH="acore_auth"
            DB_WORLD="acore_world_vanilla"
            DB_CHARS="acore_characters_vanilla"
            DB_PLAYERBOTS="acore_playerbots_vanilla"
            ;;
        basic)
            DB_PORT="3307"
            DB_AUTH="acore_auth"
            DB_WORLD="acore_world_basic"
            DB_CHARS="acore_characters_basic"
            DB_PLAYERBOTS="acore_playerbots_basic"
            ;;
        cc-test)
            DB_PORT="3307"
            DB_AUTH="acore_auth"
            DB_WORLD="acore_world_cc_test"
            DB_CHARS="acore_characters_cc_test"
            DB_PLAYERBOTS="acore_playerbots_cc_test"
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

    sed -i 's|^LoginDatabaseInfo.*=.*|LoginDatabaseInfo = "'"${DB_HOST}"';'"${DB_PORT}"';ritz;menardi;'"${DB_AUTH}"'"|' "${conf_auth}"
    sed -i 's|^LoginDatabaseInfo.*=.*|LoginDatabaseInfo     = "'"${DB_HOST}"';'"${DB_PORT}"';ritz;menardi;'"${DB_AUTH}"'"|' "${conf_world}"

    sed -i 's|^WorldDatabaseInfo.*=.*|WorldDatabaseInfo     = "'"${DB_HOST}"';'"${DB_PORT}"';ritz;menardi;'"${DB_WORLD}"'"|' "${conf_world}"

    sed -i 's|^CharacterDatabaseInfo.*=.*|CharacterDatabaseInfo = "'"${DB_HOST}"';'"${DB_PORT}"';ritz;menardi;'"${DB_CHARS}"'"|' "${conf_world}"

    local conf_playerbots="${INSTALL_DIR}/etc/modules/playerbots.conf"
    if [[ -f "${conf_playerbots}" && -n "${DB_PLAYERBOTS}" ]]; then
        sed -i 's|^PlayerbotsDatabaseInfo.*=.*|PlayerbotsDatabaseInfo = "'"${DB_HOST}"';'"${DB_PORT}"';ritz;menardi;'"${DB_PLAYERBOTS}"'"|' "${conf_playerbots}"
    fi
}
CONFIG_PROFILES[config_database_connections]="all"
CONFIG_DESCRIPTIONS[config_database_connections]="Database connections (MySQL credentials)"
